#include <stdint.h>
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "driver/gptimer.h"
#include "esp_task_wdt.h"
#include "esp_timer.h"
#include "esp_system.h"
#include "esp_log.h"

static const char *TAG="sys03f";
static QueueHandle_t q; static TaskHandle_t report_handle; static volatile uint32_t isr_count;

static bool IRAM_ATTR timer_cb(gptimer_handle_t timer, const gptimer_alarm_event_data_t *edata, void *arg)
{
    (void)timer;
    (void)edata;
    isr_count++;
    BaseType_t hp = pdFALSE;
    vTaskNotifyGiveFromISR((TaskHandle_t)arg, &hp);
    return hp == pdTRUE;
}
static void cpu_task(void *arg)
{
    int core=(int)(intptr_t)arg; esp_task_wdt_add(NULL); uint32_t n=0; int64_t t0=esp_timer_get_time();
    while(1){ volatile uint32_t x=core+1; for(int i=0;i<90000;i++) x=x*1664525u+1013904223u; (void)x; esp_task_wdt_reset(); n++; if(esp_timer_get_time()-t0>=5000000){ ESP_LOGI(TAG,"compute core=%d loops=%lu stack_free=%u",xPortGetCoreID(),(unsigned long)n,(unsigned)uxTaskGetStackHighWaterMark(NULL)); n=0;t0=esp_timer_get_time(); } vTaskDelay(1); }
}
static void ipc_rx(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL); uint32_t n=0; int64_t t0=esp_timer_get_time(); uint32_t value;
    while(1){ if(xQueueReceive(q,&value,pdMS_TO_TICKS(100))==pdTRUE){n++;} esp_task_wdt_reset(); if(esp_timer_get_time()-t0>=5000000){ESP_LOGI(TAG,"IPC core=%d msgs=%lu queue=%u",xPortGetCoreID(),(unsigned long)n,(unsigned)uxQueueMessagesWaiting(q)); n=0;t0=esp_timer_get_time();} }
}
static void ipc_tx(void *arg){(void)arg;uint32_t v=0;while(1){xQueueSend(q,&v,0);v++;vTaskDelay(1);}}
static void report(void *arg)
{
    (void)arg;
    uint32_t last_count = 0;
    int64_t last_report = esp_timer_get_time();
    while (1) {
        /* Accumulate timer notifications and report once per second.  Logging
         * from every 1 kHz interrupt would itself dominate the measurement. */
        ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(1000));
        int64_t now = esp_timer_get_time();
        if (now - last_report >= 1000000) {
            uint32_t count = isr_count;
            uint32_t delta = count - last_count;
            ESP_LOGI(TAG, "ISR rate=%lu Hz total=%lu report_core=%d",
                     (unsigned long)delta, (unsigned long)count,
                     xPortGetCoreID());
            last_count = count;
            last_report = now;
        }
    }
}
void app_main(void)
{
    ESP_LOGI(TAG,"SYS-03F combined stress start reset_reason=%d",esp_reset_reason());
    esp_task_wdt_config_t cfg={.timeout_ms=3000,.idle_core_mask=0,.trigger_panic=true}; esp_err_t e=esp_task_wdt_init(&cfg); if(e==ESP_ERR_INVALID_STATE)e=esp_task_wdt_reconfigure(&cfg); ESP_ERROR_CHECK(e);
    q=xQueueCreate(64,sizeof(uint32_t)); configASSERT(q);
    xTaskCreatePinnedToCore(cpu_task,"sys03f_c0",4096,(void*)0,5,NULL,0); xTaskCreatePinnedToCore(cpu_task,"sys03f_c1",4096,(void*)1,5,NULL,1); xTaskCreatePinnedToCore(ipc_tx,"sys03f_tx",3072,NULL,6,NULL,0); xTaskCreatePinnedToCore(ipc_rx,"sys03f_rx",3072,NULL,7,NULL,1); xTaskCreatePinnedToCore(report,"sys03f_report",3072,NULL,8,&report_handle,1);
    gptimer_handle_t timer; gptimer_config_t tc={.clk_src=GPTIMER_CLK_SRC_DEFAULT,.direction=GPTIMER_COUNT_UP,.resolution_hz=1000000}; ESP_ERROR_CHECK(gptimer_new_timer(&tc,&timer)); gptimer_event_callbacks_t cb={.on_alarm=timer_cb}; ESP_ERROR_CHECK(gptimer_register_event_callbacks(timer,&cb,report_handle)); gptimer_alarm_config_t ac={.reload_count=0,.alarm_count=1000,.flags.auto_reload_on_alarm=true}; ESP_ERROR_CHECK(gptimer_set_alarm_action(timer,&ac)); ESP_ERROR_CHECK(gptimer_enable(timer)); ESP_ERROR_CHECK(gptimer_start(timer));
}
