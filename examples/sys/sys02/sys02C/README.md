# SYS-02C：Flash 顺序读取带宽

在 factory App 分区内做只读顺序扫描，分别测试 256 B、1 KiB、4 KiB、16 KiB 和 64 KiB 块大小。工程不会擦写 Flash；记录每次读取的平均 MiB/s、最大单次耗时和校验和。

该结果是 Flash 读取基线。写入/擦除应使用独立测试分区并限制次数，不能擦除当前运行的 App、bootloader 或分区表。
