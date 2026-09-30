# SYS-02D：双核并行内存访问

通过 `idf.py menuconfig -> SYS-02D dual-core memory parallel benchmark` 选择场景。默认缓冲区为每个 worker 64 KiB、持续 2 秒、每 64 次拷贝检查一次时间，和 SYS-02B 口径一致。

| 场景 | Core 0 | Core 1 | 对比基线 |
|---|---|---|---|
| D1 | Flash read | PSRAM→PSRAM | SYS-02B PSRAM→PSRAM、SYS-02C Flash read |
| D2 | SRAM→SRAM | SRAM→SRAM | SYS-02B INT→INT |
| D3 | PSRAM→PSRAM | PSRAM→PSRAM | SYS-02B PSRAM→PSRAM |
| D4 | PSRAM→PSRAM | SRAM→SRAM | SYS-02B PSRAM→PSRAM、INT→INT |
| D5 | SRAM→PSRAM | SRAM→PSRAM | SYS-02B INT→PSRAM |

每次输出两个核心各自的实际耗时、字节数、带宽、校验和和错误数，以及两者带宽之和。汇总带宽仅用于比较不同场景，不代表物理总线理论带宽。

```text
下降率 = 1 - 并行场景中该核心带宽 / SYS-02B 对应单任务带宽
```
