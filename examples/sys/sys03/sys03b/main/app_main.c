#include <stdint.h>
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gptimer.h"
#include "esp_attr.h"
#include "esp_log.h"
#include "esp_err.h"
#include "esp_timer.h"

static const char *TAG = "sys03b";
static TaskHandle_t s_task;
static volatile uint32_t s_isr_count;
/* With auto-reload enabled, edata->count_value is the alarm value (1000)
 * on every callback, so it cannot be used to measure the interval between
 * callbacks.  Use the monotonic microsecond timer instead. */
static volatile int64_t s_last_timestamp_us;
static volatile uint32_t s_period_min = UINT32_MAX, s_period_max;
static volatile uint64_t s_period_sum;
static volatile uint32_t s_period_count;
static volatile int s_isr_core = -1;
static portMUX_TYPE s_lock = portMUX_INITIALIZER_UNLOCKED;

static bool IRAM_ATTR on_alarm(gptimer_handle_t timer, const gptimer_alarm_event_data_t *edata, void *arg)
{
    (void)timer;
    (void)edata;
    int64_t now = esp_timer_get_time();
    portENTER_CRITICAL_ISR(&s_lock);
    if (s_isr_count) {
        uint32_t period = (uint32_t)(now - s_last_timestamp_us);
        if (period < s_period_min) s_period_min = period;
        if (period > s_period_max) s_period_max = period;
        s_period_sum += period;
        s_period_count++;
    }
    s_last_timestamp_us = now;
    s_isr_count++;
    s_isr_core = xPortGetCoreID();
    portEXIT_CRITICAL_ISR(&s_lock);
    BaseType_t hp = pdFALSE;
    vTaskNotifyGiveFromISR((TaskHandle_t)arg, &hp);
    return hp == pdTRUE;
}

static void report_task(void *arg)
{
    (void)arg;
    uint32_t last_count = 0;
    int64_t last_report_us = esp_timer_get_time();
    while (1) {
        /* The ISR notifies this task every millisecond.  Do not clear the
         * period accumulator on every notification; keep collecting until a
         * complete reporting interval has elapsed. */
        ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));
        const int64_t now_us = esp_timer_get_time();
        if (now_us - last_report_us >= 1000000) {
            uint32_t count, period_count, min_period, max_period, isr_core;
            uint64_t period_sum;
            portENTER_CRITICAL(&s_lock);
            count = s_isr_count;
            period_count = s_period_count;
            period_sum = s_period_sum;
            min_period = s_period_min;
            max_period = s_period_max;
            isr_core = (uint32_t)s_isr_core;
            s_period_count = 0;
            s_period_sum = 0;
            s_period_min = UINT32_MAX;
            s_period_max = 0;
            portEXIT_CRITICAL(&s_lock);

            const uint32_t delta = count - last_count;
            const double interval_s = (double)(now_us - last_report_us) / 1000000.0;
            ESP_LOGI(TAG, "ISR rate=%.2f Hz count=%lu period_avg=%.2f us min=%lu max=%lu jitter_pp=%lu us isr_core=%lu report_core=%d",
                     interval_s > 0.0 ? (double)delta / interval_s : 0.0,
                     (unsigned long)count,
                     period_count ? (double)period_sum / period_count : 0.0,
                     (unsigned long)(min_period == UINT32_MAX ? 0 : min_period),
                     (unsigned long)max_period,
                     (unsigned long)(max_period - (min_period == UINT32_MAX ? 0 : min_period)),
                     (unsigned long)isr_core, xPortGetCoreID());
            last_count = count;
            last_report_us = now_us;
        }
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "SYS-03B GPTimer interrupt start: 1 kHz");
    xTaskCreatePinnedToCore(report_task, "sys03b_report", 3072, NULL, 8, &s_task, 1);
    gptimer_handle_t timer; 
    gptimer_config_t cfg = {.clk_src=GPTIMER_CLK_SRC_DEFAULT, .direction=GPTIMER_COUNT_UP, .resolution_hz=1000000};
    ESP_ERROR_CHECK(gptimer_new_timer(&cfg, &timer));
    gptimer_event_callbacks_t cbs = {.on_alarm=on_alarm}; 
    ESP_ERROR_CHECK(gptimer_register_event_callbacks(timer, &cbs, s_task));
    gptimer_alarm_config_t alarm = {.reload_count=0, .alarm_count=1000, .flags.auto_reload_on_alarm=true};
    ESP_ERROR_CHECK(gptimer_set_alarm_action(timer, &alarm)); ESP_ERROR_CHECK(gptimer_enable(timer)); ESP_ERROR_CHECK(gptimer_start(timer));
}
