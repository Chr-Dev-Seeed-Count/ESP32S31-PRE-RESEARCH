#include <inttypes.h>
#include <math.h>
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

static const char *TAG = "aud01";

static int16_t make_tone(uint32_t phase)
{
    return (int16_t)(sinf((float)phase * (float)(2.0 * M_PI / 4294967296.0)) * 1200.0f);
}

void app_main(void)
{
    const int rate = CONFIG_AUD01_SAMPLE_RATE;
    const size_t frames = CONFIG_AUD01_BLOCK_FRAMES;
    const size_t bytes = frames * 2 * sizeof(int16_t);
    int16_t *tx = heap_caps_malloc(bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    int16_t *rx = heap_caps_malloc(bytes, MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
    if (!tx || !rx) { ESP_LOGE(TAG, "buffer allocation failed (%u B)", (unsigned)bytes); return; }

    /*
     * ESP32-S31 maps I2S_CLK_SRC_DEFAULT to the 40 MHz XTAL.  That source
     * cannot generate the MCLK required by high sample rates (for example,
     * 96 kHz * 384 = 36.864 MHz).  Select APLL explicitly for this test.
     * The BSP must be initialized before creating the codec handles so the
     * codec data interface keeps the same clock source during reconfiguration.
     */
    i2s_std_config_t i2s_cfg = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(rate),
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

    esp_codec_dev_handle_t spk = bsp_audio_codec_speaker_init();
    esp_codec_dev_handle_t mic = bsp_audio_codec_microphone_init();
    if (!spk || !mic) { ESP_LOGE(TAG, "ES8389 init failed: spk=%p mic=%p", spk, mic); return; }
    esp_codec_dev_sample_info_t cfg = {
        .sample_rate = rate, .channel = 2, .bits_per_sample = 16,
        .mclk_multiple = I2S_MCLK_MULTIPLE_384,
    };
    ESP_ERROR_CHECK(esp_codec_dev_set_out_vol(spk, 18));
    ESP_ERROR_CHECK(esp_codec_dev_set_in_gain(mic, 16.0f));
    ESP_ERROR_CHECK(esp_codec_dev_open(spk, &cfg));
    ESP_ERROR_CHECK(esp_codec_dev_open(mic, &cfg));
    ESP_ERROR_CHECK(esp_codec_dev_set_out_mute(spk, false));
    ESP_LOGI(TAG, "AUD-01: %d Hz, 16 bit, stereo, block=%u frames, %d s", rate, (unsigned)frames, CONFIG_AUD01_TEST_SECONDS);
    ESP_LOGI(TAG, "Clock: source=APLL, MCLK=%d Hz; Scope: WS=%d Hz; expected BCLK about %d Hz; GPIO BCLK=3 WS=4 DOUT=5 DIN=6",
             rate * I2S_MCLK_MULTIPLE_384, rate, rate * 32);

    uint64_t tx_frames = 0, rx_frames = 0, sum_sq = 0, stat_samples = 0;
    uint64_t write_us = 0, read_us = 0, process_us = 0;
    uint32_t write_max_us = 0, read_max_us = 0;
    uint32_t write_err = 0, read_err = 0, peak = 0;
    uint32_t loop_count = 0;
    const int64_t start = esp_timer_get_time();
    const int64_t end = start + (int64_t)CONFIG_AUD01_TEST_SECONDS * 1000000LL;
    int64_t next_report = start + 1000000;

    /* Generate the test block once. Do not include sinf() cost in the I2S/DMA
     * throughput measurement; otherwise the signal generator becomes the
     * artificial bottleneck at high sample rates. */
    uint32_t phase = 0;
    const uint32_t step = (uint32_t)((1000.0 / rate) * 4294967296.0);
    for (size_t i = 0; i < frames; ++i) {
        int16_t s = make_tone(phase);
        phase += step;
        tx[2 * i] = s;
        tx[2 * i + 1] = s;
    }

    while (esp_timer_get_time() < end) {
        int64_t t0 = esp_timer_get_time();
        if (esp_codec_dev_write(spk, tx, bytes) != ESP_CODEC_DEV_OK) {
            ++write_err;
        } else {
            tx_frames += frames;
        }
        uint32_t call_us = (uint32_t)(esp_timer_get_time() - t0);
        write_us += call_us;
        if (call_us > write_max_us) write_max_us = call_us;
        t0 = esp_timer_get_time();
        if (esp_codec_dev_read(mic, rx, bytes) != ESP_CODEC_DEV_OK) {
            ++read_err;
        } else {
            int64_t process_start = esp_timer_get_time();
            /* Keep the benchmark focused on I2S/DMA.  Peak is checked for
             * every sample, while RMS uses one sample out of 16 and a
             * 32-bit scaled square.  The previous 64-bit square per sample
             * could consume the whole 10 ms block at 96 kHz. */
            for (size_t i = 0; i < frames * 2; ++i) {
                int32_t v = rx[i];
                uint32_t a = (uint32_t)(v < 0 ? -v : v);
                if (a > peak) peak = a;
                if ((i & 0x0F) == 0) {
                    int32_t q = v >> 4;
                    sum_sq += (uint64_t)((uint32_t)(q * q));
                    ++stat_samples;
                }
            }
            process_us += (uint64_t)(esp_timer_get_time() - process_start);
            rx_frames += frames;
        }
        call_us = (uint32_t)(esp_timer_get_time() - t0);
        read_us += call_us;
        if (call_us > read_max_us) read_max_us = call_us;
        const int64_t now = esp_timer_get_time();
        if (now >= next_report) {
            const double sec = (double)(now - start) / 1000000.0;
            const uint64_t tx_blocks = tx_frames / frames, rx_blocks = rx_frames / frames;
            const double block_us = (double)frames * 1000000.0 / rate;
            const double process_cpu = rx_blocks ? (double)process_us / (double)rx_blocks / block_us * 100.0 : 0.0;
            ESP_LOGI(TAG, "PERF: tx_rate=%.1f (%.1f KiB/s) rx_rate=%.1f (%.1f KiB/s) app_cpu=%.2f%%; "
                     "write_err=%" PRIu32 " read_err=%" PRIu32
                     " rx_rms=%.1f peak=%" PRIu32 " write_avg=%" PRIu64 "us max=%" PRIu32 "us"
                     " read_avg=%" PRIu64 "us max=%" PRIu32 "us",
                     tx_frames / sec, tx_frames * 4.0 / sec / 1024.0,
                     rx_frames / sec, rx_frames * 4.0 / sec / 1024.0, process_cpu, write_err, read_err,
                     stat_samples ? sqrt((double)sum_sq / (double)stat_samples) * 16.0 : 0.0, peak,
                     tx_blocks ? write_us / tx_blocks : 0, write_max_us,
                     rx_blocks ? read_us / rx_blocks : 0, read_max_us);
            next_report += 1000000;
        }
        /* taskYIELD() only switches to an equal-priority task.  Give IDLE0
         * an actual tick occasionally, without adding one tick to every
         * audio block and distorting the throughput measurement. */
        if ((++loop_count & 0x7F) == 0) {
            vTaskDelay(1);
        }
    }
    ESP_LOGI(TAG, "AUD-01 complete: tx=%" PRIu64 " rx=%" PRIu64 " write_err=%" PRIu32 " read_err=%" PRIu32,
             tx_frames, rx_frames, write_err, read_err);
    esp_codec_dev_set_out_mute(spk, true); esp_codec_dev_close(mic); esp_codec_dev_close(spk);
    free(tx); free(rx);
}
