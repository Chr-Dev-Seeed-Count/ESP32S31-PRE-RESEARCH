# SYS-03 系统实时性与故障处理测试

本目录包含 6 个独立 ESP-IDF 工程：

| 工程 | 内容 | 主要日志 |
|---|---|---|
| sys03a | 任务绑核 | 期望核心、实际核心、忙时、栈余量 |
| sys03b | 1 kHz GPTimer 中断 | 中断频率、周期平均值、最小/最大周期、抖动 |
| sys03c | Core0 到 Core1 Queue IPC | 消息延迟、吞吐、队列丢弃 |
| sys03d | 任务看门狗 | 正常喂狗或故意超时 |
| sys03e | Coredump | 故意空指针异常，验证异常现场保存 |
| sys03f | 综合压力 | 双核计算、IPC、1 kHz 中断和看门狗同时运行 |

ESP32-S31 在当前 IDF 中属于 preview target，因此命令需要带 `--preview`。每个目录都可以独立执行：

```powershell
cd D:\ESP32S31\examples\sys\sys03\sys03a
idf.py --preview set-target esp32s31
idf.py --preview build flash monitor
```

SYS-03D 默认是安全模式，只喂狗不触发异常。需要验证超时前，将
`SYS03D_TRIGGER_TIMEOUT` 改为 `1` 后重新编译烧录。

SYS-03E 需要启用 Flash Coredump。工程已经提供 `sdkconfig.defaults` 和
`partitions.csv`，首次配置后执行：

```text
idf.py --preview menuconfig

并确认：

```text
Component config -> ESP System Settings -> Core dump -> Flash
```

首次切换到 SYS-03E 或修改分区表后建议执行一次：

```powershell
idf.py --preview erase-flash
idf.py --preview flash monitor
```

触发异常后使用 `idf.py monitor` 查看 panic 信息。由于 Coredump 保存在 Flash，
可以直接从开发板读取并解析：

```powershell
idf.py --preview -p COM5 coredump-info
```

也可以使用底层工具：

```powershell
espcoredump.py --chip esp32s31 -p COM5 info_corefile build\sys03e.elf
```

如果串口号不是 `COM5`，替换为实际端口；当前 IDF 版本的参数有差异时，
以 `idf.py coredump-info --help` 或 `espcoredump.py --help` 为准。

## 建议记录的指标

- SYS-03A：任务期望核心与实际核心、每次计算耗时、任务忙时占比、栈余量。
- SYS-03B：中断频率、周期平均值、最小/最大值、峰峰值抖动和 ISR 所在核心。
- SYS-03C：跨核消息平均/最大延迟、吞吐量和队列丢弃数。
- SYS-03D：正常模式下无复位；超时模式下记录 TWDT 日志、复位原因和复位时间。
- SYS-03E：记录 panic 原因、异常 PC/RA、任务名以及离线解析出的 backtrace。
- SYS-03F：在双核计算、IPC、定时器中断和 TWDT 同时运行时观察是否丢消息、复位或出现明显抖动。
