#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>

#include "esp_err.h"
#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_partition.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "sys02c";
#define READ_TOTAL (1024U * 1024U)
#define BUFFER_BYTES (64U * 1024U)

static uint32_t checksum(const uint8_t *data, size_t bytes)
{
    uint32_t sum = 0;
    for (size_t i = 0; i < bytes; ++i) {
        sum = (sum << 5) - sum + data[i];
    }
    return sum;
}

static void run_block(const esp_partition_t *partition, size_t block_size)
{
    uint8_t *buffer = heap_caps_malloc(BUFFER_BYTES, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    if (buffer == NULL) {
        ESP_LOGE(TAG, "read buffer allocation failed");
        return;
    }
    const size_t total = partition->size < READ_TOTAL ? partition->size : READ_TOTAL;
    size_t offset = 0;
    uint64_t bytes = 0;
    uint32_t operations = 0;
    int64_t max_us = 0;
    uint32_t sum = 0;
    const int64_t start = esp_timer_get_time();
    while (offset < total) {
        const size_t n = (total - offset < block_size) ? total - offset : block_size;
        const int64_t op_start = esp_timer_get_time();
        const esp_err_t err = esp_partition_read(partition, offset, buffer, n);
        const int64_t op_us = esp_timer_get_time() - op_start;
        if (op_us > max_us) {
            max_us = op_us;
        }
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "read failed offset=%u size=%u: %s",
                     (unsigned)offset, (unsigned)n, esp_err_to_name(err));
            break;
        }
        sum ^= checksum(buffer, n);
        offset += n;
        bytes += n;
        ++operations;
    }
    const int64_t elapsed = esp_timer_get_time() - start;
    const double mib_per_s = (double)bytes * 1000000.0 /
                             ((double)elapsed * 1024.0 * 1024.0);
    ESP_LOGI(TAG, "block=%u bytes=%" PRIu64 " ops=%" PRIu32
             " elapsed=%" PRId64 " us bandwidth=%.2f MiB/s max_op=%" PRId64
             " us checksum=0x%08" PRIx32,
             (unsigned)block_size, bytes, operations, elapsed, mib_per_s, max_us, sum);
    free(buffer);
}

void app_main(void)
{
    const esp_partition_t *partition = esp_partition_find_first(
        ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_FACTORY, NULL);
    if (partition == NULL) {
        ESP_LOGE(TAG, "factory partition not found");
        vTaskDelete(NULL);
        return;
    }
    ESP_LOGI(TAG, "SYS-02C start: partition=%s size=%u read_total=%u",
             partition->label, (unsigned)partition->size, READ_TOTAL);
    const size_t blocks[] = {256, 1024, 4096, 16384, 65536};
    for (size_t i = 0; i < sizeof(blocks) / sizeof(blocks[0]); ++i) {
        run_block(partition, blocks[i]);
        vTaskDelay(pdMS_TO_TICKS(200));
    }
    ESP_LOGI(TAG, "SYS-02C complete (read-only)");
    vTaskDelete(NULL);
}
