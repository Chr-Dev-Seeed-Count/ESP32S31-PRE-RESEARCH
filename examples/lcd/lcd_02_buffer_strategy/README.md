# LCD-02 缓冲策略

在 menuconfig 对比 single frame buffer、double frame buffer、bounce buffer，以及 `LCD_PERF_DRAW_BUF_LINES`/`LCD_PERF_DRAW_BUF_DOUBLE`。逐级增加 `LCD_PERF_BUFFER_OBJECTS`，记录 PSRAM、internal heap 和 flush 延迟。
