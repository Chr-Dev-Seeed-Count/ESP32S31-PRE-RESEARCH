#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include "esp_timer.h"
#include "lvgl.h"
#include "lcd_perf_port.h"

#if CONFIG_LCD_TEST_ID == 6
#include "esp_jpeg_dec.h"
#include "esp_jpeg_common.h"
extern const uint8_t _binary_esp_logo_jpg_start[];
extern const uint8_t _binary_esp_logo_jpg_end[];
static void decode_jpeg_into_ui(void);
#endif

static const char *TAG = "lcd_demo";
static lv_display_t *s_disp;
static lv_obj_t *s_status;
#if CONFIG_LCD_TEST_ID == 6
static lv_obj_t *s_jpeg_img;
static lv_image_dsc_t *s_jpeg_dsc;
static uint32_t s_jpeg_elapsed_ms;
#endif
#if CONFIG_LCD_TEST_ID == 5
static char *s_text_buf;
#endif
static uint32_t s_phase;
static uint32_t s_tick;

#if CONFIG_LCD_TEST_ID >= 1 && CONFIG_LCD_TEST_ID <= 4
static lv_color_t palette(uint32_t n)
{
    return lv_color_make((n * 37u) & 0xffu, (n * 71u + 40u) & 0xffu, (n * 113u + 90u) & 0xffu);
}
#endif

static void update_status(void)
{
    if (!s_status) return;
    lv_label_set_text_fmt(s_status, "LCD-%02d  load=%" PRIu32 "  heap=%u  psram=%u",
                          CONFIG_LCD_TEST_ID, s_tick,
                          (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL),
                          (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
}

static void stress_timer_cb(lv_timer_t *timer)
{
    (void)timer;
    s_tick++;
    s_phase += CONFIG_LCD_PERF_ANIM_STEP;
#if CONFIG_LCD_TEST_ID == 1
    lv_obj_t *screen = lv_screen_active();
    lv_obj_set_style_bg_color(screen, palette(s_phase / 4), 0);
    lv_obj_invalidate(screen);
#elif CONFIG_LCD_TEST_ID == 2
    uint32_t i = 0;
    for (lv_obj_t *obj = lv_obj_get_child(lv_screen_active(), 0); obj; obj = lv_obj_get_child(lv_screen_active(), ++i)) {
        lv_obj_set_x(obj, (int32_t)((s_phase + i * 13) % 760));
        lv_obj_set_y(obj, 60 + (int32_t)((s_phase / 2 + i * 29) % 380));
    }
#elif CONFIG_LCD_TEST_ID == 3
    uint32_t i = 0;
    for (lv_obj_t *obj = lv_obj_get_child(lv_screen_active(), 0); obj; obj = lv_obj_get_child(lv_screen_active(), ++i)) {
        lv_obj_set_style_opa(obj, (lv_opa_t)(40 + ((s_phase + i * 17) % 216)), 0);
    }
#elif CONFIG_LCD_TEST_ID == 4
    lv_obj_t *screen = lv_screen_active();
    lv_obj_set_style_bg_color(screen, palette(s_phase), 0);
    lv_obj_invalidate(screen);
#elif CONFIG_LCD_TEST_ID == 5
    lv_obj_scroll_by(lv_screen_active(), -CONFIG_LCD_PERF_TEXT_SCROLL_PX, 0, LV_ANIM_OFF);
#elif CONFIG_LCD_TEST_ID == 6
    if (s_jpeg_img) lv_obj_set_style_transform_rotation(s_jpeg_img, (s_phase * CONFIG_LCD_PERF_JPEG_ROTATE_STEP) % 3600, 0);
#if CONFIG_LCD_PERF_JPEG_REDECODE
    s_jpeg_elapsed_ms += CONFIG_LCD_PERF_TIMER_PERIOD_MS;
    if (s_jpeg_elapsed_ms >= CONFIG_LCD_PERF_JPEG_REDECODE_PERIOD_MS) {
        s_jpeg_elapsed_ms = 0;
        decode_jpeg_into_ui();
    }
#endif
#endif
    update_status();
}

static void add_header(lv_obj_t *screen, const char *title)
{
    lv_obj_t *label = lv_label_create(screen);
    lv_label_set_text(label, title);
    lv_obj_set_style_text_color(label, lv_color_white(), 0);
    lv_obj_align(label, LV_ALIGN_TOP_MID, 0, 8);
    s_status = lv_label_create(screen);
    lv_label_set_text(s_status, "starting...");
    lv_obj_set_style_text_color(s_status, lv_color_white(), 0);
    lv_obj_align(s_status, LV_ALIGN_BOTTOM_MID, 0, -8);
}

static void build_ui(void)
{
    lv_obj_t *screen = lv_screen_active();
    lv_obj_set_style_bg_color(screen, lv_color_black(), 0);
#if CONFIG_LCD_TEST_ID == 1
    add_header(screen, "RGB timing sweep: full-screen invalidation");
    for (int i = 0; i < 8; ++i) {
        lv_obj_t *bar = lv_obj_create(screen);
        lv_obj_set_size(bar, 100, 320);
        lv_obj_set_pos(bar, i * 100, 70);
        lv_obj_set_style_bg_color(bar, palette(i), 0);
        lv_obj_set_style_border_width(bar, 0, 0);
    }
#elif CONFIG_LCD_TEST_ID == 2
    add_header(screen, "Buffer strategy: moving dirty rectangles");
    for (int i = 0; i < CONFIG_LCD_PERF_BUFFER_OBJECTS; ++i) {
        lv_obj_t *box = lv_obj_create(screen);
        lv_obj_set_size(box, 80 + (i % 4) * 20, 60 + (i % 3) * 20);
        lv_obj_set_pos(box, (i * 71) % 720, 70 + (i * 37) % 340);
        lv_obj_set_style_bg_color(box, palette(i + 5), 0);
        lv_obj_set_style_radius(box, (i * 7) % 24, 0);
    }
#elif CONFIG_LCD_TEST_ID == 3
    add_header(screen, "LVGL load: widgets/opacity/animation sweep");
    for (int i = 0; i < CONFIG_LCD_PERF_WIDGET_COUNT; ++i) {
        lv_obj_t *card = lv_obj_create(screen);
        lv_obj_set_size(card, 90, 70);
        lv_obj_set_pos(card, 10 + (i % 8) * 98, 55 + (i / 8) * 82);
        lv_obj_set_style_bg_color(card, palette(i), 0);
        lv_obj_set_style_bg_opa(card, 80 + (i % 5) * 30, 0);
        lv_obj_set_style_radius(card, 10, 0);
        lv_obj_t *label = lv_label_create(card);
        lv_label_set_text_fmt(label, "%d", i);
        lv_obj_center(label);
    }
#elif CONFIG_LCD_TEST_ID == 4
    add_header(screen, "Tearing/stability: high-rate full-screen animation");
    lv_obj_t *cursor = lv_obj_create(screen);
    lv_obj_set_size(cursor, 160, 160);
    lv_obj_set_style_bg_color(cursor, lv_palette_main(LV_PALETTE_RED), 0);
    lv_obj_set_style_radius(cursor, LV_RADIUS_CIRCLE, 0);
    lv_obj_center(cursor);
    for (int i = 0; i < CONFIG_LCD_PERF_TEARING_LAYERS; ++i) {
        lv_obj_t *layer = lv_obj_create(screen);
        lv_obj_set_size(layer, 640 - i * 30, 360 - i * 20);
        lv_obj_set_style_bg_opa(layer, 20 + i * 12, 0);
        lv_obj_set_style_bg_color(layer, palette(i + 10), 0);
        lv_obj_center(layer);
    }
#elif CONFIG_LCD_TEST_ID == 5
    add_header(screen, "Chinese/long text: scrolling text memory pressure");
    lv_obj_t *cont = lv_obj_create(screen);
    lv_obj_set_size(cont, 780, 340);
    lv_obj_set_pos(cont, 10, 60);
    lv_obj_set_scroll_dir(cont, LV_DIR_HOR);
    lv_obj_set_style_bg_color(cont, lv_color_make(15, 15, 25), 0);
    lv_obj_t *text = lv_label_create(cont);
    const char *pattern = "ESP32-S31性能预研 中文歌词滚动 ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789 | ";
    const size_t pattern_len = strlen(pattern);
    s_text_buf = malloc((size_t)CONFIG_LCD_PERF_TEXT_LENGTH + 1u);
    if (!s_text_buf) {
        ESP_LOGE(TAG, "FIRST_ERROR text alloc len=%d", CONFIG_LCD_PERF_TEXT_LENGTH);
        lv_label_set_text(text, "text allocation failed");
    } else {
        size_t used = 0;
        size_t pos = 0;
        while (used < (size_t)CONFIG_LCD_PERF_TEXT_LENGTH) {
            const unsigned char c = (unsigned char)pattern[pos];
            size_t cp_len = (c < 0x80) ? 1 : ((c & 0xE0) == 0xC0) ? 2 : ((c & 0xF0) == 0xE0) ? 3 : 4;
            if (pos + cp_len > pattern_len || used + cp_len > (size_t)CONFIG_LCD_PERF_TEXT_LENGTH) break;
            memcpy(s_text_buf + used, pattern + pos, cp_len);
            used += cp_len;
            pos += cp_len;
            if (pos >= pattern_len) pos = 0;
        }
        s_text_buf[used] = '\0';
        lv_label_set_text(text, s_text_buf);
    }
    lv_obj_set_width(text, 760);
    lv_label_set_long_mode(text, LV_LABEL_LONG_WRAP);
#elif CONFIG_LCD_TEST_ID == 6
    add_header(screen, "JPEG/UI: decode + scale/rotate + continuous image refresh");
    lv_obj_t *placeholder = lv_obj_create(screen);
    lv_obj_set_size(placeholder, 640, 340);
    lv_obj_center(placeholder);
    lv_obj_set_style_bg_color(placeholder, lv_color_make(30, 30, 30), 0);
    lv_obj_t *label = lv_label_create(screen);
    lv_label_set_text(label, "JPEG decode pending");
    lv_obj_center(label);
#endif
    update_status();
}

#if CONFIG_LCD_TEST_ID == 6
static void decode_jpeg_into_ui(void)
{
    const int input_len = (int)(_binary_esp_logo_jpg_end - _binary_esp_logo_jpg_start);
    jpeg_dec_config_t cfg = DEFAULT_JPEG_DEC_CONFIG();
    cfg.output_type = JPEG_PIXEL_FORMAT_RGB565_LE;
    cfg.rotate = (jpeg_rotate_t)CONFIG_LCD_PERF_JPEG_ROTATE;
    if (CONFIG_LCD_PERF_JPEG_SCALE > 0) {
        cfg.scale.width = CONFIG_LCD_PERF_JPEG_SCALE;
        cfg.scale.height = CONFIG_LCD_PERF_JPEG_SCALE;
    }
    jpeg_dec_handle_t dec = NULL;
    jpeg_dec_io_t io = {0};
    jpeg_dec_header_info_t info = {0};
    jpeg_error_t ret = jpeg_dec_open(&cfg, &dec);
    if (ret == JPEG_ERR_OK) {
        io.inbuf = (uint8_t *)_binary_esp_logo_jpg_start;
        io.inbuf_len = input_len;
        ret = jpeg_dec_parse_header(dec, &io, &info);
    }
    if (ret != JPEG_ERR_OK) {
        ESP_LOGE(TAG, "FIRST_ERROR jpeg header ret=%d", ret);
        if (dec) jpeg_dec_close(dec);
        return;
    }
    int out_len = 0;
    jpeg_dec_get_outbuf_len(dec, &out_len);
    uint8_t *out = jpeg_calloc_align((size_t)out_len, 16);
    if (!out) {
        ESP_LOGE(TAG, "FIRST_ERROR jpeg alloc len=%d", out_len);
        jpeg_dec_close(dec);
        return;
    }
    io.outbuf = out;
    io.out_size = out_len;
    ret = jpeg_dec_process(dec, &io);
    jpeg_dec_close(dec);
    if (ret != JPEG_ERR_OK) {
        ESP_LOGE(TAG, "FIRST_ERROR jpeg decode ret=%d", ret);
        jpeg_free_align(out);
        return;
    }
    if (s_jpeg_img) {
        lv_image_set_src(s_jpeg_img, NULL);
        lv_obj_del(s_jpeg_img);
        s_jpeg_img = NULL;
    }
    if (s_jpeg_dsc) {
        jpeg_free_align((void *)s_jpeg_dsc->data);
        free(s_jpeg_dsc);
        s_jpeg_dsc = NULL;
    }
    lv_image_dsc_t *dsc = calloc(1, sizeof(*dsc));
    if (!dsc) { jpeg_free_align(out); return; }
    dsc->header.magic = LV_IMAGE_HEADER_MAGIC;
    dsc->header.cf = LV_COLOR_FORMAT_RGB565;
    dsc->header.stride = info.width * 2;
    dsc->header.w = info.width;
    dsc->header.h = info.height;
    dsc->data_size = out_len;
    dsc->data = out;
    s_jpeg_dsc = dsc;
    s_jpeg_img = lv_image_create(lv_screen_active());
    lv_image_set_src(s_jpeg_img, dsc);
    lv_obj_center(s_jpeg_img);
    ESP_LOGI(TAG, "JPEG decoded %ux%u input=%d output=%d", info.width, info.height, input_len, out_len);
}
#endif

void app_main(void)
{
    char name[16];
    snprintf(name, sizeof(name), "LCD-%02d", CONFIG_LCD_TEST_ID);
    s_disp = lcd_perf_port_init();
    lcd_perf_port_log_config(name);
    lcd_perf_lock(1000);
    build_ui();
#if CONFIG_LCD_TEST_ID == 6
    decode_jpeg_into_ui();
#endif
    lv_timer_create(stress_timer_cb, CONFIG_LCD_PERF_TIMER_PERIOD_MS, NULL);
    lcd_perf_unlock();
    ESP_LOGI(TAG, "READY test=%d; increase CONFIG_LCD_PERF_* until FPS/flush errors or visual first error", CONFIG_LCD_TEST_ID);
}
