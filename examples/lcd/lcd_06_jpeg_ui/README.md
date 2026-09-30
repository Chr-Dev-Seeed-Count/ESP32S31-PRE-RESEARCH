# LCD-06 JPEG/UI

工程嵌入 `esp_logo.jpg`，使用 `esp_new_jpeg` 解码并交给 LVGL image。扫描 `LCD_PERF_JPEG_SCALE`、rotation choice、`LCD_PERF_JPEG_ROTATE_STEP`，并可勾选 `LCD_PERF_JPEG_REDECODE` 周期性重解码，观察 decode 首错、图像尺寸/内存和连续 UI 刷新性能。
