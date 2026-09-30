#include <inttypes.h>

#include "esp_chip_info.h"
#include "esp_err.h"
#include "esp_flash.h"
#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_partition.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "sys02a";

static void print_heap(const char *name, uint32_t caps)
{
    ESP_LOGI(TAG, "%s: total=%u free=%u largest=%u", name,
             (unsigned)heap_caps_get_total_size(caps),
             (unsigned)heap_caps_get_free_size(caps),
             (unsigned)heap_caps_get_largest_free_block(caps));
}

static void print_partition(const char *name, esp_partition_type_t type,
                            esp_partition_subtype_t subtype)
{
    const esp_partition_t *p = esp_partition_find_first(type, subtype, name);
    if (p == NULL) {
        ESP_LOGW(TAG, "partition '%s' not found", name);
        return;
    }
    ESP_LOGI(TAG, "partition %s: offset=0x%" PRIx32 " size=%" PRIu32,
             name, p->address, p->size);
}

static void print_snapshot(void)
{
    uint32_t flash_size = 0;
    esp_err_t err = esp_flash_get_size(NULL, &flash_size);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "Flash total=%" PRIu32 " bytes (%.2f MiB)",
                 flash_size, (double)flash_size / 1024.0 / 1024.0);
    } else {
        ESP_LOGE(TAG, "Flash size read failed: %s", esp_err_to_name(err));
    }

    print_partition("factory", ESP_PARTITION_TYPE_APP,
                    ESP_PARTITION_SUBTYPE_APP_FACTORY);
    print_partition("bench", ESP_PARTITION_TYPE_DATA,
                    ESP_PARTITION_SUBTYPE_DATA_SPIFFS);
    print_heap("Internal RAM", MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    print_heap("PSRAM", MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
}

void app_main(void)
{
    esp_chip_info_t chip = {0};
    esp_chip_info(&chip);
    ESP_LOGI(TAG, "SYS-02A start: cores=%d revision=%d features=0x%" PRIx32,
             chip.cores, chip.revision, (uint32_t)chip.features);

    while (true) {
        print_snapshot();
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}
