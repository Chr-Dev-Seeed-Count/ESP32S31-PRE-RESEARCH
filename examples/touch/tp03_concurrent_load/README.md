# TP-03 Concurrent load

The demo measures touch response latency. Because this board has no GT1151 INT
connection, the start point is the first I2C read that observes a new press.
The result reports read-to-`LV_EVENT_PRESSED` and read-to-`LV_EVENT_REFR_READY`
latencies (p50/p95/p99/max), plus CPU0/CPU1 load.

The screen is intentionally static during the run. A press only toggles a
24x24 indicator, so the measured frame latency is dominated by input
dispatch, LVGL scheduling, rendering, and panel flush rather than animation
work.

`menuconfig -> TP-03 concurrent load -> CPU stress level` controls the CPU
duty cycle on both cores from 0 to 100%. Level 100 targets about 95% CPU busy
time while retaining a small watchdog-safe idle slice. The stress tasks run at
the LVGL task priority, so high levels also create scheduler contention. Run
separate builds at increasing levels and plot p95/p99 frame latency; the knee
is the practical latency limit.
The test has no polling task competing for the LVGL mutex, and the UI only
invalidates a small indicator on each press.

During each run, tap the same area repeatedly for a stable sample set. Build
again with a higher stress level to locate the point where p95/p99 rises sharply.
