# SYS-02E：Internal RAM / PSRAM 碎片测试

在 Internal RAM 和 PSRAM 上分别进行确定性的随机大小申请/释放，默认运行 60 秒。每 5 秒输出总空闲量、最大连续块、碎片率和分配失败数。

碎片率定义为：`1 - largest_free_block / free_total`。总空闲量较大但最大连续块明显下降时，说明已经不适合继续申请大缓冲区。
