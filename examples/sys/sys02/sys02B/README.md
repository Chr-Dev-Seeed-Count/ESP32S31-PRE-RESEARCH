# SYS-02B：PSRAM 与 Internal RAM 带宽

测试四种 `memcpy` 方向：Internal RAM→Internal RAM、Internal RAM→PSRAM、PSRAM→Internal RAM、PSRAM→PSRAM。每项使用 64 KiB 缓冲区运行约 2 秒，输出拷贝次数、MiB/s 和校验和。

该工程只做易失性读写，不擦写 Flash。若 PSRAM 分配失败，先在 `menuconfig` 开启并确认 PSRAM 配置。
