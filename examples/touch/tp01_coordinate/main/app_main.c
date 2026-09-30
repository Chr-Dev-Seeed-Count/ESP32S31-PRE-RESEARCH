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

static const char *TAG = "tp01";

#define LCD_W                 800
#define LCD_H                 480
#define TARGET_MARGIN         20
#define SETTLE_MS             1000
#define SAMPLE_WINDOW_MS      2500
#define REQUIRED_SAMPLES      64
#define SAMPLE_PERIOD_MS      10

typedef struct {
    const char *name;
    uint16_t x;
    uint16_t y;
} target_t;

static const target_t targets[] = {
    {"CENTER", LCD_W / 2, LCD_H / 2},
    {"TOP_LEFT", TARGET_MARGIN, TARGET_MARGIN},
    {"TOP_RIGHT", LCD_W - TARGET_MARGIN, TARGET_MARGIN},
    {"BOTTOM_LEFT", TARGET_MARGIN, LCD_H - TARGET_MARGIN},
    {"BOTTOM_RIGHT", LCD_W - TARGET_MARGIN, LCD_H - TARGET_MARGIN},
    {"TOP_EDGE", LCD_W / 2, TARGET_MARGIN},
    {"BOTTOM_EDGE", LCD_W / 2, LCD_H - TARGET_MARGIN},
    {"LEFT_EDGE", TARGET_MARGIN, LCD_H / 2},
    {"RIGHT_EDGE", LCD_W - TARGET_MARGIN, LCD_H / 2},
};

static void draw_target(esp_lcd_panel_handle_t panel, const target_t *target, bool visible)
{
    /* RGB565 marker: black background, white ring and red center. */
    enum { RADIUS = 14, SIDE = 2 * RADIUS + 1 };
    uint16_t pixels[SIDE * SIDE];
    const uint16_t black = 0x0000;
    const uint16_t white = 0xFFFF;
    const uint16_t red = 0xF800;
    for (int y = -RADIUS; y <= RADIUS; ++y) {
        for (int x = -RADIUS; x <= RADIUS; ++x) {
            const int d2 = x * x + y * y;
            uint16_t color = black;
            if (visible && d2 <= RADIUS * RADIUS) {
                color = (d2 <= 25) ? red : white;
            }
            pixels[(y + RADIUS) * SIDE + (x + RADIUS)] = color;
        }
    }
    int x1 = (int)target->x - RADIUS;
    int y1 = (int)target->y - RADIUS;
    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    int x2 = x1 + SIDE;
    int y2 = y1 + SIDE;
    if (x2 > LCD_W) { x1 = LCD_W - SIDE; x2 = LCD_W; }
    if (y2 > LCD_H) { y1 = LCD_H - SIDE; y2 = LCD_H; }
    ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel, x1, y1, x2, y2, pixels));
}

static void clear_screen(esp_lcd_panel_handle_t panel)
{
    /* Clear one scanline at a time to avoid a large framebuffer allocation. */
    static uint16_t line[LCD_W];
    for (int y = 0; y < LCD_H; ++y) {
        ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel, 0, y, LCD_W, y + 1, line));
    }
}

void app_main(void)
{
    esp_lcd_panel_handle_t panel = NULL;
    esp_lcd_panel_io_handle_t panel_io = NULL;
    ESP_ERROR_CHECK(bsp_display_new(NULL, &panel, &panel_io));
    (void)panel_io;
    ESP_ERROR_CHECK(esp_lcd_panel_disp_on_off(panel, true));
    clear_screen(panel);

    esp_lcd_touch_handle_t tp = NULL;
    ESP_ERROR_CHECK(bsp_touch_new(NULL, &tp));
    ESP_LOGI(TAG, "TP-01 coordinate accuracy; GT1151 800x480, I2C 400 kHz nominal");
    ESP_LOGI(TAG, "A target marker is shown on the LCD; touch it with one finger and hold it still");

    double total_error = 0.0;
    uint32_t total_samples = 0;
    uint32_t total_missing = 0;
    uint32_t failed_targets = 0;

    for (size_t t = 0; t < sizeof(targets) / sizeof(targets[0]); ++t) {
        const target_t *target = &targets[t];
        draw_target(panel, target, true);
        ESP_LOGI(TAG, "TARGET %s: (%u,%u) in %d ms", target->name, target->x, target->y, SETTLE_MS);
        vTaskDelay(pdMS_TO_TICKS(SETTLE_MS));

        uint32_t count = 0;
        uint32_t missing = 0;
        double sum_error = 0.0;
        double max_error = 0.0;
        double sum_x = 0.0;
        double sum_y = 0.0;
        const int64_t end = esp_timer_get_time() + SAMPLE_WINDOW_MS * 1000LL;

        while (esp_timer_get_time() < end) {
            esp_lcd_touch_point_data_t point[1] = {0};
            uint8_t point_count = 0;
            const esp_err_t read_err = esp_lcd_touch_read_data(tp);
            const esp_err_t get_err = read_err == ESP_OK ? esp_lcd_touch_get_data(tp, point, &point_count, 1) : read_err;
            if (get_err == ESP_OK && point_count > 0) {
                const double dx = (double)point[0].x - target->x;
                const double dy = (double)point[0].y - target->y;
                const double error = sqrt(dx * dx + dy * dy);
                sum_error += error;
                if (error > max_error) max_error = error;
                sum_x += point[0].x;
                sum_y += point[0].y;
                count++;
            } else {
                missing++;
            }
            vTaskDelay(pdMS_TO_TICKS(SAMPLE_PERIOD_MS));
        }

        if (count < REQUIRED_SAMPLES) failed_targets++;
        const double mean_error = count ? sum_error / count : 0.0;
        const double mean_x = count ? sum_x / count : 0.0;
        const double mean_y = count ? sum_y / count : 0.0;
        total_error += sum_error;
        total_samples += count;
        total_missing += missing;
        ESP_LOGI(TAG,
                 "RESULT %s: samples=%" PRIu32 " missing=%" PRIu32
                 " mean=(%.1f,%.1f) error_avg=%.2f px error_max=%.2f px %s",
                 target->name, count, missing, mean_x, mean_y, mean_error, max_error,
                 count >= REQUIRED_SAMPLES ? "PASS" : "INSUFFICIENT_CONTACT");
        draw_target(panel, target, false);
    }

    const double overall = total_samples ? total_error / total_samples : 0.0;
    ESP_LOGI(TAG, "TP-01 SUMMARY: targets=%u failed_targets=%" PRIu32
             " samples=%" PRIu32 " missing=%" PRIu32 " mean_error=%.2f px",
             (unsigned)(sizeof(targets) / sizeof(targets[0])), failed_targets,
             total_samples, total_missing, overall);
    ESP_LOGI(TAG, "Record each point error; recalibrate or inspect panel alignment if edge/corner error is larger.");

    while (true) vTaskDelay(pdMS_TO_TICKS(1000));
}
