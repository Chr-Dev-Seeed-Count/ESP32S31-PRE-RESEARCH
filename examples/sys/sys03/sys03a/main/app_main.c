#include <stdint.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "esp_heap_caps.h"
#include "esp_system.h"

static const char *TAG = "sys03a";

static void worker(void *arg)
{
    const int target_core = (int)(intptr_t)arg;
    uint32_t loops = 0;
    uint64_t busy_us = 0;
    int64_t t0 = esp_timer_get_time();
    while (1) {
        int64_t begin = esp_timer_get_time();
        volatile uint32_t acc = 0x12345678;
        for (int i = 0; i < 120000; ++i) acc = acc * 1664525u + 1013904223u;
        (void)acc;
        busy_us += (uint64_t)(esp_timer_get_time() - begin);
        loops++;
        if (esp_timer_get_time() - t0 >= 5000000) {
            int64_t elapsed = esp_timer_get_time() - t0;
            ESP_LOGI(TAG, "task=%s expected_core=%d actual_core=%d loops=%lu busy_avg=%lld us CPU~%.1f%% stack_free=%u heap=%lu",
                     pcTaskGetName(NULL), target_core, xPortGetCoreID(), (unsigned long)loops,
                     loops ? (long long)(busy_us / loops) : 0LL,
                     (double)busy_us * 100.0 / (double)elapsed,
                     (unsigned)uxTaskGetStackHighWaterMark(NULL), (unsigned long)esp_get_free_heap_size());
            loops = 0; busy_us = 0; t0 = esp_timer_get_time();
        }
        vTaskDelay(1);
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "SYS-03A task affinity start");
    xTaskCreatePinnedToCore(worker, "sys03a_c0", 4096, (void *)0, 5, NULL, 0);
    xTaskCreatePinnedToCore(worker, "sys03a_c1", 4096, (void *)1, 5, NULL, 1);
}
