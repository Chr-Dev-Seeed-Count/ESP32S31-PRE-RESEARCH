#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>

#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "sys02e";
#define TEST_MS 60000
#define LOG_MS 5000
#define SLOTS 192

typedef struct {
    void *ptr;
    size_t size;
} allocation_t;

static uint32_t rng_state = 0x31415926;
static uint32_t next_random(void)
{
    rng_state = rng_state * 1664525U + 1013904223U;
    return rng_state;
}

static void print_state(const char *name, uint32_t caps, uint32_t failures)
{
    const size_t free_bytes = heap_caps_get_free_size(caps);
    const size_t largest = heap_caps_get_largest_free_block(caps);
    const double frag = free_bytes ? 1.0 - (double)largest / free_bytes : 1.0;
    ESP_LOGI(TAG, "%s: free=%u largest=%u fragmentation=%.2f failures=%" PRIu32,
             name, (unsigned)free_bytes, (unsigned)largest, frag, failures);
}

static void run_pool(const char *name, uint32_t caps, size_t max_live_bytes)
{
    allocation_t slots[SLOTS] = {0};
    uint32_t failures = 0;
    size_t live_bytes = 0;
    int64_t start = esp_timer_get_time();
    int64_t next_log = start;
    uint32_t operations = 0;
    while (esp_timer_get_time() - start < (int64_t)TEST_MS * 1000) {
        const size_t i = next_random() % SLOTS;
        if (slots[i].ptr != NULL) {
            heap_caps_free(slots[i].ptr);
            live_bytes -= slots[i].size;
            slots[i].ptr = NULL;
            slots[i].size = 0;
        } else {
            const size_t size = 1024U + (next_random() % (64U * 1024U));
            if (live_bytes + size > max_live_bytes) {
                ++failures;
                continue;
            }
            slots[i].ptr = heap_caps_malloc(size, caps);
            if (slots[i].ptr == NULL) {
                ++failures;
            } else {
                slots[i].size = size;
                live_bytes += size;
                ((uint8_t *)slots[i].ptr)[0] = (uint8_t)i;
                ((uint8_t *)slots[i].ptr)[size - 1] = (uint8_t)(i ^ 0xa5U);
            }
        }
        const int64_t now = esp_timer_get_time();
        if (now >= next_log) {
            print_state(name, caps, failures);
            next_log = now + (int64_t)LOG_MS * 1000;
        }
        if ((++operations & 0x3fU) == 0) {
            vTaskDelay(1);
        }
    }
    for (size_t i = 0; i < SLOTS; ++i) {
        heap_caps_free(slots[i].ptr);
    }
    print_state(name, caps, failures);
}

void app_main(void)
{
    ESP_LOGI(TAG, "SYS-02E start: duration=%d ms slots=%d size=1..64 KiB", TEST_MS, SLOTS);
    run_pool("Internal RAM", MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT, 128U * 1024U);
    run_pool("PSRAM", MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT, 8U * 1024U * 1024U);
    ESP_LOGI(TAG, "SYS-02E complete");
    vTaskDelete(NULL);
}
