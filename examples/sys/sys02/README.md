# ESP32-S31 SYS-02 存储资源测试

每个子目录都是独立 ESP-IDF 工程，面向阶段 1 的 SYS-02：

| 工程 | 内容 |
|---|---|
| `sys02A` | Flash、Internal RAM、PSRAM 容量和最大连续空间 |
| `sys02B` | 四种 Internal RAM/PSRAM 拷贝带宽 |
| `sys02C` | Flash 只读顺序带宽 |
| `sys02D` | Flash + PSRAM 双核并行访问 |
| `sys02E` | Internal RAM/PSRAM 碎片 |
| `sys02F` | Flash/PSRAM 长时间压力，默认 10 分钟，最长可配置 24 小时 |

通用命令（ESP32-S31 使用 preview IDF 时保留 `--preview`）：

```powershell
cd D:\ESP32S31\examples\sys\sys02A
idf.py --preview set-target esp32s31
idf.py --preview build
idf.py --preview -p COM5 flash monitor
```

SYS-02C、02D、02F 使用 `bench` 数据分区，但都只读该分区；不会擦除 bootloader、分区表或当前 App。SYS-02F 正式 24 小时运行前，在 `menuconfig` 将 `SYS02F_DURATION_MINUTES` 设为 `1440`。
