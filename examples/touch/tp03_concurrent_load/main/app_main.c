#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "esp_codec_dev.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "nvs_flash.h"
#include "freertos/FreeRTOS.h"
#include "freertos/idf_additions.h"
#include "freertos/task.h"
#include "lvgl.h"

static const char *TAG = "tp03";

#ifndef CONFIG_TP03_STRESS_LEVEL
#define CONFIG_TP03_STRESS_LEVEL 50
#endif

#define TEST_DURATION_S       60
#define CPU_STRESS_WINDOW_US  20000
#define CPU_STRESS_MAX_BUSY_US (CPU_STRESS_WINDOW_US - 1000)
#define CPU_STRESS_TASK_PRIORITY 4
#define LATENCY_SAMPLES_MAX   256
#define UI_OBJECTS            24

static lv_indev_t *s_touch_indev;
static lv_display_t *s_display;
static lv_obj_t *s_touch_catcher;
static lv_obj_t *s_response_indicator;
static lv_indev_read_cb_t s_original_touch_read;

/* The board has no GT1151 INT line. This is the beginning of the I2C read
 * that first observes a new press, which is the earliest timestamp available. */
static int64_t s_pending_press_read_us;
static int64_t s_event_start_us[LATENCY_SAMPLES_MAX];
static uint32_t s_event_latency_us[LATENCY_SAMPLES_MAX];
static uint32_t s_frame_latency_us[LATENCY_SAMPLES_MAX];
static bool s_frame_pending[LATENCY_SAMPLES_MAX];
static uint16_t s_slot_cursor;
static bool s_indicator_state;
static volatile bool s_test_running = true;
static uint32_t s_idle_start[2];
static int64_t s_test_start_us;

static void measured_touch_read(lv_indev_t *indev, lv_indev_data_t *data)
{
    const int64_t read_start_us = esp_timer_get_time();
    const lv_indev_state_t previous_state = lv_indev_get_state(indev);

    if (s_original_touch_read) {
        s_original_touch_read(indev, data);
    }

    if (s_test_running && previous_state == LV_INDEV_STATE_RELEASED && data->state == LV_INDEV_STATE_PRESSED) {
        s_pending_press_read_us = read_start_us;
    }
}

static void touch_response_event_cb(lv_event_t *event)
{
    if (!s_test_running || lv_event_get_code(event) != LV_EVENT_PRESSED || s_pending_press_read_us == 0) {
        return;
    }

    const int64_t event_us = esp_timer_get_time();
    const uint16_t slot = s_slot_cursor;
    s_slot_cursor = (uint16_t)((s_slot_cursor + 1) % LATENCY_SAMPLES_MAX);
    s_event_start_us[slot] = s_pending_press_read_us;
    s_event_latency_us[slot] = (uint32_t)(event_us - s_pending_press_read_us);
    s_frame_pending[slot] = true;
    s_pending_press_read_us = 0;

    s_indicator_state = !s_indicator_state;
    lv_obj_set_style_bg_color(s_response_indicator,
                              s_indicator_state ? lv_palette_main(LV_PALETTE_GREEN)
                                                 : lv_palette_main(LV_PALETTE_RED),
                              LV_PART_MAIN);
}

static void display_ready_event_cb(lv_event_t *event)
{
    if (lv_event_get_code(event) != LV_EVENT_REFR_READY) {
        return;
    }

    const int64_t ready_us = esp_timer_get_time();
    for (size_t i = 0; i < LATENCY_SAMPLES_MAX; ++i) {
        if (s_frame_pending[i]) {
            s_frame_latency_us[i] = (uint32_t)(ready_us - s_event_start_us[i]);
            s_frame_pending[i] = false;
        }
    }
}

static void build_ui(void)
{
    if (!bsp_display_lock(1000)) {
        return;
    }

    lv_obj_t *screen = lv_screen_active();
    for (int i = 0; i < UI_OBJECTS; ++i) {
        lv_obj_t *box = lv_obj_create(screen);
        lv_obj_remove_style_all(box);
        lv_obj_set_style_bg_color(box, lv_palette_main(LV_PALETTE_BLUE), LV_PART_MAIN);
        lv_obj_set_style_bg_opa(box, LV_OPA_COVER, LV_PART_MAIN);
        lv_obj_set_style_radius(box, 0, LV_PART_MAIN);
        lv_obj_set_style_border_width(box, 0, LV_PART_MAIN);
        lv_obj_set_style_shadow_width(box, 0, LV_PART_MAIN);
        lv_obj_clear_flag(box, LV_OBJ_FLAG_SCROLLABLE);
        lv_obj_set_size(box, 50, 30);
        lv_obj_set_pos(box, (i * 73) % (BSP_LCD_H_RES - 50), 30 + (i * 29) % 400);
    }

    /* Full-screen transparent target: every press produces one LV_EVENT_PRESSED. */
    s_touch_catcher = lv_obj_create(screen);
    lv_obj_remove_style_all(s_touch_catcher);
    lv_obj_set_size(s_touch_catcher, BSP_LCD_H_RES, BSP_LCD_V_RES);
    lv_obj_set_pos(s_touch_catcher, 0, 0);
    lv_obj_clear_flag(s_touch_catcher, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_add_flag(s_touch_catcher, LV_OBJ_FLAG_CLICKABLE);
    lv_obj_add_event_cb(s_touch_catcher, touch_response_event_cb, LV_EVENT_PRESSED, NULL);

    s_response_indicator = lv_obj_create(screen);
    lv_obj_remove_style_all(s_response_indicator);
    lv_obj_set_size(s_response_indicator, 24, 24);
    lv_obj_set_pos(s_response_indicator, 4, 4);
    lv_obj_set_style_bg_color(s_response_indicator, lv_palette_main(LV_PALETTE_RED), LV_PART_MAIN);
    lv_obj_set_style_bg_opa(s_response_indicator, LV_OPA_COVER, LV_PART_MAIN);
    lv_obj_set_style_radius(s_response_indicator, 0, LV_PART_MAIN);
    lv_obj_set_style_border_width(s_response_indicator, 0, LV_PART_MAIN);
    lv_obj_set_style_shadow_width(s_response_indicator, 0, LV_PART_MAIN);
    lv_obj_clear_flag(s_response_indicator, LV_OBJ_FLAG_SCROLLABLE | LV_OBJ_FLAG_CLICKABLE);

    if (s_touch_indev) {
        s_original_touch_read = lv_indev_get_read_cb(s_touch_indev);
        lv_indev_set_read_cb(s_touch_indev, measured_touch_read);
        /* No GT1151 INT pin is routed on this board; poll input faster than the
         * display refresh timer without adding a second LVGL task or mutex user. */
        lv_timer_set_period(lv_indev_get_read_timer(s_touch_indev), 5);
    }
    bsp_display_unlock();
}

static void cpu_stress_task(void *arg)
{
    const uint32_t seed = (uint32_t)(uintptr_t)arg;
    const uint32_t level = (CONFIG_TP03_STRESS_LEVEL > 100) ? 100 : CONFIG_TP03_STRESS_LEVEL;

    /* Level is a CPU duty-cycle target. Keep a small idle slice at level 100
     * so both idle tasks continue to feed the task watchdog. */
    const int64_t busy_us = ((int64_t)CPU_STRESS_MAX_BUSY_US * level) / 100;
    if (busy_us == 0) {
        while (true) {
            vTaskDelay(pdMS_TO_TICKS(1000));
        }
    }

    volatile uint32_t state = 0x9e3779b9U ^ seed;
    while (true) {
        const int64_t window_start_us = esp_timer_get_time();
        const int64_t busy_until_us = window_start_us + busy_us;
        uint32_t iterations = 0;
        do {
            /* Volatile state prevents the compiler from removing the burn. */
            state = state * 1664525U + 1013904223U;
            if ((++iterations & 0xffU) == 0U && esp_timer_get_time() >= busy_until_us) {
                break;
            }
        } while (true);

        const int64_t elapsed_us = esp_timer_get_time() - window_start_us;
        const int64_t sleep_us = CPU_STRESS_WINDOW_US - elapsed_us;
        /* Always block for at least one tick. taskYIELD() alone can keep the
         * two same-priority stress tasks runnable and starve the idle task. */
        const uint32_t sleep_ms = sleep_us > 0 ? (uint32_t)((sleep_us + 999) / 1000) : 1U;
        vTaskDelay(pdMS_TO_TICKS(sleep_ms));
    }
}

static void audio_task(void *arg)
{
    (void)arg;
    esp_codec_dev_handle_t speaker = bsp_audio_codec_speaker_init();
    if (!speaker) {
        vTaskDelete(NULL);
        return;
    }
    esp_codec_dev_sample_info_t cfg = {
        .sample_rate = 48000,
        .channel = 2,
        .bits_per_sample = 16,
        .mclk_multiple = I2S_MCLK_MULTIPLE_384,
    };
    if (esp_codec_dev_open(speaker, &cfg) != ESP_CODEC_DEV_OK) {
        vTaskDelete(NULL);
        return;
    }

    int16_t pcm[480 * 2];
    float sample = 0.0f;
    float previous_sample = -0.057564027f;
    const float two_cos_omega = 1.9966837f;
    uint32_t generated_samples = 0;
    while (true) {
        for (int i = 0; i < 480; ++i) {
            const float next_sample = two_cos_omega * sample - previous_sample;
            previous_sample = sample;
            sample = next_sample;
            const int16_t value = (int16_t)(2000.0f * sample);
            pcm[2 * i] = value;
            pcm[2 * i + 1] = value;
            if (++generated_samples == 48000) {
                sample = 0.0f;
                previous_sample = -0.057564027f;
                generated_samples = 0;
            }
        }
        if (esp_codec_dev_write(speaker, pcm, sizeof(pcm)) != ESP_CODEC_DEV_OK) {
            vTaskDelay(pdMS_TO_TICKS(1));
        }
    }
}

static void system_load_init(void)
{
    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        return;
    }
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return;
    }
    err = esp_netif_init();
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return;
    }
    err = esp_event_loop_create_default();
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return;
    }
    wifi_init_config_t wifi_cfg = WIFI_INIT_CONFIG_DEFAULT();
    if (esp_wifi_init(&wifi_cfg) == ESP_OK) {
        esp_wifi_set_mode(WIFI_MODE_STA);
        esp_wifi_start();
    }
    (void)bsp_camera_start(NULL);
}

static int compare_u32(const void *lhs, const void *rhs)
{
    const uint32_t a = *(const uint32_t *)lhs;
    const uint32_t b = *(const uint32_t *)rhs;
    return (a > b) - (a < b);
}

static uint32_t percentile_us(const uint32_t *values, size_t count, uint32_t percentile)
{
    if (count == 0) {
        return 0;
    }
    uint32_t sorted[LATENCY_SAMPLES_MAX];
    memcpy(sorted, values, count * sizeof(sorted[0]));
    qsort(sorted, count, sizeof(sorted[0]), compare_u32);
    return sorted[((count - 1) * percentile) / 100];
}

static void report_task(void *arg)
{
    (void)arg;
    vTaskDelay(pdMS_TO_TICKS(TEST_DURATION_S * 1000));
    s_test_running = false;
    vTaskDelay(pdMS_TO_TICKS(50));

    uint32_t event_values[LATENCY_SAMPLES_MAX];
    uint32_t frame_values[LATENCY_SAMPLES_MAX];
    size_t count = 0;
    for (size_t i = 0; i < LATENCY_SAMPLES_MAX; ++i) {
        if (!s_frame_pending[i] && s_event_start_us[i] != 0 && count < LATENCY_SAMPLES_MAX) {
            event_values[count] = s_event_latency_us[i];
            frame_values[count++] = s_frame_latency_us[i];
        }
    }

    const uint32_t idle0_us = ulTaskGetIdleRunTimeCounterForCore(0) - s_idle_start[0];
    const uint32_t idle1_us = ulTaskGetIdleRunTimeCounterForCore(1) - s_idle_start[1];
    const uint64_t elapsed_us = (uint64_t)(esp_timer_get_time() - s_test_start_us);
    /* A 60 s interval multiplied by 100 does not fit in uint32_t. */
    const uint32_t cpu0_load = elapsed_us ?
                               100U - (uint32_t)(((uint64_t)idle0_us * 100U) / elapsed_us) : 0;
    const uint32_t cpu1_load = elapsed_us ?
                               100U - (uint32_t)(((uint64_t)idle1_us * 100U) / elapsed_us) : 0;
    ESP_LOGI(TAG,
             "RESULT stress=%d samples=%u read_to_event_us[p50=%u p95=%u p99=%u max=%u] "
             "read_to_frame_us[p50=%u p95=%u p99=%u max=%u] cpu_load[0=%u%% 1=%u%%]",
             CONFIG_TP03_STRESS_LEVEL, (unsigned)count,
             percentile_us(event_values, count, 50), percentile_us(event_values, count, 95),
             percentile_us(event_values, count, 99), percentile_us(event_values, count, 100),
             percentile_us(frame_values, count, 50), percentile_us(frame_values, count, 95),
             percentile_us(frame_values, count, 99), percentile_us(frame_values, count, 100),
             (unsigned)cpu0_load, (unsigned)cpu1_load);
    vTaskDelete(NULL);
}

static lv_display_t *start_display(void)
{
    bsp_display_cfg_t cfg = {
        .lvgl_port_cfg = ESP_LVGL_PORT_INIT_CONFIG(),
        .buffer_size = BSP_LCD_H_RES * CONFIG_BSP_LCD_DRAW_BUF_HEIGHT,
#if CONFIG_BSP_LCD_DRAW_BUF_DOUBLE
        .double_buffer = true,
#else
        .double_buffer = false,
#endif
        .flags = {
            .buff_dma = true,
            .buff_spiram = false,
            .sw_rotate = false,
        },
    };
    cfg.lvgl_port_cfg.task_affinity = 1;
    return bsp_display_start_with_config(&cfg);
}

void app_main(void)
{
    esp_log_level_set("*", ESP_LOG_ERROR);
    esp_log_level_set(TAG, ESP_LOG_INFO);

    s_display = start_display();
    if (!s_display) {
        return;
    }
    s_touch_indev = bsp_display_get_input_dev();

    if (bsp_display_lock(1000)) {
        lv_display_add_event_cb(s_display, display_ready_event_cb, LV_EVENT_REFR_READY, NULL);
        bsp_display_unlock();
    }
    build_ui();

    system_load_init();
    s_test_start_us = esp_timer_get_time();
    s_idle_start[0] = ulTaskGetIdleRunTimeCounterForCore(0);
    s_idle_start[1] = ulTaskGetIdleRunTimeCounterForCore(1);
    /* Stress both CPUs at the same priority as LVGL so the load also exercises
     * scheduler contention. Each task still blocks at least once per window. */
    xTaskCreatePinnedToCore(cpu_stress_task, "tp03_stress0", 4096,
                            (void *)(uintptr_t)0x1234U, CPU_STRESS_TASK_PRIORITY, NULL, 0);
    xTaskCreatePinnedToCore(cpu_stress_task, "tp03_stress1", 4096,
                            (void *)(uintptr_t)0x5678U, CPU_STRESS_TASK_PRIORITY, NULL, 1);
    xTaskCreatePinnedToCore(audio_task, "tp03_audio", 4096, NULL, 4, NULL, 0);
    xTaskCreatePinnedToCore(report_task, "tp03_report", 4096, NULL, 1, NULL, 0);
}
