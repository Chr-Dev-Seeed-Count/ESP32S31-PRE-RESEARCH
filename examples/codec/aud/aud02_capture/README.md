# AUD-02：双麦连续采集

采集 ES8389 双 ADC 的交织双声道 PCM，输出实际采样率、双通道 RMS、Peak、Clip、读错误和调用时间。

仅改变 `Application block size` 找应用缓冲拐点；这不会自动改变 BSP 内部 DMA descriptor。要测 DMA descriptor 极限需要单独绕开 BSP 初始化 I2S。
