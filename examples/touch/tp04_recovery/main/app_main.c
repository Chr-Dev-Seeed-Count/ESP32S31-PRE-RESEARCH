#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "driver/i2c_master.h"
#include "esp_err.h"
#include "esp_lcd_panel_io.h"
#include "esp_lcd_touch.h"
#include "esp_lcd_touch_gt1151.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "tp04";
#define TEST_DURATION_S 120
#define POLL_MS 10
#define RECOVERY_PERIOD_S 10

static esp_lcd_panel_io_handle_t s_io;
static esp_lcd_touch_handle_t s_tp;

static esp_err_t touch_create(void)
{
    const esp_lcd_panel_io_i2c_config_t io_cfg = ESP_LCD_TOUCH_IO_I2C_GT1151_CONFIG();
    esp_err_t err = esp_lcd_new_panel_io_i2c(bsp_i2c_get_handle(), &io_cfg, &s_io);
    if (err != ESP_OK) return err;
    const esp_lcd_touch_config_t tp_cfg = {
        .x_max = 800,
        .y_max = 480,
        .rst_gpio_num = GPIO_NUM_NC,
        .int_gpio_num = GPIO_NUM_NC,
        .levels = {.reset = 0, .interrupt = 0},
        .flags = {.swap_xy = false, .mirror_x = false, .mirror_y = false},
    };
    err = esp_lcd_touch_new_i2c_gt1151(s_io, &tp_cfg, &s_tp);
    if (err != ESP_OK) {
        esp_lcd_panel_io_del(s_io);
        s_io = NULL;
    }
    return err;
}

static void touch_destroy(void)
{
    if (s_tp) { esp_lcd_touch_del(s_tp); s_tp = NULL; }
    if (s_io) { esp_lcd_panel_io_del(s_io); s_io = NULL; }
}

static esp_err_t touch_recover(uint32_t cycle, uint32_t *recovery_us)
{
    const int64_t start = esp_timer_get_time();
    touch_destroy();
    const esp_err_t reset_err = i2c_master_bus_reset(bsp_i2c_get_handle());
    const esp_err_t init_err = reset_err == ESP_OK ? touch_create() : reset_err;
    *recovery_us = (uint32_t)(esp_timer_get_time() - start);
    ESP_LOGI(TAG, "RECOVERY cycle=%" PRIu32 " bus_reset=%s reinit=%s elapsed=%" PRIu32 " us",
             cycle, esp_err_to_name(reset_err), esp_err_to_name(init_err), *recovery_us);
    return init_err;
}

void app_main(void)
{
    ESP_ERROR_CHECK(bsp_i2c_init());
    ESP_ERROR_CHECK(touch_create());
    ESP_LOGI(TAG, "TP-04 I2C reset/reconnect test: %d s, recovery every %d s", TEST_DURATION_S, RECOVERY_PERIOD_S);
    ESP_LOGI(TAG, "For physical LCD-subboard unplug/replug, do it between RECOVERY log lines; reset pin and INT are NC on this board");

    uint32_t read_ok = 0, read_err = 0, recover_ok = 0, recover_err = 0;
    uint32_t cycle = 0;
    int64_t start = esp_timer_get_time();
    int64_t next_recovery = start + RECOVERY_PERIOD_S * 1000000LL;
    int64_t last_report = start;
    while (esp_timer_get_time() - start < TEST_DURATION_S * 1000000LL) {
        const int64_t now = esp_timer_get_time();
        if (now >= next_recovery) {
            uint32_t recovery_us = 0;
            const esp_err_t err = touch_recover(++cycle, &recovery_us);
            if (err == ESP_OK) recover_ok++; else recover_err++;
            next_recovery += RECOVERY_PERIOD_S * 1000000LL;
            continue;
        }

        esp_lcd_touch_point_data_t point[1] = {0};
        uint8_t count = 0;
        esp_err_t err = s_tp ? esp_lcd_touch_read_data(s_tp) : ESP_ERR_INVALID_STATE;
        if (err == ESP_OK) err = esp_lcd_touch_get_data(s_tp, point, &count, 1);
        if (err == ESP_OK) read_ok++; else read_err++;
        if (now - last_report >= 5000000LL) {
            ESP_LOGI(TAG, "PERF: read_ok=%" PRIu32 " read_err=%" PRIu32 " recover_ok=%" PRIu32 " recover_err=%" PRIu32 " touch=%s",
                     read_ok, read_err, recover_ok, recover_err, count ? "DOWN" : "UP");
            last_report = now;
        }
        vTaskDelay(pdMS_TO_TICKS(POLL_MS));
    }
    ESP_LOGI(TAG, "TP-04 SUMMARY: read_ok=%" PRIu32 " read_err=%" PRIu32 " recover_ok=%" PRIu32 " recover_err=%" PRIu32,
             read_ok, read_err, recover_ok, recover_err);
    touch_destroy();
    while (true) vTaskDelay(pdMS_TO_TICKS(1000));
}
