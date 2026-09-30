# AUD-03：连续播放

独立验证 ES8389 DAC→功放→扬声器的连续播放链路。程序以配置的采样率、16 bit、双声道输出 1 kHz 数字正弦波，并每秒报告实际写入速率、写错误和 DMA 写入耗时。

```powershell
cd D:\ESP32S31\examples\codec\aud\aud03_playback
idf.py set-target esp32s31
idf.py build
idf.py -p COM5 flash monitor
```

先以 48 kHz、低音量测试；长时间测试需要连接假负载或确认扬声器功率和温升。
