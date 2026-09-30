#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_task_wdt.h"
#include "esp_system.h"
#include "esp_timer.h"
#include "esp_log.h"

/* Set to 1, rebuild and flash to intentionally trigger the task watchdog. */
#ifndef SYS03D_TRIGGER_TIMEOUT
#define SYS03D_TRIGGER_TIMEOUT 0
#endif

static const char *TAG = "sys03d";

static void watched_task(void *arg)
{
    (void)arg;
    ESP_ERROR_CHECK(esp_task_wdt_add(NULL));
    int64_t last = esp_timer_get_time();
    uint32_t n = 0;
    while (1) {
#if SYS03D_TRIGGER_TIMEOUT
        if (esp_timer_get_time() - last < 8000000) {
            esp_task_wdt_reset();
            vTaskDelay(pdMS_TO_TICKS(100));
        } else {
            ESP_LOGW(TAG, "stop feeding TWDT now; reset is expected");
            while (1) { volatile uint32_t x = n++; (void)x; }
        }
#else
        esp_task_wdt_reset();
        if ((n++ % 20) == 0) ESP_LOGI(TAG, "watched task alive core=%d", xPortGetCoreID());
        vTaskDelay(pdMS_TO_TICKS(100));
#endif
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "SYS-03D task watchdog start trigger=%d reset_reason=%d", SYS03D_TRIGGER_TIMEOUT, esp_reset_reason());
    esp_task_wdt_config_t cfg = {.timeout_ms=3000, .idle_core_mask=0, .trigger_panic=true};
    esp_err_t err = esp_task_wdt_init(&cfg);
    if (err == ESP_ERR_INVALID_STATE) err = esp_task_wdt_reconfigure(&cfg);
    ESP_ERROR_CHECK(err);
    xTaskCreatePinnedToCore(watched_task, "sys03d_watched", 4096, NULL, 5, NULL, 1);
}
