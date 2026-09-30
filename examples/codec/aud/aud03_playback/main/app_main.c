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

static const char *TAG = "aud03";

static int16_t tone(uint32_t phase)
{
    return (int16_t)(sinf((float)phase * (float)(2.0 * M_PI / 4294967296.0)) * 6000.0f);
}

void app_main(void)
{
    const size_t frames = CONFIG_AUD03_BLOCK_FRAMES;
    const size_t samples = frames * 2;
    const size_t bytes = samples * sizeof(int16_t);
    int16_t *tx = heap_caps_malloc(bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    if (!tx) {
        ESP_LOGE(TAG, "buffer allocation failed (%u bytes)", (unsigned)bytes);
        return;
    }

    esp_codec_dev_handle_t spk = bsp_audio_codec_speaker_init();
    if (!spk) {
        ESP_LOGE(TAG, "speaker codec init failed");
        free(tx);
        return;
    }
    esp_codec_dev_sample_info_t cfg = {
        .sample_rate = CONFIG_AUD03_SAMPLE_RATE,
        .channel = 2,
        .bits_per_sample = 16,
        .mclk_multiple = I2S_MCLK_MULTIPLE_384,
    };
    ESP_ERROR_CHECK(esp_codec_dev_set_out_vol(spk, CONFIG_AUD03_VOLUME));
    ESP_ERROR_CHECK(esp_codec_dev_open(spk, &cfg));
    ESP_ERROR_CHECK(esp_codec_dev_set_out_mute(spk, false));

    ESP_LOGI(TAG, "AUD-03 start: %d Hz / 16 bit / stereo / volume=%d / block=%u / %d s",
             CONFIG_AUD03_SAMPLE_RATE, CONFIG_AUD03_VOLUME, (unsigned)frames,
             CONFIG_AUD03_TEST_SECONDS);

    uint32_t phase = 0;
    const uint32_t step = (uint32_t)((1000.0 / (double)CONFIG_AUD03_SAMPLE_RATE) * 4294967296.0);
    uint64_t written_frames = 0, write_us = 0, write_max = 0;
    uint32_t write_err = 0;
    const int64_t start = esp_timer_get_time();
    const int64_t end = start + (int64_t)CONFIG_AUD03_TEST_SECONDS * 1000000LL;
    int64_t next_report = start + 1000000LL;

    while (esp_timer_get_time() < end) {
        for (size_t i = 0; i < frames; ++i) {
            const int16_t s = tone(phase);
            phase += step;
            tx[2 * i] = s;
            tx[2 * i + 1] = s;
        }
        const int64_t t0 = esp_timer_get_time();
        const int ret = esp_codec_dev_write(spk, tx, (int)bytes);
        const uint64_t elapsed = (uint64_t)(esp_timer_get_time() - t0);
        write_us += elapsed;
        if (elapsed > write_max) write_max = elapsed;
        if (ret != ESP_CODEC_DEV_OK) write_err++;
        else written_frames += frames;

        const int64_t now = esp_timer_get_time();
        if (now >= next_report) {
            const double sec = (double)(now - start) / 1000000.0;
            ESP_LOGI(TAG, "PERF: rate=%.1f Hz write_err=%" PRIu32
                     " write_avg=%" PRIu64 " us write_max=%" PRIu64 " us",
                     written_frames / sec, write_err,
                     written_frames ? write_us / (written_frames / frames) : 0,
                     write_max);
            ESP_LOGI(TAG, "heap: internal_free=%u internal_largest=%u psram_free=%u",
                     (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL),
                     (unsigned)heap_caps_get_largest_free_block(MALLOC_CAP_INTERNAL),
                     (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
            next_report += 1000000LL;
        }
    }

    ESP_LOGI(TAG, "AUD-03 complete: frames=%" PRIu64 " write_err=%" PRIu32,
             written_frames, write_err);
    esp_codec_dev_set_out_mute(spk, true);
    esp_codec_dev_close(spk);
    free(tx);
}
