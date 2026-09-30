# SYS-02A：容量和连续空间

读取 Flash、App/bench 分区、Internal RAM 和 PSRAM 的容量与当前最大连续空闲块。工程不擦写 Flash，每 5 秒打印一次快照。

```powershell
idf.py --preview set-target esp32s31
idf.py --preview build
idf.py --preview -p COM5 flash monitor
```

重点记录 `free` 与 `largest`。后者决定大型 LCD 帧缓冲、AI 模型和 DMA 缓冲能否连续分配。
