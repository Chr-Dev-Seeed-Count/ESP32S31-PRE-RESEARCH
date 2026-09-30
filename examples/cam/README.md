# OV3660 CAM-01 … CAM-06

这是 ESP32-S31 Korvo-1 板载 OV3660 的统一测试工程。工程启动摄像头后，按
`menuconfig -> OV3660 camera test suite -> Test case` 选择一个测试；结果只输出
结构化的 `CAM_RESULT` 行，便于串口脚本采集。

## 构建与烧录

本工程按 ESP32-S31 当前工具链构建；本机验证环境为 ESP-IDF 6.2/master，旧版
ESP-IDF 5.5 可能不识别 `esp32s31` 目标。

```powershell
cd D:\ESP32S31\examples\cam
idf.py set-target esp32s31
idf.py menuconfig
idf.py build flash monitor
```

默认打开 OV3660 的五种驱动格式：JPEG 1280×720、RGB565(BE)/YUYV 的 640×480 和
240×240。`CAM_RUN_SECONDS` 控制每项采集时长，`CAM_STRESS_LEVEL`（0…10）在
两个 CPU 上启动有界忙循环；等级 10 目标约 90% 忙碌时间，等级 3 约 27%。忙循环
按周期主动让出 CPU，不会长期占用 IDLE 任务，从而避免测试压力本身触发 task
watchdog。结果中的 `cpu_load=x/y` 是压力任务实际占用率，可用于确认加压是否生效。
`CAM_BUFFER_COUNT` 调整 V4L2 MMAP 队列。

## 测试定义

* CAM-01：逐项设置支持的分辨率/格式，测帧数、实际 FPS、帧间隔 P50/P95/P99。
* CAM-02：同一组格式，额外报告平均帧大小和输入带宽（kbps）。
* CAM-03：JPEG 帧经硬件 JPEG 解码为 RGB565，再由一次 PPA 事务完成居中裁剪、
  640×480 缩放和 180° 旋转；报告解码平均耗时（`aux`）和完整处理平均耗时
  （`op_us` 及其 P50/P95/P99）。
* CAM-04：640×480 RGB565(BE) 采集，经 PPA 字节交换和缩放到 800×480 后直接提交 RGB LCD，绕过
  LVGL；通过 RGB 面板 `on_frame_buf_complete` 回调记录一帧扫描完成时间，报告采集
  到 LCD 帧完成的端到端 P50/P95/P99（`op_p50_us/op_p95_us/op_p99_us`），以及其中
  PPA 耗时（`aux`）。如果 LCD 驱动未产生帧完成回调，该帧计为错误。
* CAM-05：YUYV 帧计算 Y 均值、最小/最大值和饱和比例，作为外部照度变化及 AE
  恢复的图像代理；`aux` 打包为 `mean[63:48] / min[47:40] / max[39:32] /
  saturation-permille[31:0]`，照度值由测试人员用照度计记录。
* CAM-06：YUYV 帧统计亮度代理和帧间隔，用于运动拖影/丢帧/恢复测试；移动目标
  和压力等级由测试人员按轮次改变。

每轮结束只输出一行结果（初始化错误除外），例如：

`CAM_RESULT id=CAM-01 fmt=YUYV 640x480 fps=9.9 frames=50 ... p99_us=... cpu_load=35/37`

规划要求的三轮重复、最大可持续值和首次错误点，应由脚本保存每轮的
`CAM_RESULT` 后计算均值、标准差和拐点。`drops` 来自 V4L2 buffer sequence
间隔；照度、运动速度和 LCD 物理扫描完成时间仍需由对应外设/测试夹具提供时间戳。
