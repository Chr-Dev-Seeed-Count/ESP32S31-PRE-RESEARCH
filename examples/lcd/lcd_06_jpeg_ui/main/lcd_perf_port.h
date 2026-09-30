#pragma once
#include <stdbool.h>
#include "lvgl.h"
#ifdef __cplusplus
extern "C" {
#endif
lv_display_t *lcd_perf_port_init(void);
bool lcd_perf_lock(uint32_t timeout_ms);
void lcd_perf_unlock(void);
void lcd_perf_port_log_config(const char *demo_name);
#ifdef __cplusplus
}
#endif
