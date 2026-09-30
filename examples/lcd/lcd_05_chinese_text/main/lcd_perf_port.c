#include <inttypes.h>
#include <sys/lock.h>
#include <sys/param.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_err.h"
#include "esp_check.h"
#include "esp_heap_caps.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "lcd_perf_port.h"

#define LCD_H_RES 800
#define LCD_V_RES 480
#define LCD_PIXEL_SIZE 2
#define LCD_TASK_STACK (6 * 1024)
#define LCD_TASK_PRIORITY 2
#define LCD_TICK_MS 2

static const char *TAG = "lcd_perf";
static _lock_t s_lvgl_lock;
static TaskHandle_t s_lvgl_task;
static lv_display_t *s_display;
static esp_lcd_panel_handle_t s_panel;
static volatile uint32_t s_flush_done;
static volatile uint32_t s_flush_errors;
static volatile uint64_t s_flush_total_us;
static volatile uint32_t s_flush_max_us;
static volatile uint32_t s_last_flush_start;

static void lcd_perf_flush_cb(lv_display_t *disp, const lv_area_t *area, uint8_t *px_map)
{
    const uint32_t start = (uint32_t)esp_timer_get_time();
    int x1 = area->x1;
    int y1 = area->y1;
    int x2 = area->x2;
    int y2 = area->y2;
#if CONFIG_LCD_PERF_BUFFER_MODE_DOUBLE
    if (!lv_display_flush_is_last(disp)) {
        lv_display_flush_ready(disp);
        return;
    }
    x1 = 0; y1 = 0; x2 = LCD_H_RES - 1; y2 = LCD_V_RES - 1;
    ulTaskNotifyTake(pdTRUE, 0);
#endif
    esp_err_t err = esp_lcd_panel_draw_bitmap(s_panel, x1, y1, x2 + 1, y2 + 1, px_map);
    if (err != ESP_OK) {
        s_flush_errors++;
        ESP_LOGE(TAG, "FIRST_ERROR flush=%s area=(%d,%d)-(%d,%d)", esp_err_to_name(err), x1, y1, x2, y2);
        lv_display_flush_ready(disp);
        return;
    }
    s_last_flush_start = start;
}

static bool lcd_perf_on_color_done(esp_lcd_panel_handle_t panel,
                                   const esp_lcd_rgb_panel_event_data_t *event_data, void *user_ctx)
{
    (void)panel; (void)event_data;
    lv_display_t *disp = (lv_display_t *)user_ctx;
    const uint32_t elapsed = (uint32_t)esp_timer_get_time() - s_last_flush_start;
    s_flush_done++;
    s_flush_total_us += elapsed;
    if (elapsed > s_flush_max_us) s_flush_max_us = elapsed;
    lv_display_flush_ready(disp);
    return false;
}

#if CONFIG_LCD_PERF_BUFFER_MODE_DOUBLE
static bool lcd_perf_on_frame_done(esp_lcd_panel_handle_t panel,
                                   const esp_lcd_rgb_panel_event_data_t *event_data, void *user_ctx)
{
    (void)panel; (void)event_data; (void)user_ctx;
    BaseType_t hp_task_woken = pdFALSE;
    if (s_lvgl_task) vTaskNotifyGiveFromISR(s_lvgl_task, &hp_task_woken);
    return hp_task_woken == pdTRUE;
}
static void lcd_perf_flush_wait_cb(lv_display_t *disp)
{
    if (lv_display_flush_is_last(disp)) {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
        s_flush_done++;
    }
    lv_display_flush_ready(disp);
}
#endif

static void lcd_perf_tick_cb(void *arg)
{
    (void)arg;
    lv_tick_inc(LCD_TICK_MS);
}

static void lcd_perf_task(void *arg)
{
    (void)arg;
    int64_t report_start = esp_timer_get_time();
    uint32_t report_frames = 0;
    while (true) {
        lcd_perf_lock(1000);
        uint32_t next_ms = lv_timer_handler();
        lcd_perf_unlock();
        if (next_ms < 1) next_ms = 1;
        if (next_ms > 100) next_ms = 100;
        /* With CONFIG_FREERTOS_HZ=100, pdMS_TO_TICKS(1) is zero.
         * Always delay at least one scheduler tick so IDLE can run. */
        TickType_t delay_ticks = pdMS_TO_TICKS(next_ms);
        if (delay_ticks < 1) delay_ticks = 1;
        vTaskDelay(delay_ticks);
        const int64_t now = esp_timer_get_time();
        if (now - report_start >= (int64_t)CONFIG_LCD_PERF_LOG_PERIOD_MS * 1000) {
            const uint32_t done = s_flush_done;
            const uint32_t delta = done - report_frames;
            const double seconds = (double)(now - report_start) / 1000000.0;
            const uint32_t avg = done ? (uint32_t)(s_flush_total_us / done) : 0;
            ESP_LOGI(TAG, "PERF fps=%.2f flush_done=%" PRIu32 " avg_flush_us=%" PRIu32
                     " max_flush_us=%" PRIu32 " flush_err=%" PRIu32
                     " heap=%u psram=%u min_heap=%u",
                     delta / seconds, done, avg, s_flush_max_us, s_flush_errors,
                     (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL),
                     (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM),
                     (unsigned)heap_caps_get_minimum_free_size(MALLOC_CAP_INTERNAL));
            report_start = now;
            report_frames = done;
        }
    }
}

static esp_err_t lcd_perf_new_panel(void)
{
    esp_lcd_rgb_panel_config_t cfg = {
        .clk_src = LCD_CLK_SRC_PLL160M,
        .data_width = 16,
        .dma_burst_size = 64,
#if CONFIG_LCD_PERF_BUFFER_MODE_DOUBLE
        .num_fbs = 2,
#else
        .num_fbs = 1,
#endif
#if CONFIG_LCD_PERF_BUFFER_MODE_BOUNCE
        .bounce_buffer_size_px = LCD_H_RES * CONFIG_LCD_PERF_BOUNCE_LINES,
#endif
        .disp_gpio_num = 38, .pclk_gpio_num = 40, .vsync_gpio_num = 45,
        .hsync_gpio_num = 44, .de_gpio_num = 43,
        .data_gpio_nums = {8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 33, 34, 35, 36},
        .timings = {
            .pclk_hz = CONFIG_LCD_PERF_PCLK_HZ, .h_res = LCD_H_RES, .v_res = LCD_V_RES,
            .hsync_pulse_width = CONFIG_LCD_PERF_HSYNC_PULSE,
            .hsync_back_porch = CONFIG_LCD_PERF_HBP, .hsync_front_porch = CONFIG_LCD_PERF_HFP,
            .vsync_pulse_width = CONFIG_LCD_PERF_VSYNC_PULSE,
            .vsync_back_porch = CONFIG_LCD_PERF_VBP, .vsync_front_porch = CONFIG_LCD_PERF_VFP,
            .flags.pclk_active_neg = true,
        },
        .flags.fb_in_psram = true,
    };
    ESP_RETURN_ON_ERROR(esp_lcd_new_rgb_panel(&cfg, &s_panel), TAG, "new RGB panel failed");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_reset(s_panel), TAG, "panel reset failed");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_init(s_panel), TAG, "panel init failed");
    return ESP_OK;
}

lv_display_t *lcd_perf_port_init(void)
{
    ESP_ERROR_CHECK(lcd_perf_new_panel());
    lv_init();
    s_display = lv_display_create(LCD_H_RES, LCD_V_RES);
    lv_display_set_color_format(s_display, LV_COLOR_FORMAT_RGB565);
    lv_display_set_user_data(s_display, s_panel);
    void *buf1 = NULL, *buf2 = NULL;
#if CONFIG_LCD_PERF_BUFFER_MODE_DOUBLE
    ESP_ERROR_CHECK(esp_lcd_rgb_panel_get_frame_buffer(s_panel, 2, &buf1, &buf2));
    lv_display_set_buffers(s_display, buf1, buf2, LCD_H_RES * LCD_V_RES * LCD_PIXEL_SIZE,
                           LV_DISPLAY_RENDER_MODE_DIRECT);
#else
    const size_t size = LCD_H_RES * CONFIG_LCD_PERF_DRAW_BUF_LINES * LCD_PIXEL_SIZE;
    buf1 = esp_lcd_rgb_alloc_draw_buffer(s_panel, size, 0);
 #if CONFIG_LCD_PERF_DRAW_BUF_DOUBLE
    buf2 = esp_lcd_rgb_alloc_draw_buffer(s_panel, size, 0);
 #endif
    ESP_ERROR_CHECK(buf1 ? ESP_OK : ESP_ERR_NO_MEM);
    lv_display_set_buffers(s_display, buf1, buf2, size, LV_DISPLAY_RENDER_MODE_PARTIAL);
#endif
    lv_display_set_flush_cb(s_display, lcd_perf_flush_cb);
#if CONFIG_LCD_PERF_BUFFER_MODE_DOUBLE
    lv_display_set_flush_wait_cb(s_display, lcd_perf_flush_wait_cb);
#endif
    esp_lcd_rgb_panel_event_callbacks_t cbs = {
#if CONFIG_LCD_PERF_BUFFER_MODE_DOUBLE
        .on_frame_buf_complete = lcd_perf_on_frame_done,
#else
        .on_color_trans_done = lcd_perf_on_color_done,
#endif
    };
    ESP_ERROR_CHECK(esp_lcd_rgb_panel_register_event_callbacks(s_panel, &cbs, s_display));
    const esp_timer_create_args_t tick_args = {.callback = lcd_perf_tick_cb, .name = "lvgl_tick"};
    esp_timer_handle_t timer;
    ESP_ERROR_CHECK(esp_timer_create(&tick_args, &timer));
    ESP_ERROR_CHECK(esp_timer_start_periodic(timer, LCD_TICK_MS * 1000));
    xTaskCreatePinnedToCore(lcd_perf_task, "lvgl", LCD_TASK_STACK, NULL, LCD_TASK_PRIORITY,
                            &s_lvgl_task, 1);
    return s_display;
}

bool lcd_perf_lock(uint32_t timeout_ms)
{
    (void)timeout_ms;
    _lock_acquire(&s_lvgl_lock);
    return true;
}
void lcd_perf_unlock(void)
{
    _lock_release(&s_lvgl_lock);
}
void lcd_perf_port_log_config(const char *demo_name)
{
    const uint32_t htotal = CONFIG_LCD_PERF_HSYNC_PULSE + CONFIG_LCD_PERF_HBP + LCD_H_RES + CONFIG_LCD_PERF_HFP;
    const uint32_t vtotal = CONFIG_LCD_PERF_VSYNC_PULSE + CONFIG_LCD_PERF_VBP + LCD_V_RES + CONFIG_LCD_PERF_VFP;
    const double refresh = (double)CONFIG_LCD_PERF_PCLK_HZ / ((double)htotal * vtotal);
    ESP_LOGI(TAG, "START demo=%s pclk=%dHz htotal=%u vtotal=%u refresh=%.2fHz draw_lines=%d draw_double=%d",
             demo_name, CONFIG_LCD_PERF_PCLK_HZ, htotal, vtotal, refresh,
             CONFIG_LCD_PERF_DRAW_BUF_LINES,
#if CONFIG_LCD_PERF_DRAW_BUF_DOUBLE
             1);
#else
             0);
#endif
}
