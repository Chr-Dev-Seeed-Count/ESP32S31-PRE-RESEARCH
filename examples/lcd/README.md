# ESP32-S31 LCD/LVGL 预研 demos

本目录对应预研规划 3.1 的 LCD-01～LCD-06。每个子目录都是独立的 ESP-IDF 工程，目标为 `esp32s31`，默认使用 Korvo-1 V1.1 的 800×480 RGB565 RGB 接口。

| Demo | 对应项 | 主要可调变量 |
|---|---|---|
| `lcd_01_rgb_timing` | LCD-01 RGB 时序 | `LCD_PERF_PCLK_HZ`、HSYNC/VSYNC pulse、porch |
| `lcd_02_buffer_strategy` | LCD-02 缓冲策略 | single/double/bounce、draw buffer 行数 |
| `lcd_03_lvgl_load` | LCD-03 LVGL 负载 | 控件数、动画步长、刷新周期、透明度 |
| `lcd_04_tearing_stability` | LCD-04 撕裂与稳定性 | 双帧、刷新周期、透明层数、PCLK |
| `lcd_05_chinese_text` | LCD-05 中文与长文本 | 文本长度、滚动步长、刷新周期 |
| `lcd_06_jpeg_ui` | LCD-06 JPEG/UI | JPEG 缩放、旋转、连续重解码 |

## 构建

```powershell
$env:IDF_PYTHON_ENV_PATH='D:\Espressif\python_env\idf6.2_py3.13_env'
. 'D:\Espressif-master\.espressif\master\esp-idf\export.ps1'
cd D:\ESP32S31\examples\lcd\lcd_03_lvgl_load
idf.py set-target esp32s31
idf.py menuconfig
idf.py build flash monitor
```

公共参数位于 `LCD/LVGL Performance Common` 菜单。建议每次只改变一个主变量，空载 5 分钟后逐级增加 10%～20%，拐点附近缩小步长，至少重复 3 轮。

LCD-05 的 `LCD_PERF_TEXT_LENGTH` 会生成实际长度的 UTF-8 样本文本。LCD-06 勾选 `LCD_PERF_JPEG_REDECODE` 后会按 `LCD_PERF_JPEG_REDECODE_PERIOD_MS` 周期性释放并重新解码图片，用于连续切图压力测试。

## 日志与判据

启动日志包含 `START demo=... pclk=... refresh=...`。周期日志包含 FPS、flush 次数、平均/最大 flush 时间、flush 错误数、internal/PSRAM heap 和最小 heap。驱动、JPEG 解析/分配/解码错误使用 `FIRST_ERROR` 标记；视觉首错需同步记录 RGB PCLK/HSYNC/VSYNC 波形。

LCD-06 复用了 `D:\ESPProjects\display_audio_photo\spiffs_content\esp_logo.jpg` 和 `esp_new_jpeg` 组件。

结果建议保存 `sdkconfig`、固件哈希、串口原始日志和 CSV/JSON 摘要，并记录基准点、拐点、最大持续值、首次错误点、恢复时间和瓶颈归属。









## 二、LCD-01：RGB 时序扫描

  目录：

  D:\ESP32S31\examples\lcd\lcd_01_rgb_timing

  用途：寻找 RGB PCLK、HSYNC/VSYNC 时序的性能上限和显示首错点。

  默认配置：

  PCLK = 18 MHz
  Buffer = Single
  Draw buffer lines = 40

  主要参数：

  LCD_PERF_PCLK_HZ
  LCD_PERF_HSYNC_PULSE
  LCD_PERF_HBP
  LCD_PERF_HFP
  LCD_PERF_VSYNC_PULSE
  LCD_PERF_VBP
  LCD_PERF_VFP

  推荐测试顺序：

  PCLK：18 MHz → 20 MHz → 22 MHz → 24 MHz → ...

  在每个 PCLK 下观察：

  - 是否出现横向错位
  - 是否出现闪烁、花屏、黑屏
  - FPS 是否下降
  - flush_err 是否增加
  - max_flush_us 是否突然变大

  然后固定 PCLK，在拐点附近逐项调整：

  HSYNC pulse
  HSYNC back/front porch
  VSYNC pulse
  VSYNC back/front porch

  启动日志中的：

  refresh=xx.xxHz

  是理论刷新率：

  refresh = PCLK / (HTOTAL × VTOTAL)

  建议同时使用示波器观察：

  - PCLK
  - HSYNC
  - VSYNC
  - DE

  这个 Demo 的首错通常首先表现为视觉异常，驱动日志不一定立即报错。

  ———

  ## 三、LCD-02：帧缓冲策略对比

  目录：

  D:\ESP32S31\examples\lcd\lcd_02_buffer_strategy

  用途：比较单帧、双帧、bounce buffer 和 LVGL draw buffer 对性能及内存的影响。

  默认配置：

  Buffer mode = Double
  Draw buffer lines = 40
  Moving objects = 24

  主要参数：

  LCD_PERF_BUFFER_MODE
  LCD_PERF_DRAW_BUF_LINES
  LCD_PERF_DRAW_BUF_DOUBLE
  LCD_PERF_BOUNCE_LINES
  LCD_PERF_BUFFER_OBJECTS

  LCD_PERF_BUFFER_MODE 有三种模式：

  Single frame buffer + partial LVGL
  Double frame buffer + direct LVGL
  Single frame buffer + bounce buffers

  推荐测试矩阵：

   模式                           Draw buffer lines    目的
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Single                                  20/40/80    观察局部刷新的内存和 FPS
  ─────────────────────────────  ───────────────────  ───────────────────────────────────
   Single + double draw buffer             20/40/80    观察 LVGL 双局部缓冲效果
  ─────────────────────────────  ───────────────────  ───────────────────────────────────
   Double frame buffer                         固定    观察直接渲染和撕裂情况
  ─────────────────────────────  ───────────────────  ───────────────────────────────────
   Bounce buffer                           10/20/40    观察 bounce buffer 吞吐和内存开销

  同时调整：

  LCD_PERF_BUFFER_OBJECTS

  该参数控制运动脏矩形数量。建议：

  24 → 48 → 96 → 160

  重点记录：

  - heap
  - psram
  - min_heap
  - FPS
  - 平均/最大 flush 时间
  - 是否出现撕裂、丢帧或花屏

  比较不同 buffer 模式时，应保持 PCLK、控件数量和刷新周期不变。

  ———

  ## 四、LCD-03：LVGL 控件负载

  目录：

  D:\ESP32S31\examples\lcd\lcd_03_lvgl_load

  用途：寻找 LVGL 控件数量、透明度和刷新频率造成的 CPU/内存拐点。

  默认配置：

  Widget count = 48
  Timer period = 16 ms
  Animation step = 7

  主要参数：

  LCD_PERF_WIDGET_COUNT
  LCD_PERF_TIMER_PERIOD_MS
  LCD_PERF_ANIM_STEP

  推荐测试顺序：

  ### 1. 增加控件数量

  48 → 64 → 96 → 128 → 192

  观察：

  - FPS 是否下降
  - flush 时间是否上升
  - heap 是否持续下降
  - LVGL 是否出现卡顿

  ### 2. 提高刷新频率

  Timer period：16 ms → 12 ms → 8 ms → 4 ms

  周期越小，LVGL 处理频率越高，CPU 压力越大。

  ### 3. 调整动画步长

  Animation step：7 → 14 → 28 → 56

  该参数主要用于改变动画运动幅度和视觉变化速度。

  推荐判据：

  - FPS 从稳定值突然下降
  - max_flush_us 出现尖峰
  - 屏幕动画不连续
  - heap 长时间持续减少
  - 看门狗复位或任务异常

  ———

  ## 五、LCD-04：撕裂与稳定性

  目录：

  D:\ESP32S31\examples\lcd\lcd_04_tearing_stability

  用途：在高速动画和多层透明合成下观察撕裂、花屏和恢复能力。

  默认配置：

  Double frame buffer
  Timer period = 8 ms
  Alpha layers = 8
  PCLK = 18 MHz

  主要参数：

  LCD_PERF_BUFFER_MODE
  LCD_PERF_TIMER_PERIOD_MS
  LCD_PERF_TEARING_LAYERS
  LCD_PERF_PCLK_HZ

  推荐测试顺序：

  ### 1. 提高动画刷新率

  8 ms → 6 ms → 4 ms → 2 ms

  ### 2. 增加透明层数

  8 → 12 → 16 → 24 → 32

  ### 3. 提高 PCLK

  18 MHz → 20 MHz → 22 MHz → ...

  重点观察：

  - 斜向或移动物体是否出现断裂
  - 屏幕上下区域是否不同步
  - 是否出现短暂花屏
  - 异常后能否自动恢复
  - flush_err 是否增加

  建议做两组对比：

  Double frame buffer
  Single frame buffer

  双帧模式通常更适合观察“LVGL 合成负载”，单帧模式更容易暴露撕裂和同步问题。

  此 Demo 必须配合示波器记录 PCLK、HSYNC、VSYNC，单靠串口日志无法完全判断撕裂原因。

  ———

  ## 六、LCD-05：中文与长文本

  目录：

  D:\ESP32S31\examples\lcd\lcd_05_chinese_text

  用途：测试 UTF-8 中文文本、长文本布局、滚动以及内存压力。

  默认配置：

  Text length = 1800
  Scroll pixels = 4

  主要参数：

  LCD_PERF_TEXT_LENGTH
  LCD_PERF_TEXT_SCROLL_PX
  LCD_PERF_TIMER_PERIOD_MS

  注意：LCD_PERF_TEXT_LENGTH 表示 UTF-8 字节长度，不是汉字数量。程序会避免截断中文多字节字符。

  推荐测试顺序：

  Text length：512 → 1024 → 1800 → 2400 → 3200

  然后调整滚动速度：

  Scroll pixels：4 → 8 → 16 → 32

  重点记录：

  - 文本首次显示是否异常
  - 中文是否显示为占位符
  - 滚动是否卡顿
  - FPS
  - heap 和 PSRAM 余量
  - 长时间运行是否出现内存下降

  当前默认字体是 Montserrat 14，中文可能显示为占位符。若需要真实中文字形，在 menuconfig 中启用：

  LVGL → Font usage → Source Han Sans SC CJK

  并将默认字体设置为对应的 Source Han Sans SC 字体。

  启用中文字体后，需要重新构建：

  idf.py build

  这个操作会增加 Flash 和内存占用，适合分别做两组测试：

  英文/占位符文本压力
  真实中文字库压力

  ———

  ## 七、LCD-06：JPEG 解码与 LVGL 图像

  目录：

  D:\ESP32S31\examples\lcd\lcd_06_jpeg_ui

  用途：测试 JPEG 解码、缩放、旋转、LVGL 图像刷新以及连续重解码。

  资源：

  main/esp_logo.jpg

  主要参数：

  LCD_PERF_JPEG_SCALE
  LCD_PERF_JPEG_ROTATE
  LCD_PERF_JPEG_ROTATE_STEP
  LCD_PERF_JPEG_REDECODE
  LCD_PERF_JPEG_REDECODE_PERIOD_MS

  ### 1. JPEG 缩放测试

  LCD_PERF_JPEG_SCALE = 0

  表示不缩放。

  然后可以测试：

  320
  480
  640
  800

  esp_new_jpeg 的缩放宽高要求通常为 8 的整数倍，因此建议使用 8 的倍数。

  观察：

  - JPEG 解码时间
  - 输出图像尺寸
  - PSRAM 使用量
  - FPS
  - 是否出现 FIRST_ERROR jpeg ...

  ### 2. JPEG 旋转测试

  在 menuconfig 中选择：

  0 degrees
  90 degrees
  180 degrees
  270 degrees

  该参数控制 JPEG 解码阶段旋转。

  LCD_PERF_JPEG_ROTATE_STEP 控制 LVGL 运行时图像旋转速度，单位是 0.1 度：

  0  = 不做运行时旋转
  15 = 每次定时器增加 1.5 度
  30 = 每次定时器增加 3.0 度

  如果只测试 JPEG 解码性能，建议：

  JPEG rotation = 0
  JPEG rotate step = 0

  如果测试 LVGL 图像变换，建议：

  JPEG rotation = 0
  JPEG rotate step = 15 或 30

  ### 3. 连续重解码测试

  启用：

  LCD_PERF_JPEG_REDECODE=y

  设置重解码周期：

  1000 ms → 500 ms → 200 ms → 100 ms

  每次重解码会释放旧图像、释放旧 buffer，再重新解码并创建 LVGL image 对象。

  重点观察：

  - 是否出现 JPEG 分配错误
  - 是否出现解码错误
  - heap 是否逐渐下降
  - 图像刷新是否卡顿
  - 长时间运行是否发生崩溃
  - FIRST_ERROR jpeg alloc
  - FIRST_ERROR jpeg decode

  建议先使用：

  JPEG_SCALE = 0
  REDECODE_PERIOD = 1000 ms

  确认稳定后，再逐渐降低重解码周期。

  ———

  ## 八、建议保存的测试数据

  每次实验建议保存：

  sdkconfig
  固件版本或源码提交号
  串口原始日志
  PCLK/HSYNC/VSYNC 波形
  测试时间
  环境温度

  建议最终整理成如下记录：

   项目          内容
  ━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   基准点        默认配置下 FPS、heap、flush
  ────────────  ───────────────────────────────────────
   性能拐点      参数达到多少后 FPS 明显下降
  ────────────  ───────────────────────────────────────
   首错点        第一次花屏、撕裂或 FIRST_ERROR
  ────────────  ───────────────────────────────────────
   最大稳定值    连续运行 5～10 分钟的最大参数
  ────────────  ───────────────────────────────────────
   恢复时间      异常后恢复到正常画面的时间
  ────────────  ───────────────────────────────────────
   瓶颈归属      RGB 时序、LVGL、PSRAM、JPEG 或 buffer

  当前 Demo 主要完成了“可调压力源 + 指标采集 + 首错标记”。真正的视觉首错、RGB 波形上限和长期稳定性，还需要在 Korvo-1 V1.1 实板上完
  成。