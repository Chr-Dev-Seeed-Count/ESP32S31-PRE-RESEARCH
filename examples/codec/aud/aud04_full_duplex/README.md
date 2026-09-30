# AUD-04：全双工

独立验证 ES8389 的同时录音和播放。一个任务固定在 Core 0 连续写入 1 kHz 正弦波，另一个任务固定在 Core 1 连续读取双通道麦克风数据；主任务每秒输出速率、错误、RMS 和内存余量。

```powershell
cd D:\ESP32S31\examples\codec\aud\aud04_full_duplex
idf.py set-target esp32s31
idf.py build
idf.py -p COM5 flash monitor
```

该用例只验证数字全双工稳定性，不包含 AEC、NS、AGC 或 ESP-SR。
