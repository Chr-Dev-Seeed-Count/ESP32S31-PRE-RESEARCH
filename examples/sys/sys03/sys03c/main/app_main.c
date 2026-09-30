#include <stdint.h>
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "esp_timer.h"
#include "esp_log.h"

typedef struct {
    uint32_t seq;
    int64_t sent_us;
} ipc_msg_t;

static const char *TAG = "sys03c";
static QueueHandle_t s_queue;

#ifndef CONFIG_SYS03C_TX_PERIOD_US
#define CONFIG_SYS03C_TX_PERIOD_US 1000
#endif
#ifndef CONFIG_SYS03C_QUEUE_LENGTH
#define CONFIG_SYS03C_QUEUE_LENGTH 64
#endif

static const uint32_t s_tx_period_us = CONFIG_SYS03C_TX_PERIOD_US;

static void tx_task(void *arg)
{
    (void)arg;
    ESP_LOGI(TAG, "TX task started on core=%d", xPortGetCoreID());
    uint32_t seq = 0;
    uint32_t attempts = 0;
    uint32_t sent = 0;
    uint32_t lost = 0;
    uint32_t queue_max = 0;
    int64_t report_start = esp_timer_get_time();
    int64_t next_send = report_start;

    while (1) {
        int64_t now = esp_timer_get_time();
        if (now < next_send) {
            int64_t wait_us = next_send - now;
            /* Sleep only when the remaining delay is at least two OS ticks.
             * On this target the tick is commonly 10 ms, so sleeping for one
             * tick during a 1 ms test would distort the requested rate. */
            const int64_t tick_us = (int64_t)portTICK_PERIOD_MS * 1000;
            if (wait_us >= 2 * tick_us) {
                TickType_t ticks = pdMS_TO_TICKS((wait_us - tick_us) / 1000);
                if (ticks > 0) vTaskDelay(ticks);
                else taskYIELD();
            } else {
                taskYIELD();
            }
            continue;
        }

        ipc_msg_t message = {.seq = seq++, .sent_us = now};
        attempts++;
        if (xQueueSend(s_queue, &message, 0) == pdTRUE) {
            sent++;
        } else {
            lost++;
        }
        uint32_t depth = (uint32_t)uxQueueMessagesWaiting(s_queue);
        if (depth > queue_max) queue_max = depth;

        if (s_tx_period_us == 0) {
            next_send = esp_timer_get_time();
            taskYIELD();
        } else {
            next_send += s_tx_period_us;
            if (next_send < now - (int64_t)s_tx_period_us) {
                next_send = now + s_tx_period_us;
            }
        }

        int64_t report_now = esp_timer_get_time();
        if (report_now - report_start >= 5000000) {
            ESP_LOGI(TAG,
                     "TX core=%d period=%lu us attempts=%lu sent=%lu drop=%lu "
                     "drop_rate=%.3f%% rate=%.1f msg/s queue_max=%lu",
                     xPortGetCoreID(), (unsigned long)s_tx_period_us,
                     (unsigned long)attempts, (unsigned long)sent,
                     (unsigned long)lost,
                     attempts ? 100.0 * (double)lost / attempts : 0.0,
                     (double)sent / 5.0, (unsigned long)queue_max);
            attempts = sent = lost = queue_max = 0;
            report_start = report_now;
        }
    }
}

static void rx_task(void *arg)
{
    (void)arg;
    ESP_LOGI(TAG, "RX task started on core=%d", xPortGetCoreID());
    ipc_msg_t message;
    uint32_t received = 0;
    uint32_t gaps = 0;
    uint32_t queue_max = 0;
    uint64_t latency_sum = 0;
    uint32_t latency_max = 0;
    uint32_t previous_seq = 0;
    bool have_previous = false;
    int64_t report_start = esp_timer_get_time();

    while (1) {
        if (xQueueReceive(s_queue, &message, portMAX_DELAY) != pdTRUE) {
            continue;
        }
        uint32_t latency_us = (uint32_t)(esp_timer_get_time() - message.sent_us);
        latency_sum += latency_us;
        if (latency_us > latency_max) latency_max = latency_us;
        if (have_previous && message.seq > previous_seq + 1) {
            gaps += message.seq - previous_seq - 1;
        }
        previous_seq = message.seq;
        have_previous = true;
        received++;
        uint32_t depth = (uint32_t)uxQueueMessagesWaiting(s_queue);
        if (depth > queue_max) queue_max = depth;

        int64_t now = esp_timer_get_time();
        if (now - report_start >= 5000000) {
            ESP_LOGI(TAG,
                     "RX core=%d period=%lu us msgs=%lu gaps=%lu "
                     "latency_avg=%.2f us max=%lu throughput=%.1f msg/s queue_max=%lu",
                     xPortGetCoreID(), (unsigned long)s_tx_period_us,
                     (unsigned long)received, (unsigned long)gaps,
                     received ? (double)latency_sum / received : 0.0,
                     (unsigned long)latency_max, (double)received / 5.0,
                     (unsigned long)queue_max);
            received = gaps = queue_max = 0;
            latency_sum = 0;
            latency_max = 0;
            report_start = now;
        }
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "SYS-03C queue IPC start: tx_period=%lu us queue_length=%d",
             (unsigned long)s_tx_period_us, CONFIG_SYS03C_QUEUE_LENGTH);
    s_queue = xQueueCreate(CONFIG_SYS03C_QUEUE_LENGTH, sizeof(ipc_msg_t));
    configASSERT(s_queue);
    /* The TX task has a higher priority and is pinned to the app_main core.
     * Suspend scheduling while both tasks are created; otherwise TX can run
     * immediately after xTaskCreatePinnedToCore() and preempt app_main before
     * RX is created, leaving a permanently full queue. */
    vTaskSuspendAll();
    BaseType_t rx_result = xTaskCreatePinnedToCore(rx_task, "sys03c_rx", 3072, NULL, 7, NULL, 1);
    BaseType_t tx_result = xTaskCreatePinnedToCore(tx_task, "sys03c_tx", 3072, NULL, 6, NULL, 0);
    xTaskResumeAll();
    ESP_LOGI(TAG, "task create: tx=%s rx=%s",
             tx_result == pdPASS ? "ok" : "failed",
             rx_result == pdPASS ? "ok" : "failed");
}
