idf_component_register(SRCS "lcd_perf_demo.c" "lcd_perf_port.c"
                       EMBED_FILES "esp_logo.jpg"
                       PRIV_REQUIRES esp_lcd esp_timer esp_driver_gpio esp_new_jpeg
                       INCLUDE_DIRS ".")
