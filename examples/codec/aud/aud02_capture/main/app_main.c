#include <inttypes.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>

#include "bsp/esp32_s31_korvo_1.h"
#include "esp_codec_dev.h"
#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "sdkconfig.h"

static const char *TAG = "aud02";

void app_main(void)
{
    const size_t frames = CONFIG_AUD02_BLOCK_FRAMES;
    const size_t bytes = frames * 2 * sizeof(int16_t);
    int16_t *rx = heap_caps_malloc(bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    if (!rx) { 
        ESP_LOGE(TAG, "buffer allocation failed (%u B)", (unsigned)bytes); return; 
    }

    /*
     * Initialize the Korvo I2S bus with the internal APLL as the clock
     * source.  The BSP default on ESP32-S31 uses the XTAL source; that is
     * adequate for simple rates but does not provide the same fractional
     * divider accuracy as APLL.  The codec data interface stores this clock
     * source and reapplies it when esp_codec_dev_open() changes the sample
     * format, so this must happen before creating the microphone handle.
     */
    i2s_std_config_t i2s_cfg = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(CONFIG_AUD02_SAMPLE_RATE),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(
            I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = {
            .mclk = BSP_I2S_MCLK,
            .bclk = BSP_I2S_SCLK,
            .ws = BSP_I2S_LCLK,
            .dout = BSP_I2S_DOUT,
            .din = BSP_I2S_DSIN,
            .invert_flags = {
                .mclk_inv = false,
                .bclk_inv = false,
                .ws_inv = false,
            },
        },
    };
    i2s_cfg.clk_cfg.clk_src = I2S_CLK_SRC_APLL;
    i2s_cfg.clk_cfg.mclk_multiple = I2S_MCLK_MULTIPLE_384;

    ESP_ERROR_CHECK(bsp_i2c_init());
    ESP_ERROR_CHECK(bsp_audio_init(&i2s_cfg));

    esp_codec_dev_handle_t mic = bsp_audio_codec_microphone_init();
    if (!mic) { 
        ESP_LOGE(TAG, "microphone init failed"); return; 
    }

    ESP_ERROR_CHECK(esp_codec_dev_write_reg(mic, 0x22, 0x00));

    esp_codec_dev_sample_info_t cfg = {
        .sample_rate = CONFIG_AUD02_SAMPLE_RATE,
        .channel = 2, 
        .bits_per_sample = 16,
        .mclk_multiple = I2S_MCLK_MULTIPLE_384,
    };

    ESP_ERROR_CHECK(esp_codec_dev_set_in_gain(mic, (float)CONFIG_AUD02_MIC_GAIN_DB));
    ESP_ERROR_CHECK(esp_codec_dev_open(mic, &cfg));
    ESP_LOGI(TAG, "AUD-02: %d Hz, stereo, gain=%d dB, block=%u frames, %d s",
             CONFIG_AUD02_SAMPLE_RATE, CONFIG_AUD02_MIC_GAIN_DB, (unsigned)frames, CONFIG_AUD02_TEST_SECONDS);
    ESP_LOGI(TAG, "Clock: source=APLL, MCLK=%d Hz, BCLK about %d Hz, GPIO BCLK=%d WS=%d DIN=%d",
             CONFIG_AUD02_SAMPLE_RATE * I2S_MCLK_MULTIPLE_384,
             CONFIG_AUD02_SAMPLE_RATE * 32,
             BSP_I2S_SCLK, BSP_I2S_LCLK, BSP_I2S_DSIN);

    uint64_t captured = 0, blocks = 0, sum_sq[2] = {0, 0}, call_us = 0, max_us = 0;
    int32_t peak[2] = {0, 0}; uint32_t clip[2] = {0, 0}, read_err = 0;

    const int64_t start = esp_timer_get_time(), end = start + (int64_t)CONFIG_AUD02_TEST_SECONDS * 1000000LL;
    int64_t next_report = start + 1000000;

    while (esp_timer_get_time() < end) {
        const int64_t t0 = esp_timer_get_time();
        const int ret = esp_codec_dev_read(mic, rx, bytes);
        const uint64_t elapsed = (uint64_t)(esp_timer_get_time() - t0);
        call_us += elapsed; if (elapsed > max_us) max_us = elapsed; ++blocks;
        if (ret != ESP_CODEC_DEV_OK) { ++read_err; continue; }
        captured += frames;
        for (size_t i = 0; i < frames; ++i) for (int ch = 0; ch < 2; ++ch) {
            const int32_t v = rx[2 * i + ch], a = v < 0 ? -v : v;
            sum_sq[ch] += (uint64_t)((int64_t)v * v);
            if (a > peak[ch]) peak[ch] = a;
            if (a >= 32760) ++clip[ch];
        }
        const int64_t now = esp_timer_get_time();
        if (now >= next_report) {
            const double sec = (double)(now - start) / 1000000.0;
            ESP_LOGI(TAG, "PERF: rate=%.1fHz blocks=%" PRIu64 " read_err=%" PRIu32
                     " avg=%" PRIu64 "us max=%" PRIu64 "us rms=%.1f/%.1f peak=%" PRId32 "/%" PRId32 " clip=%" PRIu32 "/%" PRIu32,
                     captured / sec, blocks, read_err, blocks ? call_us / blocks : 0, max_us,
                     sqrt((double)sum_sq[0] / (double)(captured ? captured : 1)), sqrt((double)sum_sq[1] / (double)(captured ? captured : 1)),
                     peak[0], peak[1], clip[0], clip[1]);
            next_report += 1000000;
        }
    }
    ESP_LOGI(TAG, "AUD-02 complete: frames=%" PRIu64 " read_err=%" PRIu32 " free_int=%u free_psram=%u",
             captured, read_err, (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL), (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
    esp_codec_dev_close(mic); free(rx);
}
