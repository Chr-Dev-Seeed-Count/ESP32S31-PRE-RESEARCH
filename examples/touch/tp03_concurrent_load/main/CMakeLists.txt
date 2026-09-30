idf_component_register(SRCS "app_main.c" INCLUDE_DIRS "."
                       PRIV_REQUIRES esp32_s31_korvo_1 esp_lcd_touch_gt1151
                       esp_codec_dev esp_lvgl_port lvgl esp_timer esp_wifi
                       esp_event esp_netif esp_video nvs_flash)
