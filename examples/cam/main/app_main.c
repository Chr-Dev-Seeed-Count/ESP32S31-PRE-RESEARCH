#include <fcntl.h>
#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "driver/jpeg_decode.h"
#include "driver/ppa.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_heap_caps.h"
#include "esp_attr.h"
#include "esp_log.h"
#include "esp_check.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "linux/videodev2.h"

#define TAG "cam"
#define CAM_DEV "/dev/video2"
#define INTERVAL_SAMPLES 512

typedef struct {
    uint32_t pixfmt, w, h;
    const char *name;
    float nominal_fps;
} cam_mode_t;

static const cam_mode_t s_modes[] = {
    {V4L2_PIX_FMT_JPEG, 1280, 720, "JPEG", 12.0f},
    {V4L2_PIX_FMT_RGB565X, 640, 480, "RGB565_BE", 10.0f},
    {V4L2_PIX_FMT_YUYV, 640, 480, "YUYV", 10.0f},
    {V4L2_PIX_FMT_RGB565X, 240, 240, "RGB565_BE", 24.0f},
    {V4L2_PIX_FMT_YUYV, 240, 240, "YUYV", 24.0f},
};

typedef struct {
    void *addr;
    size_t len;
} cam_buf_t;

typedef struct {
    uint64_t frames, errors, drops, bytes;
    uint32_t intervals[INTERVAL_SAMPLES];
    size_t interval_count;
    uint32_t op_times[INTERVAL_SAMPLES];
    size_t op_count;
    uint32_t min_us, max_us;
    int64_t first_us, last_us;
} cam_stats_t;

static volatile uint64_t s_busy_us[2];
static volatile uint32_t s_stress_sink;
static uint32_t s_percentile_tmp[INTERVAL_SAMPLES];

static const char *pixfmt_name(uint32_t pixfmt)
{
    switch (pixfmt) {
    case V4L2_PIX_FMT_JPEG:   return "JPEG";
    case V4L2_PIX_FMT_RGB565: return "RGB565";
    case V4L2_PIX_FMT_RGB565X:return "RGB565_BE";
    case V4L2_PIX_FMT_YUYV:   return "YUYV";
    default:                  return "UNKNOWN";
    }
}

static void stress_task(void *arg)
{
    const int core = (int)(intptr_t)arg;
    const int level = CONFIG_CAM_STRESS_LEVEL;
    const int64_t period = CONFIG_CAM_STRESS_PERIOD_US;
    const int64_t busy_target = (period * (level > 0 ? (level * 9) : 0)) / 100;
    while (true) {
        int64_t begin = esp_timer_get_time();
        int64_t until = begin + busy_target;
        uint32_t x = s_stress_sink + (uint32_t)core;
        while (esp_timer_get_time() < until) {
            x = x * 1664525u + 1013904223u;
            x ^= x >> 13;
            __asm__ __volatile__("" : "+r"(x));
        }
        s_stress_sink = x;
        s_busy_us[core] += (uint64_t)(esp_timer_get_time() - begin);
        int64_t remain = period - (esp_timer_get_time() - begin);
        if (remain > 0) {
            vTaskDelay(pdMS_TO_TICKS((remain + 999) / 1000));
        } else {
            taskYIELD();
        }
    }
}

static uint32_t percentile_us(const cam_stats_t *s, unsigned pct)
{
    if (!s->interval_count) return 0;
    uint32_t *tmp = s_percentile_tmp;
    memcpy(tmp, s->intervals, s->interval_count * sizeof(tmp[0]));
    for (size_t i = 1; i < s->interval_count; ++i) {
        uint32_t v = tmp[i]; size_t j = i;
        while (j && tmp[j - 1] > v) { tmp[j] = tmp[j - 1]; --j; }
        tmp[j] = v;
    }
    size_t n = ((size_t)pct * (s->interval_count - 1)) / 100;
    return tmp[n];
}

static uint32_t percentile_op_us(const cam_stats_t *s, unsigned pct)
{
    if (!s->op_count) return 0;
    uint32_t *tmp = s_percentile_tmp;
    memcpy(tmp, s->op_times, s->op_count * sizeof(tmp[0]));
    for (size_t i = 1; i < s->op_count; ++i) {
        uint32_t v = tmp[i]; size_t j = i;
        while (j && tmp[j - 1] > v) { tmp[j] = tmp[j - 1]; --j; }
        tmp[j] = v;
    }
    size_t n = ((size_t)pct * (s->op_count - 1)) / 100;
    return tmp[n];
}

static void stats_add(cam_stats_t *s, size_t bytes, int64_t now, bool ok, uint64_t op_us)
{
    if (!ok) { s->errors++; return; }
    if (s->last_us) {
        uint32_t dt = (uint32_t)(now - s->last_us);
        if (s->interval_count < INTERVAL_SAMPLES) s->intervals[s->interval_count++] = dt;
        if (!s->min_us || dt < s->min_us) s->min_us = dt;
        if (dt > s->max_us) s->max_us = dt;
    } else s->first_us = now;
    s->last_us = now;
    s->frames++; s->bytes += bytes;
    if (op_us && s->op_count < INTERVAL_SAMPLES) s->op_times[s->op_count++] = (uint32_t)op_us;
}

static void print_result(const char *id, const cam_mode_t *m, const cam_stats_t *s,
                         int64_t elapsed_us, uint64_t op_us, uint64_t aux)
{
    uint32_t p50 = percentile_us(s, 50), p95 = percentile_us(s, 95), p99 = percentile_us(s, 99);
    uint32_t op50 = percentile_op_us(s, 50), op95 = percentile_op_us(s, 95), op99 = percentile_op_us(s, 99);
    uint32_t fps10 = elapsed_us ? (uint32_t)((s->frames * 10000000ULL) / elapsed_us) : 0;
    uint32_t kbps = elapsed_us ? (uint32_t)((s->bytes * 8000ULL) / elapsed_us) : 0;
    uint32_t heap_i = heap_caps_get_free_size(MALLOC_CAP_INTERNAL);
    uint32_t heap_p = heap_caps_get_free_size(MALLOC_CAP_SPIRAM);
    uint32_t load0 = elapsed_us ? (uint32_t)((s_busy_us[0] * 100ULL) / elapsed_us) : 0;
    uint32_t load1 = elapsed_us ? (uint32_t)((s_busy_us[1] * 100ULL) / elapsed_us) : 0;
    if (load0 > 100) load0 = 100;
    if (load1 > 100) load1 = 100;
    ESP_LOGI(TAG, "CAM_RESULT id=%s stress=%d stress_period_us=%d fmt=%s %" PRIu32 "x%" PRIu32 " fps=%" PRIu32 ".%u frames=%" PRIu64 " errors=%" PRIu64 " drops=%" PRIu64 " bytes_per_frame=%" PRIu32 " kbps=%" PRIu32 " p50_us=%" PRIu32 " p95_us=%" PRIu32 " p99_us=%" PRIu32 " op_us=%" PRIu64 " op_p50_us=%" PRIu32 " op_p95_us=%" PRIu32 " op_p99_us=%" PRIu32 " aux=%" PRIu64 " cpu_load=%" PRIu32 "/%" PRIu32 " heap_int=%" PRIu32 " heap_psram=%" PRIu32,
               id, CONFIG_CAM_STRESS_LEVEL, CONFIG_CAM_STRESS_PERIOD_US, m->name, m->w, m->h, fps10 / 10, fps10 % 10, s->frames, s->errors, s->drops,
               s->frames ? (uint32_t)(s->bytes / s->frames) : 0, kbps, p50, p95, p99, op_us, op50, op95, op99, aux,
               load0, load1, heap_i, heap_p);
}

typedef bool (*frame_cb_t)(const uint8_t *data, size_t len, uint32_t width, uint32_t height, uint64_t *op_us, uint64_t *aux);

static esp_err_t capture_mode(const cam_mode_t *mode, const char *id, frame_cb_t cb)
{
    int fd = open(CAM_DEV, O_RDONLY);
    if (fd < 0) return ESP_FAIL;
    struct v4l2_format fmt = { .type = V4L2_BUF_TYPE_VIDEO_CAPTURE };
    fmt.fmt.pix.width = mode->w; fmt.fmt.pix.height = mode->h; fmt.fmt.pix.pixelformat = mode->pixfmt;
    if (ioctl(fd, VIDIOC_S_FMT, &fmt) != 0) { close(fd); return ESP_FAIL; }
    cam_mode_t actual = *mode;
    actual.pixfmt = fmt.fmt.pix.pixelformat;
    actual.w = fmt.fmt.pix.width;
    actual.h = fmt.fmt.pix.height;
    actual.name = pixfmt_name(actual.pixfmt);
    struct v4l2_requestbuffers req = { .count = CONFIG_CAM_BUFFER_COUNT, .type = V4L2_BUF_TYPE_VIDEO_CAPTURE, .memory = V4L2_MEMORY_MMAP };
    if (ioctl(fd, VIDIOC_REQBUFS, &req) != 0 || req.count < 2) { close(fd); return ESP_FAIL; }
    cam_buf_t bufs[6] = {0};
    for (uint32_t i = 0; i < req.count; ++i) {
        struct v4l2_buffer b = { .type = req.type, .memory = req.memory, .index = i };
        if (ioctl(fd, VIDIOC_QUERYBUF, &b) != 0) { close(fd); return ESP_FAIL; }
        bufs[i].len = b.length;
        bufs[i].addr = mmap(NULL, b.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, b.m.offset);
        if (bufs[i].addr == MAP_FAILED) { close(fd); return ESP_FAIL; }
        if (ioctl(fd, VIDIOC_QBUF, &b) != 0) { close(fd); return ESP_FAIL; }
    }
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (ioctl(fd, VIDIOC_STREAMON, &type) != 0) { close(fd); return ESP_FAIL; }
    /* Keep the percentile history out of the main task stack (the history is
     * several kilobytes and the ESP-IDF main task is intentionally small). */
    static cam_stats_t st;
    memset(&st, 0, sizeof(st));
    s_busy_us[0] = 0;
    s_busy_us[1] = 0;
    int64_t begin = esp_timer_get_time();
    int64_t end = begin + (int64_t)CONFIG_CAM_RUN_SECONDS * 1000000LL;
    uint64_t op_sum = 0, aux_last = 0;
    uint32_t last_sequence = 0;
    bool have_sequence = false;
    while (esp_timer_get_time() < end) {
        struct v4l2_buffer b = { .type = type, .memory = V4L2_MEMORY_MMAP };
        if (ioctl(fd, VIDIOC_DQBUF, &b) != 0) { st.errors++; continue; }
        if (have_sequence && b.sequence > last_sequence + 1) {
            st.drops += b.sequence - last_sequence - 1;
        }
        if (!have_sequence || b.sequence > last_sequence) {
            last_sequence = b.sequence;
            have_sequence = true;
        }
        bool ok = !(b.flags & V4L2_BUF_FLAG_ERROR);
        uint64_t op = 0, aux = 0;
        if (ok && cb) ok = cb((const uint8_t *)bufs[b.index].addr, b.bytesused, actual.w, actual.h, &op, &aux);
        stats_add(&st, b.bytesused, esp_timer_get_time(), ok, op);
        if (ok) { op_sum += op; aux_last = aux; }
        if (ioctl(fd, VIDIOC_QBUF, &b) != 0) { st.errors++; break; }
    }
    ioctl(fd, VIDIOC_STREAMOFF, &type);
    int64_t elapsed = esp_timer_get_time() - begin;
    for (uint32_t i = 0; i < req.count; ++i) if (bufs[i].addr && bufs[i].addr != MAP_FAILED) munmap(bufs[i].addr, bufs[i].len);
    close(fd);
    print_result(id, &actual, &st, elapsed, st.frames ? op_sum / st.frames : 0, aux_last);
    return ESP_OK;
}

static bool cb_none(const uint8_t *d, size_t n, uint32_t w, uint32_t h, uint64_t *op, uint64_t *aux)
{ (void)d; (void)n; (void)w; (void)h; *op = 0; *aux = 0; return true; }

static bool __attribute__((unused)) cb_brightness(const uint8_t *d, size_t n, uint32_t w, uint32_t h, uint64_t *op, uint64_t *aux)
{
    int64_t t0 = esp_timer_get_time();
    (void)w; (void)h; uint64_t sum = 0; uint32_t minv = 255, maxv = 0, sat = 0, count = 0;
    for (size_t i = 0; i + 1 < n; i += 4) { uint8_t y = d[i]; sum += y; if (y < minv) minv = y; if (y > maxv) maxv = y; if (y >= 250) sat++; count++; }
    *op = (uint64_t)(esp_timer_get_time() - t0);
    uint32_t mean = count ? (uint32_t)(sum / count) : 0;
    uint32_t sat_permille = count ? (sat * 1000 / count) : 0;
    *aux = ((uint64_t)mean << 48) | ((uint64_t)minv << 40) | ((uint64_t)maxv << 32) | sat_permille;
    return count != 0;
}

static jpeg_decoder_handle_t s_jpeg;
static ppa_client_handle_t s_ppa;
static uint8_t *s_jpeg_out, *s_ppa_out;
static size_t s_jpeg_out_size;
static esp_lcd_panel_handle_t s_display_panel;
static esp_lcd_panel_io_handle_t s_display_io;
static volatile uint32_t s_display_frame_seq;
static volatile uint32_t s_display_frame_done_us;

static bool IRAM_ATTR display_frame_done_cb(esp_lcd_panel_handle_t panel,
                                            const esp_lcd_rgb_panel_event_data_t *edata,
                                            void *user_ctx)
{
    (void)panel;
    (void)edata;
    (void)user_ctx;
    s_display_frame_done_us = (uint32_t)esp_timer_get_time();
    s_display_frame_seq++;
    return false;
}

static bool __attribute__((unused)) cb_jpeg_ppa(const uint8_t *d, size_t n, uint32_t w, uint32_t h, uint64_t *op, uint64_t *aux)
{
    uint32_t decoded = 0; int64_t t0 = esp_timer_get_time();
    jpeg_decode_cfg_t dc = { .output_format = JPEG_DECODE_OUT_FORMAT_RGB565, .rgb_order = JPEG_DEC_RGB_ELEMENT_ORDER_RGB };
    if (jpeg_decoder_process(s_jpeg, &dc, d, n, s_jpeg_out, s_jpeg_out_size, &decoded) != ESP_OK) return false;
    int64_t t1 = esp_timer_get_time();
    ppa_srm_oper_config_t pc = {0};
    /* Center crop to 4:3, scale to VGA, and rotate in one PPA transaction.
     * This exercises crop/windowing, scaling and rotation after JPEG color
     * conversion without adding a CPU-side copy. */
    uint32_t crop_w = (w * 3U) / 4U;
    uint32_t crop_x = (w - crop_w) / 2U;
    pc.in.buffer = s_jpeg_out; pc.in.pic_w = w; pc.in.pic_h = h;
    pc.in.block_w = crop_w; pc.in.block_h = h; pc.in.block_offset_x = crop_x;
    pc.in.srm_cm = PPA_SRM_COLOR_MODE_RGB565;
    pc.out.buffer = s_ppa_out; pc.out.buffer_size = 800 * 480 * 2; pc.out.pic_w = 640; pc.out.pic_h = 480; pc.out.srm_cm = PPA_SRM_COLOR_MODE_RGB565;
    pc.scale_x = 640.0f / (float)crop_w; pc.scale_y = 480.0f / (float)h;
    pc.rotation_angle = PPA_SRM_ROTATION_ANGLE_180; pc.mode = PPA_TRANS_MODE_BLOCKING;
    if (ppa_do_scale_rotate_mirror(s_ppa, &pc) != ESP_OK) return false;
    *op = (uint64_t)(esp_timer_get_time() - t0); *aux = (uint64_t)(t1 - t0); return true;
}

static esp_err_t __attribute__((unused)) init_jpeg_ppa(void)
{
    jpeg_decode_memory_alloc_cfg_t mc = { .buffer_direction = JPEG_DEC_ALLOC_OUTPUT_BUFFER };
    s_jpeg_out = jpeg_alloc_decoder_mem(1280 * 720 * 2, &mc, &s_jpeg_out_size);
    if (!s_jpeg_out) return ESP_ERR_NO_MEM;
    s_ppa_out = heap_caps_aligned_alloc(64, 800 * 480 * 2, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (!s_ppa_out) return ESP_ERR_NO_MEM;
    jpeg_decode_engine_cfg_t ec = { .timeout_ms = 200 };
    ESP_RETURN_ON_ERROR(jpeg_new_decoder_engine(&ec, &s_jpeg), TAG, "jpeg engine");
    ppa_client_config_t pc = { .oper_type = PPA_OPERATION_SRM, .max_pending_trans_num = 1 };
    return ppa_register_client(&pc, &s_ppa);
}

static bool __attribute__((unused)) cb_display(const uint8_t *d, size_t n, uint32_t w, uint32_t h, uint64_t *op, uint64_t *aux)
{
    (void)n;
    if (!s_ppa || !s_display_panel) return false;
    int64_t t0 = esp_timer_get_time();
    ppa_srm_oper_config_t pc = {0};
    pc.in.buffer = d; pc.in.pic_w = w; pc.in.pic_h = h; pc.in.block_w = w; pc.in.block_h = h; pc.in.srm_cm = PPA_SRM_COLOR_MODE_RGB565;
    pc.out.buffer = s_ppa_out; pc.out.buffer_size = 800 * 480 * 2; pc.out.pic_w = 800; pc.out.pic_h = 480; pc.out.srm_cm = PPA_SRM_COLOR_MODE_RGB565;
    pc.scale_x = 800.0f / (float)w; pc.scale_y = 480.0f / (float)h; pc.rotation_angle = PPA_SRM_ROTATION_ANGLE_0;
    pc.byte_swap = true; /* OV3660 RGB565 mode is big-endian; LCD frame buffers are little-endian. */
    pc.mode = PPA_TRANS_MODE_BLOCKING;
    if (ppa_do_scale_rotate_mirror(s_ppa, &pc) != ESP_OK) return false;
    int64_t t1 = esp_timer_get_time();
    uint32_t frame_seq = s_display_frame_seq;
    if (esp_lcd_panel_draw_bitmap(s_display_panel, 0, 0, 800, 480, s_ppa_out) != ESP_OK) return false;
    int64_t timeout = esp_timer_get_time() + 100000;
    while (s_display_frame_seq == frame_seq && esp_timer_get_time() < timeout) {
        vTaskDelay(1);
    }
    if (s_display_frame_seq == frame_seq) return false;
    *op = (uint32_t)s_display_frame_done_us - (uint32_t)t0; *aux = (uint64_t)(t1 - t0); return true;
}

static uint8_t s_prev_y[256];
static bool s_have_prev;
static bool __attribute__((unused)) cb_motion(const uint8_t *d, size_t n, uint32_t w, uint32_t h, uint64_t *op, uint64_t *aux)
{
    int64_t t0 = esp_timer_get_time();
    (void)w; (void)h;
    uint32_t diff = 0, count = 0;
    size_t step = (n / 256 + 1) & ~1U;
    if (step < 2) step = 2;
    for (size_t i = 0; i + 1 < n && count < 256; i += step) {
        uint8_t y = d[i]; if (s_have_prev) diff += (y > s_prev_y[count]) ? y - s_prev_y[count] : s_prev_y[count] - y; s_prev_y[count++] = y;
    }
    s_have_prev = count != 0; *op = (uint64_t)(esp_timer_get_time() - t0); *aux = count ? diff / count : 0; return count != 0;
}

static bool __attribute__((unused)) init_display(void)
{
    if (bsp_display_new(NULL, &s_display_panel, &s_display_io) != ESP_OK) return false;
    const esp_lcd_rgb_panel_event_callbacks_t callbacks = {
        .on_frame_buf_complete = display_frame_done_cb,
    };
    if (esp_lcd_rgb_panel_register_event_callbacks(s_display_panel, &callbacks, NULL) != ESP_OK) return false;
    esp_lcd_panel_disp_on_off(s_display_panel, true);
    (void)bsp_display_brightness_init(); (void)bsp_display_brightness_set(100);
    return true;
}

static void __attribute__((unused)) deinit_jpeg_ppa(void)
{
    if (s_ppa) {
        ppa_unregister_client(s_ppa);
    }
    if (s_jpeg) {
        jpeg_del_decoder_engine(s_jpeg);
    }
    if (s_ppa_out) {
        heap_caps_free(s_ppa_out);
    }
    if (s_jpeg_out) {
        heap_caps_free(s_jpeg_out);
    }
    s_ppa = NULL; s_jpeg = NULL; s_ppa_out = NULL; s_jpeg_out = NULL;
}

void app_main(void)
{
    /* Keep the serial stream machine-readable: retain only errors globally and
     * the single structured result line emitted by this application. */
    esp_log_level_set("*", ESP_LOG_ERROR);
    esp_log_level_set(TAG, ESP_LOG_INFO);
    ESP_ERROR_CHECK(bsp_camera_start(NULL));
    xTaskCreatePinnedToCore(stress_task, "cam_stress0", 3072, (void *)0, 2, NULL, 0);
    xTaskCreatePinnedToCore(stress_task, "cam_stress1", 3072, (void *)1, 2, NULL, 1);
    vTaskDelay(pdMS_TO_TICKS(300));
#if CONFIG_CAM_TEST_CAM01
    for (size_t i = 0; i < sizeof(s_modes) / sizeof(s_modes[0]); ++i) capture_mode(&s_modes[i], "CAM-01", cb_none);
#elif CONFIG_CAM_TEST_CAM02
    for (size_t i = 0; i < sizeof(s_modes) / sizeof(s_modes[0]); ++i) capture_mode(&s_modes[i], "CAM-02", cb_none);
#elif CONFIG_CAM_TEST_CAM03
    if (init_jpeg_ppa() == ESP_OK) { capture_mode(&s_modes[0], "CAM-03", cb_jpeg_ppa); deinit_jpeg_ppa(); }
#elif CONFIG_CAM_TEST_CAM04
    if (init_jpeg_ppa() == ESP_OK && init_display()) { capture_mode(&s_modes[1], "CAM-04", cb_display); deinit_jpeg_ppa(); bsp_display_delete(); s_display_panel = NULL; s_display_io = NULL; }
#elif CONFIG_CAM_TEST_CAM05
    capture_mode(&s_modes[2], "CAM-05", cb_brightness);
#elif CONFIG_CAM_TEST_CAM06
    capture_mode(&s_modes[2], "CAM-06", cb_motion);
#endif
    while (true) vTaskDelay(pdMS_TO_TICKS(1000));
}
