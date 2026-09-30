#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "esp_err.h"
#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_partition.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"
#include "sdkconfig.h"

static const char *TAG = "sys02d";

#define GO_BIT BIT0
#define DONE_CORE0_BIT BIT1
#define DONE_CORE1_BIT BIT2
#define FLASH_BLOCK_BYTES 4096U

typedef enum {
    OP_SRAM_TO_SRAM,
    OP_PSRAM_TO_PSRAM,
    OP_SRAM_TO_PSRAM,
    OP_FLASH_READ,
} memory_operation_t;

typedef struct {
    const char *name;
    int core;
    EventBits_t done_bit;
    memory_operation_t operation;
    uint8_t *src;
    uint8_t *dst;
    size_t bytes_per_copy;
    uint64_t total_bytes;
    uint64_t copies;
    int64_t elapsed_us;
    uint32_t checksum;
    uint32_t errors;
} worker_t;

typedef struct {
    EventGroupHandle_t events;
    const esp_partition_t *bench_partition;
    worker_t core0;
    worker_t core1;
} test_context_t;

typedef struct {
    test_context_t *ctx;
    worker_t *worker;
} task_arg_t;

static uint32_t checksum(const uint8_t *data, size_t bytes)
{
    uint32_t sum = 0;
    for (size_t i = 0; i < bytes; ++i) {
        sum = (sum << 5) - sum + data[i];
    }
    return sum;
}

static double mib_per_second(uint64_t bytes, int64_t elapsed_us)
{
    return elapsed_us > 0 ? (double)bytes * 1000000.0 /
                           ((double)elapsed_us * 1024.0 * 1024.0) : 0.0;
}

static const char *operation_name(memory_operation_t operation)
{
    switch (operation) {
    case OP_SRAM_TO_SRAM: return "SRAM->SRAM";
    case OP_PSRAM_TO_PSRAM: return "PSRAM->PSRAM";
    case OP_SRAM_TO_PSRAM: return "SRAM->PSRAM";
    case OP_FLASH_READ: return "Flash read";
    default: return "unknown";
    }
}

static uint32_t source_caps(memory_operation_t operation)
{
    return operation == OP_PSRAM_TO_PSRAM ?
           (MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT) :
           (MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
}

static uint32_t destination_caps(memory_operation_t operation)
{
    return (operation == OP_PSRAM_TO_PSRAM || operation == OP_SRAM_TO_PSRAM) ?
           (MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT) :
           (MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
}

static bool allocate_worker_buffers(worker_t *worker)
{
    if (worker->operation == OP_FLASH_READ) {
        worker->bytes_per_copy = FLASH_BLOCK_BYTES;
        worker->dst = heap_caps_malloc(FLASH_BLOCK_BYTES,
                                       MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
        return worker->dst != NULL;
    }
    worker->bytes_per_copy = (size_t)CONFIG_SYS02D_BUFFER_KIB * 1024U;
    worker->src = heap_caps_malloc(worker->bytes_per_copy, source_caps(worker->operation));
    worker->dst = heap_caps_malloc(worker->bytes_per_copy,
                                   destination_caps(worker->operation));
    if (worker->src == NULL || worker->dst == NULL) {
        return false;
    }
    for (size_t i = 0; i < worker->bytes_per_copy; ++i) {
        worker->src[i] = (uint8_t)(i * 29U + (uint8_t)(worker->core * 71U + 3U));
    }
    return true;
}

static void free_worker_buffers(worker_t *worker)
{
    free(worker->src);
    free(worker->dst);
    worker->src = NULL;
    worker->dst = NULL;
}

static void memory_worker_task(void *arg)
{
    task_arg_t *task_arg = arg;
    test_context_t *ctx = task_arg->ctx;
    worker_t *worker = task_arg->worker;

    xEventGroupWaitBits(ctx->events, GO_BIT, pdFALSE, pdTRUE, portMAX_DELAY);
    const int64_t start = esp_timer_get_time();
    const int64_t deadline = start + (int64_t)CONFIG_SYS02D_DURATION_MS * 1000;
    int64_t now = start;
    size_t flash_offset = 0;

    while ((now - start) < (int64_t)CONFIG_SYS02D_DURATION_MS * 1000) {
        for (int i = 0; i < CONFIG_SYS02D_COPIES_PER_TIME_CHECK; ++i) {
            if (worker->operation == OP_FLASH_READ) {
                const esp_err_t err = esp_partition_read(
                    ctx->bench_partition, flash_offset, worker->dst, FLASH_BLOCK_BYTES);
                if (err != ESP_OK) {
                    ++worker->errors;
                } else {
                    worker->total_bytes += FLASH_BLOCK_BYTES;
                }
                flash_offset += FLASH_BLOCK_BYTES;
                if (flash_offset + FLASH_BLOCK_BYTES > ctx->bench_partition->size) {
                    flash_offset = 0;
                }
            } else {
                memcpy(worker->dst, worker->src, worker->bytes_per_copy);
                worker->total_bytes += worker->bytes_per_copy;
            }
            ++worker->copies;
        }
        now = esp_timer_get_time();
    }
    worker->elapsed_us = now - start;
    worker->checksum = checksum(worker->dst, worker->bytes_per_copy);
    (void)deadline;
    xEventGroupSetBits(ctx->events, worker->done_bit);
    vTaskDelete(NULL);
}

static bool configure_scenario(test_context_t *ctx)
{
    ctx->core0.core = 0;
    ctx->core0.done_bit = DONE_CORE0_BIT;
    ctx->core1.core = 1;
    ctx->core1.done_bit = DONE_CORE1_BIT;

    switch (CONFIG_SYS02D_SCENARIO) {
    case 1:
        ctx->core0.name = "D1 Core0 Flash read";
        ctx->core0.operation = OP_FLASH_READ;
        ctx->core1.name = "D1 Core1 PSRAM->PSRAM";
        ctx->core1.operation = OP_PSRAM_TO_PSRAM;
        ctx->bench_partition = esp_partition_find_first(
            ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_DATA_SPIFFS, "bench");
        return ctx->bench_partition != NULL;
    case 2:
        ctx->core0.name = "D2 Core0 SRAM->SRAM";
        ctx->core0.operation = OP_SRAM_TO_SRAM;
        ctx->core1.name = "D2 Core1 SRAM->SRAM";
        ctx->core1.operation = OP_SRAM_TO_SRAM;
        return true;
    case 3:
        ctx->core0.name = "D3 Core0 PSRAM->PSRAM";
        ctx->core0.operation = OP_PSRAM_TO_PSRAM;
        ctx->core1.name = "D3 Core1 PSRAM->PSRAM";
        ctx->core1.operation = OP_PSRAM_TO_PSRAM;
        return true;
    case 4:
        ctx->core0.name = "D4 Core0 PSRAM->PSRAM";
        ctx->core0.operation = OP_PSRAM_TO_PSRAM;
        ctx->core1.name = "D4 Core1 SRAM->SRAM";
        ctx->core1.operation = OP_SRAM_TO_SRAM;
        return true;
    case 5:
        ctx->core0.name = "D5 Core0 SRAM->PSRAM";
        ctx->core0.operation = OP_SRAM_TO_PSRAM;
        ctx->core1.name = "D5 Core1 SRAM->PSRAM";
        ctx->core1.operation = OP_SRAM_TO_PSRAM;
        return true;
    default:
        return false;
    }
}

static void print_worker_result(const worker_t *worker)
{
    ESP_LOGI(TAG, "%s (%s): copies=%" PRIu64 " bytes=%" PRIu64
             " elapsed=%" PRId64 " us bandwidth=%.2f MiB/s"
             " checksum=0x%08" PRIx32 " errors=%" PRIu32,
             worker->name, operation_name(worker->operation), worker->copies,
             worker->total_bytes, worker->elapsed_us,
             mib_per_second(worker->total_bytes, worker->elapsed_us),
             worker->checksum, worker->errors);
}

void app_main(void)
{
    test_context_t *ctx = calloc(1, sizeof(*ctx));
    if (ctx == NULL || !configure_scenario(ctx)) {
        ESP_LOGE(TAG, "invalid scenario=%d or bench partition missing",
                 CONFIG_SYS02D_SCENARIO);
        free(ctx);
        vTaskDelete(NULL);
        return;
    }
    ctx->events = xEventGroupCreate();
    if (ctx->events == NULL || !allocate_worker_buffers(&ctx->core0) ||
        !allocate_worker_buffers(&ctx->core1)) {
        ESP_LOGE(TAG, "buffer/event allocation failed; reduce buffer size or check PSRAM");
        free_worker_buffers(&ctx->core0);
        free_worker_buffers(&ctx->core1);
        if (ctx->events != NULL) vEventGroupDelete(ctx->events);
        free(ctx);
        vTaskDelete(NULL);
        return;
    }

    task_arg_t arg0 = {ctx, &ctx->core0};
    task_arg_t arg1 = {ctx, &ctx->core1};
    ESP_LOGI(TAG, "SYS-02D%d start: buffer=%d KiB duration=%d ms copies/check=%d",
             CONFIG_SYS02D_SCENARIO, CONFIG_SYS02D_BUFFER_KIB,
             CONFIG_SYS02D_DURATION_MS, CONFIG_SYS02D_COPIES_PER_TIME_CHECK);
    ESP_LOGI(TAG, "%s; %s", ctx->core0.name, ctx->core1.name);

    const BaseType_t task0_ok = xTaskCreatePinnedToCore(
        memory_worker_task, "mem_core0", 4096, &arg0, 5, NULL, 0);
    const BaseType_t task1_ok = xTaskCreatePinnedToCore(
        memory_worker_task, "mem_core1", 4096, &arg1, 5, NULL, 1);
    if (task0_ok != pdPASS || task1_ok != pdPASS) {
        ESP_LOGE(TAG, "worker task creation failed");
    } else {
        xEventGroupSetBits(ctx->events, GO_BIT);
        xEventGroupWaitBits(ctx->events, DONE_CORE0_BIT | DONE_CORE1_BIT,
                            pdFALSE, pdTRUE, pdMS_TO_TICKS(CONFIG_SYS02D_DURATION_MS + 1000));
        print_worker_result(&ctx->core0);
        print_worker_result(&ctx->core1);
        ESP_LOGI(TAG, "SYS-02D%d aggregate=%.2f MiB/s", CONFIG_SYS02D_SCENARIO,
                 mib_per_second(ctx->core0.total_bytes, ctx->core0.elapsed_us) +
                 mib_per_second(ctx->core1.total_bytes, ctx->core1.elapsed_us));
    }

    free_worker_buffers(&ctx->core0);
    free_worker_buffers(&ctx->core1);
    vEventGroupDelete(ctx->events);
    free(ctx);
    vTaskDelete(NULL);
}
