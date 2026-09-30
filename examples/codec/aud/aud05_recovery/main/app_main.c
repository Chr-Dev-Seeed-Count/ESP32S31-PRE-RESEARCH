#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "esp_codec_dev.h"
#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "sdkconfig.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static const char *TAG = "aud05";

static int16_t tone(uint32_t phase)
{
    return (int16_t)(sinf((float)phase * (float)(2.0 * M_PI / 4294967296.0)) * 3000.0f);
}

static esp_codec_dev_sample_info_t sample_cfg(int rate)
{
    return (esp_codec_dev_sample_info_t){
        .sample_rate = rate,
        .channel = 2,
        .bits_per_sample = 16,
        .mclk_multiple = I2S_MCLK_MULTIPLE_384,
    };
}

void app_main(void)
{
    const size_t frames = CONFIG_AUD05_BLOCK_FRAMES;
    const size_t bytes = frames * 2 * sizeof(int16_t);
    int16_t *tx = heap_caps_malloc(bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    int16_t *rx = heap_caps_malloc(bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    if (!tx || !rx) {
        ESP_LOGE(TAG, "buffer allocation failed (%u bytes each)", (unsigned)bytes);
        free(tx); free(rx);
        return;
    }
    esp_codec_dev_handle_t mic = bsp_audio_codec_microphone_init();
    esp_codec_dev_handle_t spk = bsp_audio_codec_speaker_init();
    if (!mic || !spk) {
        ESP_LOGE(TAG, "codec init failed: mic=%p spk=%p", mic, spk);
        free(tx); free(rx);
        return;
    }

    ESP_LOGI(TAG, "AUD-05 start: %d cycles, rates=%d/%d Hz, %d s/rate, block=%u",
             CONFIG_AUD05_RECOVERY_CYCLES, CONFIG_AUD05_SAMPLE_RATE, CONFIG_AUD05_ALT_RATE,
             CONFIG_AUD05_TEST_SECONDS, (unsigned)frames);
    uint32_t read_err = 0, write_err = 0, open_err = 0, recovered = 0;
    uint64_t frames_ok = 0;

    for (int cycle = 0; cycle < CONFIG_AUD05_RECOVERY_CYCLES; ++cycle) {
        const int rate = (cycle & 1) ? CONFIG_AUD05_ALT_RATE : CONFIG_AUD05_SAMPLE_RATE;
        const int64_t t0 = esp_timer_get_time();
        esp_codec_dev_sample_info_t cfg = sample_cfg(rate);
        int ret = esp_codec_dev_open(spk, &cfg);
        if (ret != ESP_CODEC_DEV_OK) {
            ESP_LOGE(TAG, "cycle=%d rate=%d speaker open failed=%d", cycle + 1, rate, ret);
            open_err++;
            continue;
        }
        ret = esp_codec_dev_open(mic, &cfg);
        if (ret != ESP_CODEC_DEV_OK) {
            ESP_LOGE(TAG, "cycle=%d rate=%d microphone open failed=%d", cycle + 1, rate, ret);
            open_err++;
            esp_codec_dev_close(spk);
            continue;
        }
        esp_codec_dev_set_out_vol(spk, CONFIG_AUD05_VOLUME);
        esp_codec_dev_set_out_mute(spk, false);
        uint32_t phase = 0;
        const uint32_t step = (uint32_t)((1000.0 / (double)rate) * 4294967296.0);
        const int64_t end = esp_timer_get_time() + (int64_t)CONFIG_AUD05_TEST_SECONDS * 1000000LL;
        uint64_t cycle_frames = 0;
        while (esp_timer_get_time() < end) {
            for (size_t i = 0; i < frames; ++i) {
                const int16_t s = tone(phase);
                phase += step;
                tx[2 * i] = s;
                tx[2 * i + 1] = s;
            }
            if (esp_codec_dev_write(spk, tx, (int)bytes) != ESP_CODEC_DEV_OK) write_err++;
            if (esp_codec_dev_read(mic, rx, (int)bytes) != ESP_CODEC_DEV_OK) read_err++;
            else { frames_ok += frames; cycle_frames += frames; }
        }
        esp_codec_dev_set_out_mute(spk, true);
        esp_codec_dev_close(mic);
        esp_codec_dev_close(spk);
        recovered++;
        ESP_LOGI(TAG, "cycle=%d rate=%d frames=%" PRIu64 " close/reopen_time=%" PRIu64
                 " us read_err=%" PRIu32 " write_err=%" PRIu32,
                 cycle + 1, rate, cycle_frames,
                 (uint64_t)(esp_timer_get_time() - t0), read_err, write_err);
    }

    ESP_LOGI(TAG, "AUD-05 complete: recovered=%" PRIu32 "/%d open_err=%" PRIu32
             " frames=%" PRIu64 " read_err=%" PRIu32 " write_err=%" PRIu32,
             recovered, CONFIG_AUD05_RECOVERY_CYCLES, open_err, frames_ok, read_err, write_err);
    free(tx); free(rx);
}
