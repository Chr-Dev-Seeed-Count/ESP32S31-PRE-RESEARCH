# AUD-05：时钟重配与恢复

独立验证 Codec 关闭、重新打开和采样率切换后的恢复能力。程序交替使用主采样率和备用采样率，每个周期同时进行短时间播放和采集，记录打开失败、读写错误以及每次关闭/重开耗时。

```powershell
cd D:\ESP32S31\examples\codec\aud\aud05_recovery
idf.py set-target esp32s31
idf.py build
idf.py -p COM5 flash monitor
```

若某个采样率不被当前 ES8389/BSP 支持，会在对应周期输出 `open failed`；这属于配置兼容性结果，不应与 DMA 运行期错误混淆。
