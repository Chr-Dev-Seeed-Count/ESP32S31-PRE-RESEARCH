# GT1151 touch-screen validation

These four projects implement the TP-01 to TP-04 items in the Korvo-1 V1.1
extreme pre-research plan. The projects use the ESP32-S31-Korvo-1 BSP and the
GT1151 I2C driver already used by `D:/ESPProjects/display_audio_photo`.

| Demo | Purpose | Main output |
|---|---|---|
| `tp01_coordinate` | Center, edge and corner coordinate accuracy | Mean/max coordinate error and missing samples |
| `tp02_trajectory` | Fast line, swipe, long press and drag continuity | LCD live trail plus contact rate, path length and split gap diagnostics |
| `tp03_concurrent_load` | Touch service under UI, Wi-Fi, audio and camera load | Touch polling interval, events, heap and load status |
| `tp04_recovery` | I2C reset, GT1151 driver deletion/reconnection and physical unplug observation | Read errors and recovery time |

Board wiring comes from the BSP: I2C SDA=GPIO0, SCL=GPIO1, GT1151 address
0x14, display resolution 800x480. The touch interrupt and reset pins are NC
on this board, so TP-04 uses I2C bus reset plus GT1151 driver deletion/recreation.

Each subdirectory is an independent ESP-IDF project. In a project directory:

```powershell
idf.py --preview set-target esp32s31
idf.py --preview build flash monitor
```

The component manifest uses public registry dependencies. If the registry is
not reachable, copy the corresponding `managed_components` from the existing
`D:/ESPProjects/display_audio_photo` project into the demo directory.
