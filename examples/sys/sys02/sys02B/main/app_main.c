#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "sys02b";
#define TEST_BYTES (64U * 1024U)
#define TEST_MS 2000

typedef struct {
    const char *name;
    uint8_t *dst;
    const uint8_t *src;
    size_t bytes;
} copy_case_t;

static uint32_t checksum(const uint8_t *data, size_t bytes)
{
    uint32_t sum = 0;
    for (size_t i = 0; i < bytes; ++i) {
        sum = (sum << 5) - sum + data[i];
    }
    return sum;
}

static void run_copy(const copy_case_t *test)
{
    const int64_t start = esp_timer_get_time();
    int64_t now = start;
    uint64_t copies = 0;
    while ((now - start) < (int64_t)TEST_MS * 1000) {
        for (int i = 0; i < 64; ++i) {
            memcpy(test->dst, test->src, test->bytes);
        }
        copies += 64;
        now = esp_timer_get_time();
    }
    const int64_t elapsed = now - start;
    const double mib_per_s = (double)(copies * test->bytes) * 1000000.0 /
                             ((double)elapsed * 1024.0 * 1024.0);
    ESP_LOGI(TAG, "%s: copies=%" PRIu64 " elapsed=%" PRId64
             " us bandwidth=%.2f MiB/s checksum=0x%08" PRIx32,
             test->name, copies, elapsed, mib_per_s,
             checksum(test->dst, test->bytes));
}

void app_main(void)
{
    uint8_t *int_a = heap_caps_malloc(TEST_BYTES, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    uint8_t *int_b = heap_caps_malloc(TEST_BYTES, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    uint8_t *ps_a = heap_caps_malloc(TEST_BYTES, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    uint8_t *ps_b = heap_caps_malloc(TEST_BYTES, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (int_a == NULL || int_b == NULL || ps_a == NULL || ps_b == NULL) {
        ESP_LOGE(TAG, "buffer allocation failed; check PSRAM configuration");
        free(int_a); free(int_b); free(ps_a); free(ps_b);
        vTaskDelete(NULL);
        return;
    }
    for (size_t i = 0; i < TEST_BYTES; ++i) {
        int_a[i] = (uint8_t)(i * 13U + 7U);
        ps_a[i] = (uint8_t)(i * 29U + 3U);
    }

    ESP_LOGI(TAG, "SYS-02B start: buffer=%u bytes duration=%d ms", TEST_BYTES, TEST_MS);
    const copy_case_t cases[] = {
        {"INT->INT", int_b, int_a, TEST_BYTES},
        {"INT->PSRAM", ps_b, int_a, TEST_BYTES},
        {"PSRAM->INT", int_b, ps_a, TEST_BYTES},
        {"PSRAM->PSRAM", ps_b, ps_a, TEST_BYTES},
    };
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        run_copy(&cases[i]);
        vTaskDelay(pdMS_TO_TICKS(100));
    }
    free(int_a); free(int_b); free(ps_a); free(ps_b);
    ESP_LOGI(TAG, "SYS-02B complete");
    vTaskDelete(NULL);
}
