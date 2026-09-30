#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_partition.h"
#include "esp_random.h"
#include "esp_system.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sdkconfig.h"

static const char *TAG = "sys02f";
#define FLASH_BLOCK 4096U
#define PSRAM_BLOCK (256U * 1024U)

typedef struct {
    uint8_t *flash_buf;
    uint8_t *ps_a;
    uint8_t *ps_b;
    const esp_partition_t *partition;
    uint64_t flash_bytes;
    uint64_t psram_bytes;
    uint32_t read_errors;
    uint32_t verify_errors;
    size_t min_internal_free;
    size_t min_internal_largest;
    size_t min_psram_free;
    size_t min_psram_largest;
} stress_ctx_t;

static uint32_t checksum(const uint8_t *data, size_t bytes)
{
    uint32_t sum = 0;
    for (size_t i = 0; i < bytes; ++i) {
        sum = (sum << 5) - sum + data[i];
    }
    return sum;
}

static void update_minimums(stress_ctx_t *ctx)
{
    const size_t int_free = heap_caps_get_free_size(MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    const size_t int_largest = heap_caps_get_largest_free_block(MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    const size_t ps_free = heap_caps_get_free_size(MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    const size_t ps_largest = heap_caps_get_largest_free_block(MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (int_free < ctx->min_internal_free) ctx->min_internal_free = int_free;
    if (int_largest < ctx->min_internal_largest) ctx->min_internal_largest = int_largest;
    if (ps_free < ctx->min_psram_free) ctx->min_psram_free = ps_free;
    if (ps_largest < ctx->min_psram_largest) ctx->min_psram_largest = ps_largest;
}

static void print_progress(const stress_ctx_t *ctx, int64_t elapsed_us)
{
    const double elapsed_s = (double)elapsed_us / 1000000.0;
    ESP_LOGI(TAG, "progress: elapsed=%.1f s flash=%.2f MiB/s psram=%.2f MiB/s"
             " read_err=%" PRIu32 " verify_err=%" PRIu32,
             elapsed_s,
             (double)ctx->flash_bytes / elapsed_s / 1024.0 / 1024.0,
             (double)ctx->psram_bytes / elapsed_s / 1024.0 / 1024.0,
             ctx->read_errors, ctx->verify_errors);
    ESP_LOGI(TAG, "heap: int_free=%u int_largest=%u ps_free=%u ps_largest=%u"
             " min_int_free=%u min_int_largest=%u min_ps_free=%u min_ps_largest=%u",
             (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT),
             (unsigned)heap_caps_get_largest_free_block(MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT),
             (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT),
             (unsigned)heap_caps_get_largest_free_block(MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT),
             (unsigned)ctx->min_internal_free, (unsigned)ctx->min_internal_largest,
             (unsigned)ctx->min_psram_free, (unsigned)ctx->min_psram_largest);
}

void app_main(void)
{
    const esp_partition_t *partition = esp_partition_find_first(
        ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_DATA_SPIFFS, "bench");
    stress_ctx_t *ctx = calloc(1, sizeof(*ctx));
    if (partition == NULL || ctx == NULL) {
        ESP_LOGE(TAG, "bench partition or context allocation failed");
        free(ctx);
        vTaskDelete(NULL);
        return;
    }
    ctx->partition = partition;
    ctx->flash_buf = heap_caps_malloc(FLASH_BLOCK, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    ctx->ps_a = heap_caps_malloc(PSRAM_BLOCK, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    ctx->ps_b = heap_caps_malloc(PSRAM_BLOCK, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    ctx->min_internal_free = SIZE_MAX;
    ctx->min_internal_largest = SIZE_MAX;
    ctx->min_psram_free = SIZE_MAX;
    ctx->min_psram_largest = SIZE_MAX;
    if (ctx->flash_buf == NULL || ctx->ps_a == NULL || ctx->ps_b == NULL) {
        ESP_LOGE(TAG, "stress buffer allocation failed");
        free(ctx->flash_buf); free(ctx->ps_a); free(ctx->ps_b); free(ctx);
        vTaskDelete(NULL);
        return;
    }
    memset(ctx->ps_a, 0x5a, PSRAM_BLOCK);
    memset(ctx->ps_b, 0xa5, PSRAM_BLOCK);
    update_minimums(ctx);

    const int64_t start = esp_timer_get_time();
    const int64_t deadline = start + (int64_t)CONFIG_SYS02F_DURATION_MINUTES * 60LL * 1000000LL;
    int64_t next_log = start;
    size_t flash_offset = 0;
    uint32_t expected_psram_sum = checksum(ctx->ps_a, PSRAM_BLOCK);
    ESP_LOGI(TAG, "SYS-02F start: duration=%d min log=%d sec reset_reason=%d",
             CONFIG_SYS02F_DURATION_MINUTES, CONFIG_SYS02F_LOG_INTERVAL_SEC,
             esp_reset_reason());

    while (esp_timer_get_time() < deadline) {
        if (flash_offset + FLASH_BLOCK > partition->size) {
            flash_offset = 0;
        }
        if (esp_partition_read(partition, flash_offset, ctx->flash_buf, FLASH_BLOCK) != ESP_OK) {
            ++ctx->read_errors;
        } else {
            (void)checksum(ctx->flash_buf, FLASH_BLOCK);
            ctx->flash_bytes += FLASH_BLOCK;
        }
        flash_offset += FLASH_BLOCK;

        memcpy(ctx->ps_b, ctx->ps_a, PSRAM_BLOCK);
        if (checksum(ctx->ps_b, PSRAM_BLOCK) != expected_psram_sum) {
            ++ctx->verify_errors;
        }
        memcpy(ctx->ps_a, ctx->ps_b, PSRAM_BLOCK);
        ctx->psram_bytes += 2ULL * PSRAM_BLOCK;

        void *temporary = heap_caps_malloc(1024U + (esp_random() % 16384U),
                                           MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
        if (temporary != NULL) {
            memset(temporary, 0x3c, 1024U);
            heap_caps_free(temporary);
        }
        update_minimums(ctx);

        const int64_t now = esp_timer_get_time();
        if (now >= next_log) {
            print_progress(ctx, now - start);
            next_log = now + (int64_t)CONFIG_SYS02F_LOG_INTERVAL_SEC * 1000000LL;
        }
        vTaskDelay(1);
    }
    print_progress(ctx, esp_timer_get_time() - start);
    ESP_LOGI(TAG, "SYS-02F complete: read_err=%" PRIu32 " verify_err=%" PRIu32,
             ctx->read_errors, ctx->verify_errors);
    free(ctx->flash_buf); free(ctx->ps_a); free(ctx->ps_b); free(ctx);
    vTaskDelete(NULL);
}
