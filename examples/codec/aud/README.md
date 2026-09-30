# ESP32-S31 Korvo-1 阶段 2：I2S / ES8389 Codec 测试

## 用例

| 用例 | 内容 | 主要输出 |
|---|---|---|
| `aud01_clock` | AUD-01 基本 TX/RX 与时钟基线 | 实际收发速率、读写错误、PCM RMS/Peak、调用平均时间 |
| `aud02_capture` | AUD-02 双麦连续采集 | 双通道 RMS、削顶、读取错误、读取最大耗时、缓冲影响 |
| `aud03_playback` | AUD-03 双声道连续播放 | 播放速率、写错误、写入最大耗时、左右声道信号 |
| `aud04_full_duplex` | AUD-04 双麦采集与双声道播放全双工 | 双向速率、读写错误、双通道 RMS、资源余量 |
| `aud05_recovery` | AUD-05 采样率切换和恢复 | close/reopen 成功率、重配耗时、读写错误、恢复后是否继续工作 |

## 当前 I2S 基线

当前 Korvo BSP 使用 `i2s_std_config_t` 的 Philips 标准 I2S，不是 TDM。默认基线为：

```text
48 kHz / 16 bit / stereo
SoC I2S master / ES8389 slave
BCLK GPIO3 / WS GPIO4 / DOUT GPIO5 / DIN GPIO6 / PA GPIO7
```

`BSP_I2S_MCLK` 当前为 `GPIO_NUM_NC`，因此本工程不把不存在的外部 MCLK 波形当作测试结果。若必须验证 TDM，需要另建低层 `i2s_channel_init_tdm_mode()` 工程，不能把本工程的标准 I2S 结果写成 TDM 结果。

## 构建与运行

根目录本身不是 ESP-IDF 工程；请进入具体的 `aud0x_*` 子目录执行命令。旧的单文件合并版已移到同级目录 `D:\ESP32S31\examples\codec\aud_legacy_combined`，仅用于回溯，不参与构建。

```powershell
cd D:\ESP32S31\examples\codec\aud\aud01_clock
idf.py --preview set-target esp32s31
idf.py --preview build
idf.py --preview -p COM5 flash monitor
```

每个工程自身的 `menuconfig` 只包含本用例的参数，例如采样率、应用块大小、持续时间和音量。建议每次只改变一个变量，分别烧录运行。

## 推荐测试顺序

1. AUD-01 固定 48 kHz / 16 bit / stereo，确认基本收发无错误。
2. AUD-01 扫描采样率：8k、16k、22.05k、24k、32k、44.1k、48k；不把驱动拒绝的配置当作芯片极限。
3. AUD-02/AUD-03 将应用块设置为 1024、512、480、256、128、64、32 frames，记录首个读写错误点。
4. AUD-04 固定收发格式，确认全双工长时间无读写错误，再叠加 AFE/AEC 等算法。
5. AUD-05 交替测试 48 kHz 与 16 kHz，记录重配耗时和恢复情况。

## 结果判定

每个配置至少重复 3 轮；基础点运行 5 分钟，拐点附近运行 10 分钟，最大稳定点运行 30 分钟。记录：

```text
固件/ESP-IDF/BSP 版本、采样率、位宽、声道、应用块大小、持续时间
实际 RX/TX 速率、读写错误、RMS、Peak、clip、调用 P50/P95/P99
内部 RAM、PSRAM、任务 CPU、BCLK/WS 实测频率、异常与恢复时间
```

`esp_codec_dev_read/write` 的等待时间包含 DMA 等待，不能直接当作 CPU 占用；需要结合任务运行时间统计区分阻塞时间和实际计算时间。

软件日志只能说明数字链路和 DMA 是否稳定。THD+N、输出功率、底噪、串扰和 PA 温升必须使用音频分析仪/示波器及 4 Ω 功率负载。长时间满幅正弦不要直接施加到普通扬声器。
