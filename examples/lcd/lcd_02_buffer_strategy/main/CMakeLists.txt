idf_component_register(SRCS "lcd_perf_demo.c" "lcd_perf_port.c"
                       PRIV_REQUIRES esp_lcd esp_timer esp_driver_gpio
                       INCLUDE_DIRS ".")
