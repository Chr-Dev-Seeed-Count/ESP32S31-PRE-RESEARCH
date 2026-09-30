#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"

static const char *TAG = "sys03e";

static void coredump_task(void *arg)
{
    (void)arg;
    vTaskDelay(pdMS_TO_TICKS(3000));
    ESP_LOGE(TAG, "triggering deliberate null-pointer panic for coredump");
    volatile uint32_t *bad = (volatile uint32_t *)0;
    *bad = 0xC0DE03E;
    vTaskDelete(NULL);
}

void app_main(void)
{
    ESP_LOGI(TAG, "SYS-03E coredump start reset_reason=%d", esp_reset_reason());
    ESP_LOGI(TAG, "Configure Core dump to Flash in menuconfig before running this demo");
    xTaskCreatePinnedToCore(coredump_task, "sys03e_panic", 4096, NULL, 5, NULL, 1);
}
