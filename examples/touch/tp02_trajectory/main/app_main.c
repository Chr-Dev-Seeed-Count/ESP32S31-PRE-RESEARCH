#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "bsp/touch.h"
#include "esp_err.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_touch.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "tp02";

#define LCD_W 800
#define LCD_H 480
#define TEST_MS 12000
#define POLL_MS 2
#define LCD_UPDATE_MS 20
#define MAX_STEP_PX 120
#define SAMPLE_INTERVAL_WARN_MS 30
#define RELEASE_CONFIRM_MS 30
#define WAIT_START_MS 10000
#define MOTION_MAX_MS 5000
#define LONG_PRESS_MS 3000

static esp_lcd_panel_handle_t s_panel;

static void lcd_fill(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color)
{
    static uint16_t pixels[17 * 17];
    if (w > 17 || h > 17 || x >= LCD_W || y >= LCD_H) return;
    if (x + w > LCD_W) w = LCD_W - x;
    if (y + h > LCD_H) h = LCD_H - y;
    for (uint16_t i = 0; i < w * h; ++i) pixels[i] = color;
    ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(s_panel, x, y, x + w, y + h, pixels));
}

static void lcd_clear(void)
{
    static uint16_t line[LCD_W];
    for (int y = 0; y < LCD_H; ++y) {
        ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(s_panel, 0, y, LCD_W, y + 1, line));
    }
}

static void lcd_marker(uint16_t x, uint16_t y, uint16_t color)
{
    enum { R = 8, S = 2 * R + 1 };
    static uint16_t pixels[S * S];
    for (int py = -R; py <= R; ++py) {
        for (int px = -R; px <= R; ++px) {
            const int d2 = px * px + py * py;
            pixels[(py + R) * S + (px + R)] = (d2 <= 4 || (d2 >= 36 && d2 <= 64)) ? color : 0x0000;
        }
    }
    int x1 = (int)x - R;
    int y1 = (int)y - R;
    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x1 + S > LCD_W) x1 = LCD_W - S;
    if (y1 + S > LCD_H) y1 = LCD_H - S;
    ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(s_panel, x1, y1, x1 + S, y1 + S, pixels));
}

static void lcd_trail(uint16_t x, uint16_t y)
{
    lcd_fill(x > 1 ? x - 1 : 0, y > 1 ? y - 1 : 0, 3, 3, 0x07E0);
}

typedef struct {
    uint32_t polls, samples, read_errors, no_point_polls;
    uint32_t short_dropouts, interval_warnings, large_steps;
    uint32_t max_step, max_interval_us, max_no_point_us;
    uint64_t path, read_time_us;
    uint32_t read_time_max_us;
    int64_t first_sample_us, last_sample_us;
} trajectory_stats_t;

static esp_err_t touch_read(esp_lcd_touch_handle_t tp, esp_lcd_touch_point_data_t point[1], uint8_t *count, trajectory_stats_t *st)
{
    const int64_t read_start = esp_timer_get_time();
    esp_err_t err = esp_lcd_touch_read_data(tp);
    if (err == ESP_OK) err = esp_lcd_touch_get_data(tp, point, count, 1);
    const uint32_t read_us = (uint32_t)(esp_timer_get_time() - read_start);
    st->read_time_us += read_us;
    if (read_us > st->read_time_max_us) st->read_time_max_us = read_us;
    st->polls++;
    return err;
}

static void run_trajectory(esp_lcd_touch_handle_t tp, const char *name, uint16_t marker_color, bool is_long_press)
{
    trajectory_stats_t st = {0};
    uint16_t last_x = 0, last_y = 0;
    int64_t last_t = 0, lcd_update = 0, no_point_since = 0;
    bool active = false, completed = false, released = false;
    const int64_t wait_start = esp_timer_get_time();
    int64_t active_start = 0;

    lcd_clear();
    ESP_LOGI(TAG, "TRAJECTORY %s: wait for finger (max %d ms), then %s; LCD shows live point/trail",
             name, WAIT_START_MS, is_long_press ? "hold for 3 s" : "perform one gesture and release");
    while (true) {
        const int64_t now = esp_timer_get_time();
        esp_lcd_touch_point_data_t p[1] = {0};
        uint8_t n = 0;
        const esp_err_t err = touch_read(tp, p, &n, &st);

        if (err != ESP_OK) {
            st.read_errors++;
        } else if (!active) {
            if (n > 0) {
                active = true;
                active_start = now;
                st.first_sample_us = now;
                last_x = p[0].x;
                last_y = p[0].y;
                last_t = now;
                st.last_sample_us = now;
                st.samples = 1;
                lcd_trail(last_x, last_y);
                lcd_marker(last_x, last_y, marker_color);
                lcd_update = now;
            } else if (now - wait_start >= WAIT_START_MS * 1000LL) {
                ESP_LOGW(TAG, "RESULT %s: WAIT_TIMEOUT (no touch received)", name);
                return;
            }
        } else if (n > 0) {
            if (no_point_since != 0) {
                const uint32_t absence_us = (uint32_t)(now - no_point_since);
                st.short_dropouts++;
                if (absence_us > st.max_no_point_us) st.max_no_point_us = absence_us;
                no_point_since = 0;
            }
            const uint32_t dx = p[0].x > last_x ? p[0].x - last_x : last_x - p[0].x;
            const uint32_t dy = p[0].y > last_y ? p[0].y - last_y : last_y - p[0].y;
            const uint32_t step = (uint32_t)sqrt((double)dx * dx + (double)dy * dy);
            const uint32_t interval = (uint32_t)(now - last_t);
            st.path += step;
            if (step > st.max_step) st.max_step = step;
            if (interval > st.max_interval_us) st.max_interval_us = interval;
            if (step > MAX_STEP_PX) st.large_steps++;
            if (interval > SAMPLE_INTERVAL_WARN_MS * 1000U) st.interval_warnings++;
            last_x = p[0].x;
            last_y = p[0].y;
            last_t = now;
            st.last_sample_us = now;
            st.samples++;
            if (now - lcd_update >= LCD_UPDATE_MS * 1000LL) {
                lcd_trail(p[0].x, p[0].y);
                lcd_marker(p[0].x, p[0].y, marker_color);
                lcd_update = now;
            }
        } else {
            st.no_point_polls++;
            if (no_point_since == 0) no_point_since = now;
            if (now - no_point_since >= RELEASE_CONFIRM_MS * 1000LL) {
                released = true;
                break;
            }
        }
        if (active && is_long_press && now - active_start >= LONG_PRESS_MS * 1000LL) {
            completed = true;
            break;
        }
        if (active && !is_long_press && now - active_start >= MOTION_MAX_MS * 1000LL) break;
        vTaskDelay(pdMS_TO_TICKS(POLL_MS));
    }

    const double active_s = (double)(esp_timer_get_time() - active_start) / 1000000.0;
    const double contact_s = st.samples > 1 ? (double)(st.last_sample_us - st.first_sample_us) / 1000000.0 : active_s;
    const double sample_rate = contact_s > 0.0 ? st.samples / contact_s : 0.0;
    const uint32_t read_avg = st.polls ? (uint32_t)(st.read_time_us / st.polls) : 0;
    ESP_LOGI(TAG, "RESULT %s: samples=%" PRIu32 " active=%.2f s sample_rate=%.1f Hz path=%" PRIu64 " px max_step=%" PRIu32 " large_steps=%" PRIu32, name, st.samples, active_s, sample_rate, st.path, st.max_step, st.large_steps);
    ESP_LOGI(TAG, "DIAG %s: polls=%" PRIu32 " read_err=%" PRIu32 " no_point=%" PRIu32 " short_dropouts=%" PRIu32 " max_no_point=%" PRIu32 " us max_interval=%" PRIu32 " us interval_gt_%dms=%" PRIu32 " read_avg=%" PRIu32 " us read_max=%" PRIu32 " us end=%s", name, st.polls, st.read_errors, st.no_point_polls, st.short_dropouts, st.max_no_point_us, st.max_interval_us, SAMPLE_INTERVAL_WARN_MS, st.interval_warnings, read_avg, st.read_time_max_us, completed ? "HOLD_COMPLETE" : (released ? "RELEASE" : "MOTION_TIMEOUT"));
}

void app_main(void)
{
    esp_lcd_panel_io_handle_t panel_io = NULL;
    ESP_ERROR_CHECK(bsp_display_new(NULL, &s_panel, &panel_io));
    (void)panel_io;
    ESP_ERROR_CHECK(esp_lcd_panel_disp_on_off(s_panel, true));
    lcd_clear();
    esp_lcd_touch_handle_t tp = NULL;
    ESP_ERROR_CHECK(bsp_touch_new(NULL, &tp));
    ESP_LOGI(TAG, "TP-02 continuous trajectory; poll=%d ms, interval warning=%d ms", POLL_MS, SAMPLE_INTERVAL_WARN_MS);
    ESP_LOGI(TAG, "LCD: green trail + colored live marker; one gesture per test, then release");
    run_trajectory(tp, "FAST_LINE", 0xF800, false);
    run_trajectory(tp, "SWIPE", 0x001F, false);
    run_trajectory(tp, "LONG_PRESS", 0xFFE0, true);
    run_trajectory(tp, "DRAG", 0xF81F, false);
    ESP_LOGI(TAG, "TP-02 complete; `large_steps` indicate motion distance, not necessarily lost samples");
    while (true) vTaskDelay(pdMS_TO_TICKS(1000));
}
