#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "esp_codec_dev.h"
#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sdkconfig.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static const char *TAG = "aud04";

typedef struct {
    esp_codec_dev_handle_t mic;
    esp_codec_dev_handle_t spk;
    int16_t *rx;
    int16_t *tx;
    size_t frames;
    size_t bytes;
    uint32_t phase;
    uint32_t phase_step;
    volatile bool stop;
    volatile uint64_t rx_frames;
    volatile uint64_t tx_frames;
    volatile uint32_t rx_err;
    volatile uint32_t tx_err;
    volatile uint64_t rx_sq[2];
} duplex_ctx_t;

static int16_t tone(uint32_t phase)
{
    return (int16_t)(sinf((float)phase * (float)(2.0 * M_PI / 4294967296.0)) * 5000.0f);
}

static void tx_task(void *arg)
{
    duplex_ctx_t *c = arg;
    while (!c->stop) {
        for (size_t i = 0; i < c->frames; ++i) {
            const int16_t s = tone(c->phase);
            c->phase += c->phase_step;
            c->tx[2 * i] = s;
            c->tx[2 * i + 1] = s;
        }
        if (esp_codec_dev_write(c->spk, c->tx, (int)c->bytes) != ESP_CODEC_DEV_OK) c->tx_err++;
        else c->tx_frames += c->frames;
    }
    vTaskDelete(NULL);
}

static void rx_task(void *arg)
{
    duplex_ctx_t *c = arg;
    while (!c->stop) {
        if (esp_codec_dev_read(c->mic, c->rx, (int)c->bytes) != ESP_CODEC_DEV_OK) {
            c->rx_err++;
            continue;
        }
        for (size_t i = 0; i < c->frames; ++i) {
            for (int ch = 0; ch < 2; ++ch) {
                const int32_t v = c->rx[2 * i + ch];
                c->rx_sq[ch] += (uint64_t)((int64_t)v * v);
            }
        }
        c->rx_frames += c->frames;
    }
    vTaskDelete(NULL);
}

void app_main(void)
{
    duplex_ctx_t c = {0};
    c.frames = CONFIG_AUD04_BLOCK_FRAMES;
    c.bytes = c.frames * 2 * sizeof(int16_t);
    c.phase_step = (uint32_t)((1000.0 / (double)CONFIG_AUD04_SAMPLE_RATE) * 4294967296.0);
    c.rx = heap_caps_malloc(c.bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    c.tx = heap_caps_malloc(c.bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    if (!c.rx || !c.tx) {
        ESP_LOGE(TAG, "buffer allocation failed (%u bytes each)", (unsigned)c.bytes);
        free(c.rx); free(c.tx);
        return;
    }
    c.mic = bsp_audio_codec_microphone_init();
    c.spk = bsp_audio_codec_speaker_init();
    if (!c.mic || !c.spk) {
        ESP_LOGE(TAG, "codec init failed: mic=%p spk=%p", c.mic, c.spk);
        free(c.rx); free(c.tx);
        return;
    }
    esp_codec_dev_sample_info_t cfg = {
        .sample_rate = CONFIG_AUD04_SAMPLE_RATE,
        .channel = 2,
        .bits_per_sample = 16,
        .mclk_multiple = I2S_MCLK_MULTIPLE_384,
    };
    ESP_ERROR_CHECK(esp_codec_dev_set_out_vol(c.spk, CONFIG_AUD04_VOLUME));
    ESP_ERROR_CHECK(esp_codec_dev_set_in_gain(c.mic, 20.0f));
    ESP_ERROR_CHECK(esp_codec_dev_open(c.spk, &cfg));
    ESP_ERROR_CHECK(esp_codec_dev_open(c.mic, &cfg));
    ESP_ERROR_CHECK(esp_codec_dev_set_out_mute(c.spk, false));

    ESP_LOGI(TAG, "AUD-04 start: %d Hz / 16 bit / stereo / block=%u / %d s; TX core0 RX core1",
             CONFIG_AUD04_SAMPLE_RATE, (unsigned)c.frames, CONFIG_AUD04_TEST_SECONDS);
    xTaskCreatePinnedToCore(tx_task, "aud04_tx", 4096, &c, 6, NULL, 0);
    xTaskCreatePinnedToCore(rx_task, "aud04_rx", 4096, &c, 6, NULL, 1);

    const int64_t start = esp_timer_get_time();
    const int64_t end = start + (int64_t)CONFIG_AUD04_TEST_SECONDS * 1000000LL;
    int64_t next_report = start + 1000000LL;
    while (esp_timer_get_time() < end) {
        vTaskDelay(pdMS_TO_TICKS(20));
        const int64_t now = esp_timer_get_time();
        if (now >= next_report) {
            const double sec = (double)(now - start) / 1000000.0;
            ESP_LOGI(TAG, "PERF: tx_rate=%.1f rx_rate=%.1f tx_err=%" PRIu32 " rx_err=%" PRIu32
                     " rms=%.1f/%.1f", c.tx_frames / sec, c.rx_frames / sec, c.tx_err, c.rx_err,
                     sqrt((double)c.rx_sq[0] / (double)(c.rx_frames ? c.rx_frames : 1)),
                     sqrt((double)c.rx_sq[1] / (double)(c.rx_frames ? c.rx_frames : 1)));
            ESP_LOGI(TAG, "heap: internal_free=%u internal_largest=%u psram_free=%u",
                     (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL),
                     (unsigned)heap_caps_get_largest_free_block(MALLOC_CAP_INTERNAL),
                     (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
            next_report += 1000000LL;
        }
    }

    c.stop = true;
    vTaskDelay(pdMS_TO_TICKS(100));
    ESP_LOGI(TAG, "AUD-04 complete: tx_frames=%" PRIu64 " rx_frames=%" PRIu64
             " tx_err=%" PRIu32 " rx_err=%" PRIu32, c.tx_frames, c.rx_frames, c.tx_err, c.rx_err);
    esp_codec_dev_set_out_mute(c.spk, true);
    esp_codec_dev_close(c.mic);
    esp_codec_dev_close(c.spk);
    free(c.rx); free(c.tx);
}
