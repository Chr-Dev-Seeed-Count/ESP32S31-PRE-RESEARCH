/* Automatically generated file; DO NOT EDIT */
/* Espressif IoT Development Framework Linker Script */
/* Generated from: D:\ESP32S31\examples\sys\sys02A\build\esp-idf\esp_system\ld\sections.ld.in */

/*
 * SPDX-FileCopyrightText: 2022 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* Default entry point */
ENTRY(call_start_cpu0);
SECTIONS
{
/*

 * Automatically generated file. DO NOT EDIT.

 * Espressif IoT Development Framework (ESP-IDF) 6.2.0 Configuration Header

 */
       
/* List of deprecated options */
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  /**
   * RTC fast memory holds RTC wake stub code,
   * including from any source file named rtc_wake_stub*.c
   */
  .rtc.text :
  {
    /**
     * Align the start of RTC code region as per PMP granularity.
     * This ensures we do not overwrite the permissions for the previous
     * region (ULP mem/RTC reserved) regardless of their end alignment.
     */
    . = ALIGN(128);
    _rtc_fast_start = ABSOLUTE(.);
    _rtc_text_start = ABSOLUTE(.);
    HIDDEN(_rtc_code_start = .);
    *(.rtc.entry.text)
    
 *(.rtc.literal .rtc.text .rtc.text.*)
    *rtc_wake_stub*.*(.text .text.*)
    *(.rtc_text_end_test)
    /* Align the end of RTC code region as per PMP granularity */
    . = ALIGN(128);
    HIDDEN(_rtc_code_end = .);
    /* Padding for possible CPU prefetch + 4B alignment for PMS split lines. */
    . = ((_rtc_code_end - _rtc_code_start) == 0) ?
        ALIGN(0) : 0 + ALIGN(4);
    _rtc_text_end = ABSOLUTE(.);
  } > rtc_text_seg
  /**
   * This section is located in RTC FAST Memory area.
   * It holds data marked with RTC_FAST_ATTR attribute.
   * See the file "esp_attr.h" for more information.
   */
  .rtc.force_fast :
  {
    
 . = ALIGN(4); 
 _rtc_force_fast_start = ABSOLUTE(.);
    
    *(.rtc.force_fast .rtc.force_fast.*)
    
 . = ALIGN(4); 
 _rtc_force_fast_end = ABSOLUTE(.);
  } > rtc_force_fast_seg
  /**
   * RTC data section holds RTC wake stub data/rodata, including from
   * any source file named rtc_wake_stub*.c and the data marked with
   * RTC_DATA_ATTR, RTC_RODATA_ATTR attributes.
   */
  .rtc.data :
  {
    _rtc_data_start = ABSOLUTE(.);
    
 *(.rtc.data .rtc.data.*)
 *(.rtc.rodata .rtc.rodata.*)
    *rtc_wake_stub*.*(.data .rodata .data.* .rodata.* .srodata.*)
    _rtc_data_end = ABSOLUTE(.);
  } > rtc_data_seg
  /* RTC bss, from any source file named rtc_wake_stub*.c */
  .rtc.bss (NOLOAD) :
  {
    _rtc_bss_start = ABSOLUTE(.);
    *rtc_wake_stub*.*(.bss .bss.* .sbss .sbss.*)
    *rtc_wake_stub*.*(COMMON)
    
 *(.rtc.bss)
    _rtc_bss_end = ABSOLUTE(.);
  } > rtc_data_seg
  /**
   * This section holds data that should not be initialized at power up
   * and will be retained during deep sleep.
   * User data marked with RTC_NOINIT_ATTR will be placed into this section.
   * See the file "esp_attr.h" for more information.
   */
  .rtc_noinit (NOLOAD) :
  {
    
 . = ALIGN(4); 
 _rtc_noinit_start = ABSOLUTE(.);
    
    *(.rtc_noinit .rtc_noinit.*)
    
 . = ALIGN(4); 
 _rtc_noinit_end = ABSOLUTE(.);
  } > rtc_data_seg
  /**
   * This section is located in RTC SLOW Memory area.
   * It holds data marked with RTC_SLOW_ATTR attribute.
   * See the file "esp_attr.h" for more information.
   */
  .rtc.force_slow :
  {
    
 . = ALIGN(4); 
 _rtc_force_slow_start = ABSOLUTE(.);
    *(.rtc.force_slow .rtc.force_slow.*)
    
 . = ALIGN(4); 
 _rtc_force_slow_end = ABSOLUTE(.);
  } > rtc_force_slow_seg
  /**
   * This section holds RTC data that should have fixed addresses.
   * The data are not initialized at power-up and are retained during deep sleep.
   */
  .rtc_reserved (NOLOAD) :
  {
    
 . = ALIGN(4); 
 _rtc_reserved_start = ABSOLUTE(.);
    /**
     * IMPORTANT: Existing data must not be moved.
     * Data have adhered to the beginning or ending of the segment
     * (depending on chip) and code relies on it.
     */
    /**
     * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     * Put new data before this line
     */
    *(.rtc_timer_data_in_rtc_mem .rtc_timer_data_in_rtc_mem.*)
    KEEP(*(.bootloader_data_rtc_mem .bootloader_data_rtc_mem.*))
    _bootloader_data_rtc_mem_end = ABSOLUTE(.);
    /* ROM keeps the verified image digest in the last bytes of RTC RAM */
    . = . + 0;
    _rtc_reserved_end = ABSOLUTE(.);
  } > rtc_reserved_seg
  _rtc_ulp_memory_start = _rtc_reserved_start + LENGTH(rtc_reserved_seg);
  _rtc_reserved_length = _rtc_reserved_end - _rtc_reserved_start;
  ASSERT((_rtc_reserved_length <= LENGTH(rtc_reserved_seg)),
          "RTC reserved segment data does not fit.")
  /* Get size of rtc slow data based on rtc_data_seg alias */
  _rtc_slow_length = (ORIGIN(rtc_slow_seg) == ORIGIN(rtc_data_seg))
                        ? (_rtc_force_slow_end - _rtc_data_start)
                        : (_rtc_force_slow_end - _rtc_force_slow_start);
  _rtc_fast_length = (ORIGIN(rtc_slow_seg) == ORIGIN(rtc_data_seg))
                        ? (_rtc_force_fast_end - _rtc_fast_start)
                        : (_rtc_noinit_end - _rtc_fast_start);
  ASSERT((_rtc_slow_length <= LENGTH(rtc_slow_seg)),
          "RTC_SLOW segment data does not fit.")
  ASSERT((_rtc_fast_length <= LENGTH(rtc_data_seg)),
          "RTC_FAST segment data does not fit.")
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  .iram0.text :
  {
    _iram_start = ABSOLUTE(.);
    /* Vectors go to start of IRAM */
    ASSERT(ABSOLUTE(.) % ALIGN_VECTOR_TABLE == 0, "vector address must be ALIGN_VECTOR_TABLE byte aligned");
    _vector_table_start = ABSOLUTE(.);
    KEEP(*(.exception_vectors_table.text));
    KEEP(*(.exception_vectors.text));
    /* Code marked as running out of IRAM */
    _iram_text_start = ABSOLUTE(.);
    
 
 *(.iram1 .iram1.*)
 *libclang_rt.builtins.a:_divsf3.*(.literal .literal.* .text .text.*)
 *libclang_rt.builtins.a:restore.*(.literal .literal.* .text .text.*)
 *libclang_rt.builtins.a:save.*(.literal .literal.* .text .text.*)
 *libcoexist.a:(.coexiram .coexiram.*)
 *libcoexist.a:(.coexsleepiram .coexsleepiram.*)
 *libesp_driver_ana_cmpr.a:ana_cmpr.*(.literal.ana_cmpr_default_intr_handler .text.ana_cmpr_default_intr_handler)
 *libesp_driver_dma.a:dma2d.*(.literal._dma2d_default_rx_isr .text._dma2d_default_rx_isr)
 *libesp_driver_dma.a:dma2d.*(.literal._dma2d_default_tx_isr .text._dma2d_default_tx_isr)
 *libesp_driver_dma.a:dma2d.*(.literal.acquire_free_channels_for_trans .text.acquire_free_channels_for_trans)
 *libesp_driver_dma.a:dma2d.*(.literal.dma2d_default_isr .text.dma2d_default_isr)
 *libesp_driver_dma.a:dma2d.*(.literal.free_up_channels .text.free_up_channels)
 *libesp_driver_dma.a:esp_dma_utils.*(.literal.esp_dma_merge_aligned_rx_buffers .text.esp_dma_merge_aligned_rx_buffers)
 *libesp_driver_dma.a:esp_dma_utils.*(.literal.esp_dma_split_rx_buffer_to_cache_aligned .text.esp_dma_split_rx_buffer_to_cache_aligned)
 *libesp_driver_dma.a:gdma.*(.literal.gdma_append .text.gdma_append)
 *libesp_driver_dma.a:gdma.*(.literal.gdma_default_rx_isr .text.gdma_default_rx_isr)
 *libesp_driver_dma.a:gdma.*(.literal.gdma_default_tx_isr .text.gdma_default_tx_isr)
 *libesp_driver_dma.a:gdma.*(.literal.gdma_reset .text.gdma_reset)
 *libesp_driver_dma.a:gdma.*(.literal.gdma_start .text.gdma_start)
 *libesp_driver_dma.a:gdma.*(.literal.gdma_stop .text.gdma_stop)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_check_end .text.gdma_link_check_end)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_concat .text.gdma_link_concat)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_count_buffer_size_till_eof .text.gdma_link_count_buffer_size_till_eof)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_get_buffer .text.gdma_link_get_buffer)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_get_head_addr .text.gdma_link_get_head_addr)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_get_length .text.gdma_link_get_length)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_mount_buffers .text.gdma_link_mount_buffers)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_set_length .text.gdma_link_set_length)
 *libesp_driver_dma.a:gdma_link.*(.literal.gdma_link_set_owner .text.gdma_link_set_owner)
 *libesp_driver_gptimer.a:gptimer.*(.literal.gptimer_default_isr .text.gptimer_default_isr)
 *libesp_driver_i2c.a:i2c_master.*(.literal.i2c_master_isr_handler_default .text.i2c_master_isr_handler_default)
 *libesp_driver_mcpwm.a:mcpwm_cap.*(.literal.mcpwm_capture_default_isr .text.mcpwm_capture_default_isr)
 *libesp_driver_mcpwm.a:mcpwm_cmpr.*(.literal.mcpwm_comparator_default_isr .text.mcpwm_comparator_default_isr)
 *libesp_driver_mcpwm.a:mcpwm_fault.*(.literal.mcpwm_gpio_fault_default_isr .text.mcpwm_gpio_fault_default_isr)
 *libesp_driver_mcpwm.a:mcpwm_oper.*(.literal.mcpwm_operator_default_isr .text.mcpwm_operator_default_isr)
 *libesp_driver_mcpwm.a:mcpwm_timer.*(.literal.mcpwm_timer_default_isr .text.mcpwm_timer_default_isr)
 *libesp_driver_parlio.a:parlio_common.*(.literal.parlio_sw_retention .text.parlio_sw_retention)
 *libesp_driver_parlio.a:parlio_rx.*(.literal.parlio_rx_default_desc_done_callback .text.parlio_rx_default_desc_done_callback)
 *libesp_driver_parlio.a:parlio_rx.*(.literal.parlio_rx_default_eof_callback .text.parlio_rx_default_eof_callback)
 *libesp_driver_parlio.a:parlio_rx.*(.literal.parlio_rx_mount_transaction_buffer .text.parlio_rx_mount_transaction_buffer)
 *libesp_driver_parlio.a:parlio_rx.*(.literal.parlio_rx_set_delimiter_config .text.parlio_rx_set_delimiter_config)
 *libesp_driver_parlio.a:parlio_rx.*(.literal.parlio_rx_unit_receive_from_isr .text.parlio_rx_unit_receive_from_isr)
 *libesp_driver_parlio.a:parlio_rx.*(.literal.parlio_rx_unit_trigger_fake_eof .text.parlio_rx_unit_trigger_fake_eof)
 *libesp_driver_parlio.a:parlio_tx.*(.literal.parlio_mount_buffer .text.parlio_mount_buffer)
 *libesp_driver_parlio.a:parlio_tx.*(.literal.parlio_tx_default_isr .text.parlio_tx_default_isr)
 *libesp_driver_parlio.a:parlio_tx.*(.literal.parlio_tx_do_transaction .text.parlio_tx_do_transaction)
 *libesp_driver_parlio.a:parlio_tx.*(.literal.parlio_tx_gdma_buffer_switched_callback .text.parlio_tx_gdma_buffer_switched_callback)
 *libesp_driver_rmt.a:rmt_encoder.*(.literal.rmt_encoder_reset .text.rmt_encoder_reset)
 *libesp_driver_rmt.a:rmt_rx.*(.literal.rmt_dma_rx_one_block_cb .text.rmt_dma_rx_one_block_cb)
 *libesp_driver_rmt.a:rmt_rx.*(.literal.rmt_isr_handle_rx_done .text.rmt_isr_handle_rx_done)
 *libesp_driver_rmt.a:rmt_rx.*(.literal.rmt_isr_handle_rx_threshold .text.rmt_isr_handle_rx_threshold)
 *libesp_driver_rmt.a:rmt_rx.*(.literal.rmt_rx_default_isr .text.rmt_rx_default_isr)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_dma_tx_eof_cb .text.rmt_dma_tx_eof_cb)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_encode_check_result .text.rmt_encode_check_result)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_isr_handle_tx_done .text.rmt_isr_handle_tx_done)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_isr_handle_tx_loop_end .text.rmt_isr_handle_tx_loop_end)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_isr_handle_tx_threshold .text.rmt_isr_handle_tx_threshold)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_tx_default_isr .text.rmt_tx_default_isr)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_tx_do_transaction .text.rmt_tx_do_transaction)
 *libesp_driver_rmt.a:rmt_tx.*(.literal.rmt_tx_mark_eof .text.rmt_tx_mark_eof)
 *libesp_event.a:default_event_loop.*(.literal.esp_event_isr_post .text.esp_event_isr_post)
 *libesp_event.a:esp_event.*(.literal.esp_event_isr_post_to .text.esp_event_isr_post_to)
 *libesp_hal_ana_conv.a:temperature_sensor_hal.*(.literal.temperature_sensor_hal_get_raw_value .text.temperature_sensor_hal_get_raw_value)
 *libesp_hal_ana_conv.a:temperature_sensor_hal.*(.literal.temperature_sensor_hal_i2c_saradc_reg_backup .text.temperature_sensor_hal_i2c_saradc_reg_backup)
 *libesp_hal_ana_conv.a:temperature_sensor_hal.*(.literal.temperature_sensor_hal_i2c_saradc_reg_restore .text.temperature_sensor_hal_i2c_saradc_reg_restore)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_append .text.gdma_ahb_hal_append)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_clear_intr .text.gdma_ahb_hal_clear_intr)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_get_eof_desc_addr .text.gdma_ahb_hal_get_eof_desc_addr)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_is_tx_link_switch_event_supported .text.gdma_ahb_hal_is_tx_link_switch_event_supported)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_read_intr_status .text.gdma_ahb_hal_read_intr_status)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_reset .text.gdma_ahb_hal_reset)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_start_with_desc .text.gdma_ahb_hal_start_with_desc)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.literal.gdma_ahb_hal_stop .text.gdma_ahb_hal_stop)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_append .text.gdma_axi_hal_append)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_clear_intr .text.gdma_axi_hal_clear_intr)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_get_eof_desc_addr .text.gdma_axi_hal_get_eof_desc_addr)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_is_tx_link_switch_event_supported .text.gdma_axi_hal_is_tx_link_switch_event_supported)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_read_intr_status .text.gdma_axi_hal_read_intr_status)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_reset .text.gdma_axi_hal_reset)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_start_with_desc .text.gdma_axi_hal_start_with_desc)
 *libesp_hal_dma.a:gdma_hal_axi.*(.literal.gdma_axi_hal_stop .text.gdma_axi_hal_stop)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_append .text.gdma_hal_append)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_clear_intr .text.gdma_hal_clear_intr)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_get_eof_desc_addr .text.gdma_hal_get_eof_desc_addr)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_is_tx_link_switch_event_supported .text.gdma_hal_is_tx_link_switch_event_supported)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_read_intr_status .text.gdma_hal_read_intr_status)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_reset .text.gdma_hal_reset)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_start_with_desc .text.gdma_hal_start_with_desc)
 *libesp_hal_dma.a:gdma_hal_top.*(.literal.gdma_hal_stop .text.gdma_hal_stop)
 *libesp_hal_gpio.a:gpio_hal.*(.literal.gpio_hal_isolate_in_sleep .text.gpio_hal_isolate_in_sleep)
 *libesp_hal_gpspi.a:spi_hal_iram.*(.literal .literal.* .text .text.*)
 *libesp_hal_gpspi.a:spi_slave_hal_iram.*(.literal .literal.* .text .text.*)
 *libesp_hal_i2c.a:i2c_hal_iram.*(.literal .literal.* .text .text.*)
 *libesp_hal_ledc.a:ledc_hal_iram.*(.literal .literal.* .text .text.*)
 *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.*(.literal .literal.* .text .text.*)
 *libesp_hal_mspi.a:spi_flash_hal_gpspi.*(.literal .literal.* .text .text.*)
 *libesp_hal_mspi.a:spi_flash_hal_iram.*(.literal .literal.* .text .text.*)
 *libesp_hal_pmu.a:pmu_hal.*(.literal .literal.* .text .text.*)
 *libesp_hal_regi2c.a:(.literal .literal.* .text .text.*)
 *libesp_hal_systimer.a:(.literal .literal.* .text .text.*)
 *libesp_hal_timg.a:timer_hal.*(.literal.timer_hal_capture_and_get_counter_value .text.timer_hal_capture_and_get_counter_value)
 *libesp_hal_wdt.a:rom_patch.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:adc_share_hw_ctrl.*(.literal.adc_apb_periph_claim .text.adc_apb_periph_claim)
 *libesp_hw_support.a:adc_share_hw_ctrl.*(.literal.adc_apb_periph_free .text.adc_apb_periph_free)
 *libesp_hw_support.a:clk_utils.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:cpu.*(.literal.esp_cpu_compare_and_set .text.esp_cpu_compare_and_set)
 *libesp_hw_support.a:cpu.*(.literal.esp_cpu_reset .text.esp_cpu_reset)
 *libesp_hw_support.a:cpu.*(.literal.esp_cpu_stall .text.esp_cpu_stall)
 *libesp_hw_support.a:cpu.*(.literal.esp_cpu_unstall .text.esp_cpu_unstall)
 *libesp_hw_support.a:cpu.*(.literal.esp_cpu_wait_for_intr .text.esp_cpu_wait_for_intr)
 *libesp_hw_support.a:esp_clk.*(.literal.esp_clk_private_lock .text.esp_clk_private_lock)
 *libesp_hw_support.a:esp_clk.*(.literal.esp_clk_private_unlock .text.esp_clk_private_unlock)
 *libesp_hw_support.a:esp_clk.*(.literal.esp_clk_slowclk_cal_get .text.esp_clk_slowclk_cal_get)
 *libesp_hw_support.a:esp_clk.*(.literal.esp_clk_slowclk_cal_set .text.esp_clk_slowclk_cal_set)
 *libesp_hw_support.a:esp_clk.*(.literal.esp_rtc_get_time_us .text.esp_rtc_get_time_us)
 *libesp_hw_support.a:esp_clk_tree.*(.literal.esp_clk_tree_enable_power .text.esp_clk_tree_enable_power)
 *libesp_hw_support.a:esp_clk_tree.*(.literal.esp_clk_tree_enable_src .text.esp_clk_tree_enable_src)
 *libesp_hw_support.a:esp_clk_tree_common.*(.literal.esp_clk_tree_apll_acquire .text.esp_clk_tree_apll_acquire)
 *libesp_hw_support.a:esp_clk_tree_common.*(.literal.esp_clk_tree_apll_release .text.esp_clk_tree_apll_release)
 *libesp_hw_support.a:esp_clk_tree_common.*(.literal.esp_clk_tree_is_power_on .text.esp_clk_tree_is_power_on)
 *libesp_hw_support.a:esp_clk_tree_common.*(.literal.esp_clk_tree_mpll_release .text.esp_clk_tree_mpll_release)
 *libesp_hw_support.a:esp_gpio_reserve.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:esp_memory_utils.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:mspi_timing_by_dqs.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:mspi_timing_config.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:mspi_timing_tuning.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_module_reset .text.periph_module_reset)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_rcc_acquire_enter .text.periph_rcc_acquire_enter)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_rcc_acquire_exit .text.periph_rcc_acquire_exit)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_rcc_enter .text.periph_rcc_enter)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_rcc_exit .text.periph_rcc_exit)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_rcc_release_enter .text.periph_rcc_release_enter)
 *libesp_hw_support.a:periph_ctrl.*(.literal.periph_rcc_release_exit .text.periph_rcc_release_exit)
 *libesp_hw_support.a:periph_ctrl.*(.literal.wifi_module_disable .text.wifi_module_disable)
 *libesp_hw_support.a:periph_ctrl.*(.literal.wifi_module_enable .text.wifi_module_enable)
 *libesp_hw_support.a:peripheral_domain_pd.*(.literal.peripheral_domain_pd_allowed .text.peripheral_domain_pd_allowed)
 *libesp_hw_support.a:pmu_sleep.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:regi2c_ctrl.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:rtc_clk.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:rtc_time.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:sar_periph_ctrl.*(.literal.adc_reset_lock_acquire .text.adc_reset_lock_acquire)
 *libesp_hw_support.a:sar_periph_ctrl.*(.literal.adc_reset_lock_release .text.adc_reset_lock_release)
 *libesp_hw_support.a:sar_periph_ctrl.*(.literal.sar_periph_ctrl_adc_reset .text.sar_periph_ctrl_adc_reset)
 *libesp_hw_support.a:sar_periph_ctrl.*(.literal.sar_periph_ctrl_power_disable .text.sar_periph_ctrl_power_disable)
 *libesp_hw_support.a:sar_periph_ctrl.*(.literal.sar_periph_ctrl_power_enable .text.sar_periph_ctrl_power_enable)
 *libesp_hw_support.a:sar_periph_ctrl_common.*(.literal.regi2c_saradc_disable .text.regi2c_saradc_disable)
 *libesp_hw_support.a:sar_periph_ctrl_common.*(.literal.regi2c_saradc_enable .text.regi2c_saradc_enable)
 *libesp_hw_support.a:sar_tsens_ctrl.*(.literal.temp_sensor_get_raw_value .text.temp_sensor_get_raw_value)
 *libesp_hw_support.a:sar_tsens_ctrl.*(.literal.temperature_sensor_power_acquire .text.temperature_sensor_power_acquire)
 *libesp_hw_support.a:sar_tsens_ctrl.*(.literal.temperature_sensor_power_release .text.temperature_sensor_power_release)
 *libesp_hw_support.a:sleep_cache.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:sleep_clock.*(.literal.clock_domain_pd_allowed .text.clock_domain_pd_allowed)
 *libesp_hw_support.a:sleep_console.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:sleep_cpu.*(.literal.cpu_domain_pd_allowed .text.cpu_domain_pd_allowed)
 *libesp_hw_support.a:sleep_modem.*(.literal.modem_domain_pd_allowed .text.modem_domain_pd_allowed)
 *libesp_hw_support.a:sleep_modem.*(.literal.periph_inform_out_light_sleep_overhead .text.periph_inform_out_light_sleep_overhead)
 *libesp_hw_support.a:sleep_modem.*(.literal.sleep_modem_reject_triggers .text.sleep_modem_reject_triggers)
 *libesp_hw_support.a:sleep_modes.*(.literal.esp_light_sleep_start .text.esp_light_sleep_start)
 *libesp_hw_support.a:sleep_modes.*(.literal.esp_sleep_enable_timer_wakeup .text.esp_sleep_enable_timer_wakeup)
 *libesp_hw_support.a:sleep_mspi.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:sleep_usb.*(.literal .literal.* .text .text.*)
 *libesp_hw_support.a:systimer.*(.literal .literal.* .text .text.*)
 *libesp_libc.a:abort.*(.literal .literal.* .text .text.*)
 *libesp_libc.a:assert.*(.literal .literal.* .text .text.*)
 *libesp_libc.a:esp_time_impl.*(.literal.esp_set_time_from_rtc .text.esp_set_time_from_rtc)
 *libesp_libc.a:esp_time_impl.*(.literal.esp_time_impl_get_boot_time .text.esp_time_impl_get_boot_time)
 *libesp_libc.a:esp_time_impl.*(.literal.esp_time_impl_set_boot_time .text.esp_time_impl_set_boot_time)
 *libesp_libc.a:heap.*(.literal .literal.* .text .text.*)
 *libesp_libc.a:stdatomic.*(.literal .literal.* .text .text.*)
 *libesp_mm.a:esp_cache_msync.*(.literal .literal.* .text .text.*)
 *libesp_mm.a:esp_cache_utils.*(.literal .literal.* .text .text.*)
 *libesp_phy.a:phy_init.*(.literal.esp_phy_disable .text.esp_phy_disable)
 *libesp_phy.a:phy_init.*(.literal.esp_phy_enable .text.esp_phy_enable)
 *libesp_phy.a:phy_init.*(.literal.esp_wifi_bt_power_domain_off .text.esp_wifi_bt_power_domain_off)
 *libesp_phy.a:phy_override.*(.literal.phy_get_tsens_value .text.phy_get_tsens_value)
 *libesp_pm.a:pm_impl.*(.literal.esp_pm_impl_get_cpu_freq .text.esp_pm_impl_get_cpu_freq)
 *libesp_psram.a:esp_psram_impl_ap_oct.*(.literal .literal.* .text .text.*)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvAcquireItemNoSplit .text.prvAcquireItemNoSplit)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvCheckItemAvail .text.prvCheckItemAvail)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvCheckItemFitsByteBuffer .text.prvCheckItemFitsByteBuffer)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvCheckItemFitsDefault .text.prvCheckItemFitsDefault)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvCopyItemAllowSplit .text.prvCopyItemAllowSplit)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvCopyItemByteBuf .text.prvCopyItemByteBuf)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvCopyItemNoSplit .text.prvCopyItemNoSplit)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvGetItemByteBuf .text.prvGetItemByteBuf)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvGetItemDefault .text.prvGetItemDefault)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvReceiveGenericFromISR .text.prvReceiveGenericFromISR)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvReturnItemByteBuf .text.prvReturnItemByteBuf)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvReturnItemDefault .text.prvReturnItemDefault)
 *libesp_ringbuf.a:ringbuf.*(.literal.prvSendItemDoneNoSplit .text.prvSendItemDoneNoSplit)
 *libesp_ringbuf.a:ringbuf.*(.literal.vRingbufferReturnItemFromISR .text.vRingbufferReturnItemFromISR)
 *libesp_ringbuf.a:ringbuf.*(.literal.xRingbufferReceiveFromISR .text.xRingbufferReceiveFromISR)
 *libesp_ringbuf.a:ringbuf.*(.literal.xRingbufferReceiveSplitFromISR .text.xRingbufferReceiveSplitFromISR)
 *libesp_ringbuf.a:ringbuf.*(.literal.xRingbufferReceiveUpToFromISR .text.xRingbufferReceiveUpToFromISR)
 *libesp_ringbuf.a:ringbuf.*(.literal.xRingbufferSendFromISR .text.xRingbufferSendFromISR)
 *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.*(.literal .literal.* .text .text.*)
 *libesp_rom.a:esp_rom_print.*(.literal .literal.* .text .text.*)
 *libesp_rom.a:esp_rom_spiflash.*(.literal .literal.* .text .text.*)
 *libesp_rom.a:esp_rom_sys.*(.literal .literal.* .text .text.*)
 *libesp_system.a:esp_err.*(.literal .literal.* .text .text.*)
 *libesp_system.a:esp_system_chip.*(.literal.esp_system_abort .text.esp_system_abort)
 *libesp_system.a:freertos_hooks.*(.literal.esp_vApplicationTickHook .text.esp_vApplicationTickHook)
 *libesp_system.a:image_process.*(.literal .literal.* .text .text.*)
 *libesp_system.a:panic.*(.literal.panic_abort .text.panic_abort)
 *libesp_system.a:reset_reason.*(.literal.esp_reset_reason_set_hint .text.esp_reset_reason_set_hint)
 *libesp_system.a:system_internal.*(.literal.esp_restart_noos .text.esp_restart_noos)
 *libesp_system.a:system_internal.*(.literal.esp_system_reset_modules_on_exit .text.esp_system_reset_modules_on_exit)
 *libesp_system.a:system_time.*(.literal.esp_system_get_time .text.esp_system_get_time)
 *libesp_system.a:system_time.*(.literal.esp_system_get_time_resolution .text.esp_system_get_time_resolution)
 *libesp_system.a:ubsan.*(.literal .literal.* .text .text.*)
 *libesp_timer.a:esp_timer_impl_common.*(.literal.esp_timer_impl_lock .text.esp_timer_impl_lock)
 *libesp_timer.a:esp_timer_impl_common.*(.literal.esp_timer_impl_unlock .text.esp_timer_impl_unlock)
 *libesp_timer.a:esp_timer_impl_systimer.*(.literal.esp_timer_impl_advance .text.esp_timer_impl_advance)
 *libesp_timer.a:esp_timer_impl_systimer.*(.literal.esp_timer_impl_set .text.esp_timer_impl_set)
 *libesp_wifi.a:esp_adapter.*(.literal.coex_pti_get_wrapper .text.coex_pti_get_wrapper)
 *libesp_wifi.a:esp_adapter.*(.literal.wifi_clock_disable_wrapper .text.wifi_clock_disable_wrapper)
 *libesp_wifi.a:esp_adapter.*(.literal.wifi_clock_enable_wrapper .text.wifi_clock_enable_wrapper)
 *libesp_wifi.a:wifi_netif.*(.literal.wifi_sta_receive .text.wifi_sta_receive)
 *libesp_wifi.a:wifi_netif.*(.literal.wifi_transmit_wrap .text.wifi_transmit_wrap)
 *libfreertos.a:event_groups.*(.literal.xEventGroupGetBitsFromISR .text.xEventGroupGetBitsFromISR)
 *libfreertos.a:list.*(.literal.uxListRemove .text.uxListRemove)
 *libfreertos.a:list.*(.literal.vListInsertEnd .text.vListInsertEnd)
 *libfreertos.a:port.*(.literal.vPortAssertIfInISR .text.vPortAssertIfInISR)
 *libfreertos.a:port.*(.literal.vPortClearInterruptMaskFromISR .text.vPortClearInterruptMaskFromISR)
 *libfreertos.a:port.*(.literal.vPortCoprocUsedInISR .text.vPortCoprocUsedInISR)
 *libfreertos.a:port.*(.literal.vPortEnterCritical .text.vPortEnterCritical)
 *libfreertos.a:port.*(.literal.vPortExitCritical .text.vPortExitCritical)
 *libfreertos.a:port.*(.literal.vPortExitCriticalMultiCore .text.vPortExitCriticalMultiCore)
 *libfreertos.a:port.*(.literal.vPortSetStackWatchpoint .text.vPortSetStackWatchpoint)
 *libfreertos.a:port.*(.literal.vPortYield .text.vPortYield)
 *libfreertos.a:port.*(.literal.vPortYieldFromISR .text.vPortYieldFromISR)
 *libfreertos.a:port.*(.literal.vPortYieldOtherCore .text.vPortYieldOtherCore)
 *libfreertos.a:port.*(.literal.xPortEnterCriticalTimeout .text.xPortEnterCriticalTimeout)
 *libfreertos.a:port.*(.literal.xPortFPUContextIsDirty .text.xPortFPUContextIsDirty)
 *libfreertos.a:port.*(.literal.xPortInIsrContext .text.xPortInIsrContext)
 *libfreertos.a:port.*(.literal.xPortInterruptedFromISRContext .text.xPortInterruptedFromISRContext)
 *libfreertos.a:port.*(.literal.xPortSetInterruptMaskFromISR .text.xPortSetInterruptMaskFromISR)
 *libfreertos.a:port_systick.*(.text .text.SysTickIsrHandler .text.xPortSysTickClaimElapsedTicks .text.xPortSysTickHandler)
 *libfreertos.a:portasm.*(.literal .literal.* .text .text.*)
 *libfreertos.a:queue.*(.literal.prvCopyDataFromQueue .text.prvCopyDataFromQueue)
 *libfreertos.a:queue.*(.literal.prvCopyDataToQueue .text.prvCopyDataToQueue)
 *libfreertos.a:queue.*(.literal.prvNotifyQueueSetContainer .text.prvNotifyQueueSetContainer)
 *libfreertos.a:queue.*(.literal.uxQueueMessagesWaitingFromISR .text.uxQueueMessagesWaitingFromISR)
 *libfreertos.a:queue.*(.literal.xQueueGenericSendFromISR .text.xQueueGenericSendFromISR)
 *libfreertos.a:queue.*(.literal.xQueueGetMutexHolderFromISR .text.xQueueGetMutexHolderFromISR)
 *libfreertos.a:queue.*(.literal.xQueueGiveFromISR .text.xQueueGiveFromISR)
 *libfreertos.a:queue.*(.literal.xQueueIsQueueEmptyFromISR .text.xQueueIsQueueEmptyFromISR)
 *libfreertos.a:queue.*(.literal.xQueueIsQueueFullFromISR .text.xQueueIsQueueFullFromISR)
 *libfreertos.a:queue.*(.literal.xQueuePeekFromISR .text.xQueuePeekFromISR)
 *libfreertos.a:queue.*(.literal.xQueueReceiveFromISR .text.xQueueReceiveFromISR)
 *libfreertos.a:queue.*(.literal.xQueueSelectFromSetFromISR .text.xQueueSelectFromSetFromISR)
 *libfreertos.a:stream_buffer.*(.literal.prvBytesInBuffer .text.prvBytesInBuffer)
 *libfreertos.a:stream_buffer.*(.literal.prvReadMessageFromBuffer .text.prvReadMessageFromBuffer)
 *libfreertos.a:stream_buffer.*(.literal.prvWriteMessageToBuffer .text.prvWriteMessageToBuffer)
 *libfreertos.a:stream_buffer.*(.literal.xStreamBufferReceiveCompletedFromISR .text.xStreamBufferReceiveCompletedFromISR)
 *libfreertos.a:stream_buffer.*(.literal.xStreamBufferReceiveFromISR .text.xStreamBufferReceiveFromISR)
 *libfreertos.a:stream_buffer.*(.literal.xStreamBufferSendCompletedFromISR .text.xStreamBufferSendCompletedFromISR)
 *libfreertos.a:stream_buffer.*(.literal.xStreamBufferSendFromISR .text.xStreamBufferSendFromISR)
 *libfreertos.a:tasks.*(.literal.prvCheckTaskCanBeScheduledSMP .text.prvCheckTaskCanBeScheduledSMP)
 *libfreertos.a:tasks.*(.literal.prvIsYieldRequiredSMP .text.prvIsYieldRequiredSMP)
 *libfreertos.a:tasks.*(.literal.prvResetNextTaskUnblockTime .text.prvResetNextTaskUnblockTime)
 *libfreertos.a:tasks.*(.literal.prvSelectHighestPriorityTaskSMP .text.prvSelectHighestPriorityTaskSMP)
 *libfreertos.a:tasks.*(.literal.prvTaskIsTaskSuspended .text.prvTaskIsTaskSuspended)
 *libfreertos.a:tasks.*(.literal.uxTaskPriorityGetFromISR .text.uxTaskPriorityGetFromISR)
 *libfreertos.a:tasks.*(.literal.vTaskGenericNotifyGiveFromISR .text.vTaskGenericNotifyGiveFromISR)
 *libfreertos.a:tasks.*(.literal.vTaskGetSnapshot .text.vTaskGetSnapshot)
 *libfreertos.a:tasks.*(.literal.vTaskSwitchContext .text.vTaskSwitchContext)
 *libfreertos.a:tasks.*(.literal.xTaskGenericNotifyFromISR .text.xTaskGenericNotifyFromISR)
 *libfreertos.a:tasks.*(.literal.xTaskGetSchedulerState .text.xTaskGetSchedulerState)
 *libfreertos.a:tasks.*(.literal.xTaskGetTickCount .text.xTaskGetTickCount)
 *libfreertos.a:tasks.*(.literal.xTaskGetTickCountFromISR .text.xTaskGetTickCountFromISR)
 *libfreertos.a:tasks.*(.literal.xTaskIncrementTick .text.xTaskIncrementTick)
 *libfreertos.a:tasks.*(.literal.xTaskIncrementTickOtherCores .text.xTaskIncrementTickOtherCores)
 *libfreertos.a:tasks.*(.literal.xTaskRemoveFromEventList .text.xTaskRemoveFromEventList)
 *libfreertos.a:tasks.*(.literal.xTaskResumeFromISR .text.xTaskResumeFromISR)
 *libfreertos.a:timers.*(.literal.xTimerGenericCommand .text.xTimerGenericCommand)
 *libfreertos.a:timers.*(.literal.xTimerPendFunctionCallFromISR .text.xTimerPendFunctionCallFromISR)
 *libgcc.a:_divsf3.*(.literal .literal.* .text .text.*)
 *libgcc.a:lib2funcs.*(.literal .literal.* .text .text.*)
 *libgcc.a:save-restore.*(.literal .literal.* .text .text.*)
 *libgcov.a:(.literal .literal.* .text .text.*)
 *libhal.a:cache_hal.*(.literal .literal.* .text .text.*)
 *libhal.a:mmu_hal.*(.literal .literal.* .text .text.*)
 *libheap.a:multi_heap.*(.literal._multi_heap_lock .text._multi_heap_lock)
 *libheap.a:multi_heap.*(.literal._multi_heap_unlock .text._multi_heap_unlock)
 *libheap.a:multi_heap.*(.literal.multi_heap_aligned_alloc_offs .text.multi_heap_aligned_alloc_offs)
 *libheap.a:multi_heap.*(.literal.multi_heap_get_full_block_size .text.multi_heap_get_full_block_size)
 *libheap.a:multi_heap.*(.literal.multi_heap_in_rom_init .text.multi_heap_in_rom_init)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_enh_ack_generator .text.esp_ieee802154_enh_ack_generator)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_get_extended_address .text.esp_ieee802154_get_extended_address)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_get_recent_lqi .text.esp_ieee802154_get_recent_lqi)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_get_recent_rssi .text.esp_ieee802154_get_recent_rssi)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_receive .text.esp_ieee802154_receive)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_receive_at .text.esp_ieee802154_receive_at)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_set_transmit_security .text.esp_ieee802154_set_transmit_security)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_transmit .text.esp_ieee802154_transmit)
 *libieee802154.a:esp_ieee802154.*(.literal.esp_ieee802154_transmit_at .text.esp_ieee802154_transmit_at)
 *libieee802154.a:esp_ieee802154_ack.*(.literal.ieee802154_ack_config_pending_bit .text.ieee802154_ack_config_pending_bit)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_finish_receive_at .text.ieee802154_finish_receive_at)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_get_recent_lqi .text.ieee802154_get_recent_lqi)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_get_recent_rssi .text.ieee802154_get_recent_rssi)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_isr .text.ieee802154_isr)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_receive .text.ieee802154_receive)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_receive_at .text.ieee802154_receive_at)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_rx_frame_info_update .text.ieee802154_rx_frame_info_update)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_start_receive_at .text.ieee802154_start_receive_at)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_transmit .text.ieee802154_transmit)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.ieee802154_transmit_at .text.ieee802154_transmit_at)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.set_next_rx_buffer .text.set_next_rx_buffer)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_cca .text.stop_cca)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_current_operation .text.stop_current_operation)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_ed .text.stop_ed)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_rx .text.stop_rx)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_rx_ack .text.stop_rx_ack)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_tx .text.stop_tx)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_tx_ack .text.stop_tx_ack)
 *libieee802154.a:esp_ieee802154_dev.*(.literal.stop_tx_cca .text.stop_tx_cca)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_energy_detect_done .text.ieee802154_inner_energy_detect_done)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_enh_ack_generator .text.ieee802154_inner_enh_ack_generator)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_receive_done .text.ieee802154_inner_receive_done)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_receive_sfd_done .text.ieee802154_inner_receive_sfd_done)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_transmit_done .text.ieee802154_inner_transmit_done)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_transmit_failed .text.ieee802154_inner_transmit_failed)
 *libieee802154.a:esp_ieee802154_event.*(.literal.ieee802154_inner_transmit_sfd_done .text.ieee802154_inner_transmit_sfd_done)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_get_dest_panid .text.ieee802154_frame_get_dest_panid)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_get_dst_addr .text.ieee802154_frame_get_dst_addr)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_get_security_field_len .text.ieee802154_frame_get_security_field_len)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_get_security_payload_offset .text.ieee802154_frame_get_security_payload_offset)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_get_src_addr .text.ieee802154_frame_get_src_addr)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_get_src_panid .text.ieee802154_frame_get_src_panid)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_is_security_enabled .text.ieee802154_frame_is_security_enabled)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_frame_security_header_offset .text.ieee802154_frame_security_header_offset)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.ieee802154_is_data_request .text.ieee802154_is_data_request)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.is_dst_panid_present .text.is_dst_panid_present)
 *libieee802154.a:esp_ieee802154_frame.*(.literal.is_src_panid_present .text.is_src_panid_present)
 *libieee802154.a:esp_ieee802154_pib.*(.literal.ieee802154_pib_get_pending_mode .text.ieee802154_pib_get_pending_mode)
 *libieee802154.a:esp_ieee802154_pib.*(.literal.ieee802154_pib_get_rx_when_idle .text.ieee802154_pib_get_rx_when_idle)
 *libieee802154.a:esp_ieee802154_pib.*(.literal.ieee802154_pib_update .text.ieee802154_pib_update)
 *libieee802154.a:esp_ieee802154_pib.*(.literal.ieee802154_txpower_convert .text.ieee802154_txpower_convert)
 *libieee802154.a:esp_ieee802154_sec.*(.literal.ieee802154_sec_clear .text.ieee802154_sec_clear)
 *libieee802154.a:esp_ieee802154_sec.*(.literal.ieee802154_transmit_security_config .text.ieee802154_transmit_security_config)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer0_fire_at .text.ieee802154_timer0_fire_at)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer0_fire_at_with_callback .text.ieee802154_timer0_fire_at_with_callback)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer0_set_callback .text.ieee802154_timer0_set_callback)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer0_set_threshold .text.ieee802154_timer0_set_threshold)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer0_start .text.ieee802154_timer0_start)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer0_stop .text.ieee802154_timer0_stop)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer1_fire_at .text.ieee802154_timer1_fire_at)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer1_fire_at_with_callback .text.ieee802154_timer1_fire_at_with_callback)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer1_set_callback .text.ieee802154_timer1_set_callback)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer1_set_threshold .text.ieee802154_timer1_set_threshold)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer1_start .text.ieee802154_timer1_start)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.ieee802154_timer1_stop .text.ieee802154_timer1_stop)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.isr_handle_timer0_done .text.isr_handle_timer0_done)
 *libieee802154.a:esp_ieee802154_timer.*(.literal.isr_handle_timer1_done .text.isr_handle_timer1_done)
 *libieee802154.a:esp_ieee802154_util.*(.literal.ieee802154_channel_to_freq .text.ieee802154_channel_to_freq)
 *libieee802154.a:esp_ieee802154_util.*(.literal.ieee802154_etm_channel_clear .text.ieee802154_etm_channel_clear)
 *liblog.a:log.*(.literal .literal.* .text .text.*)
 *liblog.a:log_format_text.*(.literal .literal.* .text .text.*)
 *liblog.a:log_lock.*(.literal .literal.* .text .text.*)
 *liblog.a:log_print.*(.literal .literal.* .text .text.*)
 *liblog.a:log_timestamp.*(.literal.esp_log_early_timestamp .text.esp_log_early_timestamp)
 *liblog.a:log_timestamp.*(.literal.esp_log_timestamp .text.esp_log_timestamp)
 *liblog.a:log_timestamp_common.*(.literal .literal.* .text .text.*)
 *liblog.a:log_write.*(.literal.esp_log_write .text.esp_log_write)
 *liblog.a:log_write.*(.literal.esp_log_writev .text.esp_log_writev)
 *liblog.a:tag_log_level.*(.literal.esp_log_level_get_timeout .text.esp_log_level_get_timeout)
 *liblog.a:util.*(.literal .literal.* .text .text.*)
 *libnet80211.a:(.wifi0iram .wifi0iram.*)
 *libnet80211.a:(.wifiextrairam .wifiextrairam.*)
 *libnet80211.a:(.wifirxiram .wifirxiram.*)
 *libnet80211.a:(.wifislpiram .wifislpiram.*)
 *libnet80211.a:(.wifislprxiram .wifislprxiram.*)
 *libpp.a:(.wifi0iram .wifi0iram.*)
 *libpp.a:(.wifiextrairam .wifiextrairam.*)
 *libpp.a:(.wifiorslpiram .wifiorslpiram.*)
 *libpp.a:(.wifirxiram .wifirxiram.*)
 *libpp.a:(.wifislpiram .wifislpiram.*)
 *libpp.a:(.wifislprxiram .wifislprxiram.*)
 *libriscv.a:interrupt.*(.text .text._global_interrupt_handler .text.intr_get_item .text.intr_handler_get_arg)
 *libriscv.a:rv_utils.*(.literal .literal.* .text .text.*)
 *libriscv.a:vectors.*(.literal .literal.* .text .text.*)
 *librtc.a:(.literal .literal.* .text .text.*)
 *libsoc.a:lldesc.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:esp_flash_api.*(.literal.check_chip_pointer_default .text.check_chip_pointer_default)
 *libspi_flash.a:esp_flash_api.*(.literal.detect_spi_flash_chip .text.detect_spi_flash_chip)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_chip_driver_initialized .text.esp_flash_chip_driver_initialized)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_erase_chip .text.esp_flash_erase_chip)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_erase_region .text.esp_flash_erase_region)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_get_chip_write_protect .text.esp_flash_get_chip_write_protect)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_get_io_mode .text.esp_flash_get_io_mode)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_get_physical_size .text.esp_flash_get_physical_size)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_get_protected_region .text.esp_flash_get_protected_region)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_get_size .text.esp_flash_get_size)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_init .text.esp_flash_init)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_init_main .text.esp_flash_init_main)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_is_quad_mode .text.esp_flash_is_quad_mode)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_read .text.esp_flash_read)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_read_encrypted .text.esp_flash_read_encrypted)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_set_chip_write_protect .text.esp_flash_set_chip_write_protect)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_set_io_mode .text.esp_flash_set_io_mode)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_set_protected_region .text.esp_flash_set_protected_region)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_write .text.esp_flash_write)
 *libspi_flash.a:esp_flash_api.*(.literal.esp_flash_write_encrypted .text.esp_flash_write_encrypted)
 *libspi_flash.a:esp_flash_api.*(.literal.flash_end_flush_cache .text.flash_end_flush_cache)
 *libspi_flash.a:esp_flash_api.*(.literal.read_unique_id .text.read_unique_id)
 *libspi_flash.a:esp_flash_api.*(.literal.spiflash_end_default .text.spiflash_end_default)
 *libspi_flash.a:esp_flash_api.*(.literal.spiflash_start_core .text.spiflash_start_core)
 *libspi_flash.a:esp_flash_api.*(.literal.spiflash_start_prog .text.spiflash_start_prog)
 *libspi_flash.a:esp_flash_api.*(.literal.spiflash_start_read .text.spiflash_start_read)
 *libspi_flash.a:flash_brownout_hook.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:flash_ops.*(.literal.esp_mspi_get_io .text.esp_mspi_get_io)
 *libspi_flash.a:memspi_host_driver.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_boya.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_gd.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_generic.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_issi.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_mxic.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_th.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_chip_winbond.*(.literal .literal.* .text .text.*)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.delay_us .text.delay_us)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.get_buffer_malloc .text.get_buffer_malloc)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.main_flash_op_status .text.main_flash_op_status)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.main_flash_region_protected .text.main_flash_region_protected)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.release_buffer_malloc .text.release_buffer_malloc)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.spi23_end .text.spi23_end)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.spi23_start .text.spi23_start)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.spi_flash_os_check_yield .text.spi_flash_os_check_yield)
 *libspi_flash.a:spi_flash_os_func_app.*(.literal.spi_flash_os_yield .text.spi_flash_os_yield)
 *libspi_flash.a:spi_flash_os_func_noos.*(.literal.delay_us .text.delay_us)
 *libspi_flash.a:spi_flash_os_func_noos.*(.literal.esp_flash_app_disable_os_functions .text.esp_flash_app_disable_os_functions)
 *libspi_flash.a:spi_flash_os_func_noos.*(.literal.get_temp_buffer_not_supported .text.get_temp_buffer_not_supported)
 *libspi_flash.a:spi_flash_wrap.*(.literal .literal.* .text .text.*)

  } > iram_text_seg
  /* Marks the end of IRAM code segment */
  .iram0.text_end (NOLOAD) :
  {
    /* Padding for possible CPU prefetch + alignment for PMS split lines */
    . += 0;
    . = ALIGN(0);
    /* Align the end of code region as per PMP region granularity */
    . = ALIGN(128);
    /* iram_end_test section exists for use by memprot unit tests only */
    *(.iram_end_test)
    
 . = ALIGN(4); 
 _iram_text_end = ABSOLUTE(.);
  } > iram_text_seg
 .iram0.data :
  {
    
 . = ALIGN(16); 
 _iram_data_start = ABSOLUTE(.);
    
 *(.iram.data .iram.data.*)
    _iram_data_end = ABSOLUTE(.);
  } > iram_text_seg
  .iram0.bss (NOLOAD) :
  {
    
 . = ALIGN(16); 
 _iram_bss_start = ABSOLUTE(.);
    
 
 *(.iram.bss .iram.bss.*)

    _iram_bss_end = ABSOLUTE(.);
  } > iram_text_seg
  .iram0.end (NOLOAD) :
  {
    
 . = ALIGN(16); 
 _iram_end = ABSOLUTE(.);
  } > iram_text_seg
ASSERT(((_iram_end - ORIGIN(iram_text_seg)) <= LENGTH(iram_text_seg)),
          "IRAM0 segment data does not fit.")
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  .dram0.dummy (NOLOAD) :
  {
    /**
     * Reserve DRAM space for shared D/IRAM memory configuration.
     *
     * On certain ESP chips, the same physical SRAM is accessible via two
     * different virtual address ranges:
     *   - IRAM: 0x4xxxxxxx
     *   - DRAM: 0x3Fxxxxxx
     *
     * While the virtual addresses differ, both ranges map to the same physical
     * memory.
     *
     * When `_iram_dram_shared` is defined, it indicates this configuration exists.
     * We must advance the DRAM location counter past the region used by IRAM code
     * to prevent DRAM data from physically overwriting executable IRAM code.
     */
    . = DEFINED(_iram_dram_shared) ? ORIGIN(dram_seg) + (_iram_end - _iram_start) : .;
  } > dram_seg
  .dram0.data_start :
  {
    _data_start = .;
  } > dram_seg
  .dram0.data :
  {
    *(.gnu.linkonce.d.*)
    *(.data1)
    __global_pointer$ = . + 0x800;
    *(.sdata)
    *(.sdata.*)
    *(.gnu.linkonce.s.*)
    *(.gnu.linkonce.s2.*)
    *(.jcr)
    
 
 *(.data .data.*)
 *(.dram1 .dram1.*)
 *libclang_rt.builtins.a:_divsf3.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libclang_rt.builtins.a:restore.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libclang_rt.builtins.a:save.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_driver_dma.a:dma2d.*(.rodata._dma2d_default_rx_isr .rodata._dma2d_default_rx_isr.str1.4 .sdata2._dma2d_default_rx_isr .srodata._dma2d_default_rx_isr)
 *libesp_driver_dma.a:dma2d.*(.rodata.free_up_channels .rodata.free_up_channels.str1.4 .sdata2.free_up_channels .srodata.free_up_channels)
 *libesp_driver_dma.a:esp_dma_utils.*(.rodata.esp_dma_split_rx_buffer_to_cache_aligned .rodata.esp_dma_split_rx_buffer_to_cache_aligned.str1.4 .sdata2.esp_dma_split_rx_buffer_to_cache_aligned .srodata.esp_dma_split_rx_buffer_to_cache_aligned)
 *libesp_driver_dma.a:gdma_link.*(.rodata.gdma_link_mount_buffers .rodata.gdma_link_mount_buffers.str1.4 .sdata2.gdma_link_mount_buffers .srodata.gdma_link_mount_buffers)
 *libesp_driver_parlio.a:parlio_rx.*(.rodata.parlio_rx_default_desc_done_callback .rodata.parlio_rx_default_desc_done_callback.str1.4 .sdata2.parlio_rx_default_desc_done_callback .srodata.parlio_rx_default_desc_done_callback)
 *libesp_driver_parlio.a:parlio_rx.*(.rodata.parlio_rx_unit_trigger_fake_eof .rodata.parlio_rx_unit_trigger_fake_eof.str1.4 .sdata2.parlio_rx_unit_trigger_fake_eof .srodata.parlio_rx_unit_trigger_fake_eof)
 *libesp_driver_parlio.a:parlio_tx.*(.rodata.parlio_tx_default_isr .rodata.parlio_tx_default_isr.str1.4 .sdata2.parlio_tx_default_isr .srodata.parlio_tx_default_isr)
 *libesp_driver_rmt.a:rmt_tx.*(.rodata.rmt_isr_handle_tx_done .rodata.rmt_isr_handle_tx_done.str1.4 .sdata2.rmt_isr_handle_tx_done .srodata.rmt_isr_handle_tx_done)
 *libesp_driver_rmt.a:rmt_tx.*(.rodata.rmt_tx_do_transaction .rodata.rmt_tx_do_transaction.str1.4 .sdata2.rmt_tx_do_transaction .srodata.rmt_tx_do_transaction)
 *libesp_hal_ana_conv.a:temperature_sensor_periph.*(.rodata.temperature_sensor_attributes .sdata2.temperature_sensor_attributes .srodata.temperature_sensor_attributes)
 *libesp_hal_gpspi.a:spi_hal_iram.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_gpspi.a:spi_slave_hal_iram.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_i2c.a:i2c_hal_iram.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_ledc.a:ledc_hal_iram.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_mspi.a:spi_flash_hal_gpspi.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_mspi.a:spi_flash_hal_iram.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_parlio.a:parlio_periph.*(.rodata.soc_parlio_signals .sdata2.soc_parlio_signals .srodata.soc_parlio_signals)
 *libesp_hal_pmu.a:pmu_hal.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_regi2c.a:(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_systimer.a:(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hal_wdt.a:rom_patch.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:adc_share_hw_ctrl.*(.rodata.adc_apb_periph_free .rodata.adc_apb_periph_free.str1.4 .sdata2.adc_apb_periph_free .srodata.adc_apb_periph_free)
 *libesp_hw_support.a:clk_utils.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:cpu.*(.rodata.esp_cpu_stall .rodata.esp_cpu_stall.str1.4 .sdata2.esp_cpu_stall .srodata.esp_cpu_stall)
 *libesp_hw_support.a:esp_clk_tree.*(.rodata.esp_clk_tree_enable_src .rodata.esp_clk_tree_enable_src.str1.4 .sdata2.esp_clk_tree_enable_src .srodata.esp_clk_tree_enable_src)
 *libesp_hw_support.a:esp_clk_tree_common.*(.rodata.esp_clk_tree_apll_release .rodata.esp_clk_tree_apll_release.str1.4 .sdata2.esp_clk_tree_apll_release .srodata.esp_clk_tree_apll_release)
 *libesp_hw_support.a:esp_clk_tree_common.*(.rodata.esp_clk_tree_mpll_release .rodata.esp_clk_tree_mpll_release.str1.4 .sdata2.esp_clk_tree_mpll_release .srodata.esp_clk_tree_mpll_release)
 *libesp_hw_support.a:esp_gpio_reserve.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:esp_memory_utils.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:mspi_timing_by_dqs.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:mspi_timing_config.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:mspi_timing_tuning.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:pmu_sleep.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:regi2c_ctrl.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:rtc_clk.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:sar_periph_ctrl_common.*(.rodata.regi2c_saradc_disable .rodata.regi2c_saradc_disable.str1.4 .sdata2.regi2c_saradc_disable .srodata.regi2c_saradc_disable)
 *libesp_hw_support.a:sar_tsens_ctrl.*(.rodata.temperature_sensor_power_release .rodata.temperature_sensor_power_release.str1.4 .sdata2.temperature_sensor_power_release .srodata.temperature_sensor_power_release)
 *libesp_hw_support.a:sleep_cache.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:sleep_console.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:sleep_modes.*(.rodata.esp_sleep_enable_timer_wakeup .rodata.esp_sleep_enable_timer_wakeup.str1.4 .sdata2.esp_sleep_enable_timer_wakeup .srodata.esp_sleep_enable_timer_wakeup)
 *libesp_hw_support.a:sleep_mspi.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:sleep_usb.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_hw_support.a:systimer.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_libc.a:abort.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_libc.a:assert.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_libc.a:heap.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_libc.a:stdatomic.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_mm.a:esp_cache_msync.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_mm.a:esp_cache_utils.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_phy.a:phy_init.*(.rodata.esp_phy_enable .rodata.esp_phy_enable.str1.4 .sdata2.esp_phy_enable .srodata.esp_phy_enable)
 *libesp_psram.a:esp_psram_impl_ap_oct.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_rom.a:esp_rom_print.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_rom.a:esp_rom_spiflash.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_rom.a:esp_rom_sys.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_system.a:esp_err.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_system.a:image_process.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libesp_system.a:reset_reason.*(.rodata.esp_reset_reason_set_hint .rodata.esp_reset_reason_set_hint.str1.4 .sdata2.esp_reset_reason_set_hint .srodata.esp_reset_reason_set_hint)
 *libesp_system.a:system_internal.*(.rodata.esp_system_reset_modules_on_exit .rodata.esp_system_reset_modules_on_exit.str1.4 .sdata2.esp_system_reset_modules_on_exit .srodata.esp_system_reset_modules_on_exit)
 *libesp_system.a:ubsan.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libgcc.a:_divsf3.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libgcc.a:save-restore.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libgcov.a:(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libhal.a:cache_hal.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libhal.a:mmu_hal.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libieee802154.a:esp_ieee802154.*(.rodata.esp_ieee802154_enh_ack_generator .rodata.esp_ieee802154_enh_ack_generator.str1.4 .sdata2.esp_ieee802154_enh_ack_generator .srodata.esp_ieee802154_enh_ack_generator)
 *libieee802154.a:esp_ieee802154.*(.rodata.esp_ieee802154_get_extended_address .rodata.esp_ieee802154_get_extended_address.str1.4 .sdata2.esp_ieee802154_get_extended_address .srodata.esp_ieee802154_get_extended_address)
 *libieee802154.a:esp_ieee802154.*(.rodata.esp_ieee802154_set_transmit_security .rodata.esp_ieee802154_set_transmit_security.str1.4 .sdata2.esp_ieee802154_set_transmit_security .srodata.esp_ieee802154_set_transmit_security)
 *libieee802154.a:esp_ieee802154.*(.rodata.esp_ieee802154_transmit .rodata.esp_ieee802154_transmit.str1.4 .sdata2.esp_ieee802154_transmit .srodata.esp_ieee802154_transmit)
 *libieee802154.a:esp_ieee802154_ack.*(.rodata.ieee802154_ack_config_pending_bit .rodata.ieee802154_ack_config_pending_bit.str1.4 .sdata2.ieee802154_ack_config_pending_bit .srodata.ieee802154_ack_config_pending_bit)
 *libieee802154.a:esp_ieee802154_dev.*(.rodata.ieee802154_isr .rodata.ieee802154_isr.str1.4 .sdata2.ieee802154_isr .srodata.ieee802154_isr)
 *libieee802154.a:esp_ieee802154_frame.*(.rodata.ieee802154_frame_get_dst_addr .rodata.ieee802154_frame_get_dst_addr.str1.4 .sdata2.ieee802154_frame_get_dst_addr .srodata.ieee802154_frame_get_dst_addr)
 *libieee802154.a:esp_ieee802154_frame.*(.rodata.ieee802154_frame_get_security_field_len .rodata.ieee802154_frame_get_security_field_len.str1.4 .sdata2.ieee802154_frame_get_security_field_len .srodata.ieee802154_frame_get_security_field_len)
 *libieee802154.a:esp_ieee802154_sec.*(.rodata.ieee802154_transmit_security_config .rodata.ieee802154_transmit_security_config.str1.4 .sdata2.ieee802154_transmit_security_config .srodata.ieee802154_transmit_security_config)
 *libieee802154.a:esp_ieee802154_util.*(.rodata.ieee802154_etm_channel_clear .rodata.ieee802154_etm_channel_clear.str1.4 .sdata2.ieee802154_etm_channel_clear .srodata.ieee802154_etm_channel_clear)
 *liblog.a:log.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *liblog.a:log_format_text.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *liblog.a:log_lock.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *liblog.a:log_print.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *liblog.a:log_timestamp_common.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *liblog.a:util.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libphy.a:(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libsoc.a:lldesc.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:flash_brownout_hook.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:flash_ops.*(.rodata.esp_mspi_get_io .rodata.esp_mspi_get_io.str1.4 .sdata2.esp_mspi_get_io .srodata.esp_mspi_get_io)
 *libspi_flash.a:flash_ops.*(.rodata.s_mspi_io_num_default .sdata2.s_mspi_io_num_default .srodata.s_mspi_io_num_default)
 *libspi_flash.a:memspi_host_driver.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_boya.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_gd.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_generic.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_issi.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_mxic.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_th.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_chip_winbond.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)
 *libspi_flash.a:spi_flash_os_func_app.*(.rodata.spi_flash_os_check_yield .rodata.spi_flash_os_check_yield.str1.4 .sdata2.spi_flash_os_check_yield .srodata.spi_flash_os_check_yield)
 *libspi_flash.a:spi_flash_wrap.*(.rodata .rodata.* .sdata2 .sdata2.* .srodata .srodata.*)

    _data_end = ABSOLUTE(.);
  } > dram_seg
  /**
   * This section holds data that should not be initialized at power up.
   * The section is located in Internal SRAM memory region. The macro _NOINIT
   * can be used as attribute to place data into this section.
   * See the "esp_attr.h" file for more information.
   */
  .noinit (NOLOAD) :
  {
    
 . = ALIGN(4); 
 _noinit_start = ABSOLUTE(.);
    
    *(.noinit .noinit.*)
    
 . = ALIGN(4); 
 _noinit_end = ABSOLUTE(.);
  } > dram_seg
  /* Shared RAM */
  .dram0.bss (NOLOAD) :
  {
    
 . = ALIGN(8); 
 _bss_start = ABSOLUTE(.);
    
 *(.bss .bss.*)
 *(.dynbss .dynsbss .gnu.linkonce.b .gnu.linkonce.b.* .gnu.linkonce.sb .gnu.linkonce.sb.* .gnu.linkonce.sb2 .gnu.linkonce.sb2.* .sbss .sbss.* .sbss2 .sbss2.* .scommon .share.mem)
 *(.ext_ram.bss .ext_ram.bss.*)
 *(COMMON)
    
 . = ALIGN(8); 
 _bss_end = ABSOLUTE(.);
  } > dram_seg
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  .flash.text :
  {
    _stext = .;
    /**
     * Mark the start of flash.text.
     * This can be used by the MMU driver to maintain the virtual address.
     */
    _instruction_reserved_start = ABSOLUTE(.);
    _text_start = ABSOLUTE(.);
    
 
 *(EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *librtc.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_ana_cmpr.a:ana_cmpr.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_gptimer.a:gptimer.* *libesp_driver_i2c.a:i2c_master.* *libesp_driver_mcpwm.a:mcpwm_cap.* *libesp_driver_mcpwm.a:mcpwm_cmpr.* *libesp_driver_mcpwm.a:mcpwm_fault.* *libesp_driver_mcpwm.a:mcpwm_oper.* *libesp_driver_mcpwm.a:mcpwm_timer.* *libesp_driver_parlio.a:parlio_common.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_encoder.* *libesp_driver_rmt.a:rmt_rx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_event.a:default_event_loop.* *libesp_event.a:esp_event.* *libesp_hal_ana_conv.a:temperature_sensor_hal.* *libesp_hal_dma.a:gdma_hal_ahb_v2.* *libesp_hal_dma.a:gdma_hal_axi.* *libesp_hal_dma.a:gdma_hal_top.* *libesp_hal_gpio.a:gpio_hal.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_timg.a:timer_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:periph_ctrl.* *libesp_hw_support.a:peripheral_domain_pd.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:rtc_time.* *libesp_hw_support.a:sar_periph_ctrl.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_clock.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_cpu.* *libesp_hw_support.a:sleep_modem.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:esp_time_impl.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_phy.a:phy_override.* *libesp_pm.a:pm_impl.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_ringbuf.a:ringbuf.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:esp_system_chip.* *libesp_system.a:freertos_hooks.* *libesp_system.a:image_process.* *libesp_system.a:panic.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:system_time.* *libesp_system.a:ubsan.* *libesp_timer.a:esp_timer_impl_common.* *libesp_timer.a:esp_timer_impl_systimer.* *libesp_wifi.a:esp_adapter.* *libesp_wifi.a:wifi_netif.* *libfreertos.a:event_groups.* *libfreertos.a:list.* *libfreertos.a:port.* *libfreertos.a:port_systick.* *libfreertos.a:portasm.* *libfreertos.a:queue.* *libfreertos.a:stream_buffer.* *libfreertos.a:tasks.* *libfreertos.a:timers.* *libgcc.a:_divsf3.* *libgcc.a:lib2funcs.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libheap.a:multi_heap.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_event.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_pib.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_timer.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp.* *liblog.a:log_timestamp_common.* *liblog.a:log_write.* *liblog.a:tag_log_level.* *liblog.a:util.* *libriscv.a:interrupt.* *libriscv.a:rv_utils.* *libriscv.a:vectors.* *libsoc.a:lldesc.* *libspi_flash.a:esp_flash_api.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_os_func_noos.* *libspi_flash.a:spi_flash_wrap.*) .literal EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *librtc.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_ana_cmpr.a:ana_cmpr.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_gptimer.a:gptimer.* *libesp_driver_i2c.a:i2c_master.* *libesp_driver_mcpwm.a:mcpwm_cap.* *libesp_driver_mcpwm.a:mcpwm_cmpr.* *libesp_driver_mcpwm.a:mcpwm_fault.* *libesp_driver_mcpwm.a:mcpwm_oper.* *libesp_driver_mcpwm.a:mcpwm_timer.* *libesp_driver_parlio.a:parlio_common.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_encoder.* *libesp_driver_rmt.a:rmt_rx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_event.a:default_event_loop.* *libesp_event.a:esp_event.* *libesp_hal_ana_conv.a:temperature_sensor_hal.* *libesp_hal_dma.a:gdma_hal_ahb_v2.* *libesp_hal_dma.a:gdma_hal_axi.* *libesp_hal_dma.a:gdma_hal_top.* *libesp_hal_gpio.a:gpio_hal.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_timg.a:timer_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:periph_ctrl.* *libesp_hw_support.a:peripheral_domain_pd.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:rtc_time.* *libesp_hw_support.a:sar_periph_ctrl.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_clock.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_cpu.* *libesp_hw_support.a:sleep_modem.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:esp_time_impl.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_phy.a:phy_override.* *libesp_pm.a:pm_impl.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_ringbuf.a:ringbuf.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:esp_system_chip.* *libesp_system.a:freertos_hooks.* *libesp_system.a:image_process.* *libesp_system.a:panic.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:system_time.* *libesp_system.a:ubsan.* *libesp_timer.a:esp_timer_impl_common.* *libesp_timer.a:esp_timer_impl_systimer.* *libesp_wifi.a:esp_adapter.* *libesp_wifi.a:wifi_netif.* *libfreertos.a:event_groups.* *libfreertos.a:list.* *libfreertos.a:port.* *libfreertos.a:port_systick.* *libfreertos.a:portasm.* *libfreertos.a:queue.* *libfreertos.a:stream_buffer.* *libfreertos.a:tasks.* *libfreertos.a:timers.* *libgcc.a:_divsf3.* *libgcc.a:lib2funcs.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libheap.a:multi_heap.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_event.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_pib.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_timer.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp.* *liblog.a:log_timestamp_common.* *liblog.a:log_write.* *liblog.a:tag_log_level.* *liblog.a:util.* *libriscv.a:interrupt.* *libriscv.a:rv_utils.* *libriscv.a:vectors.* *libsoc.a:lldesc.* *libspi_flash.a:esp_flash_api.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_os_func_noos.* *libspi_flash.a:spi_flash_wrap.*) .literal.* EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *librtc.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_ana_cmpr.a:ana_cmpr.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_gptimer.a:gptimer.* *libesp_driver_i2c.a:i2c_master.* *libesp_driver_mcpwm.a:mcpwm_cap.* *libesp_driver_mcpwm.a:mcpwm_cmpr.* *libesp_driver_mcpwm.a:mcpwm_fault.* *libesp_driver_mcpwm.a:mcpwm_oper.* *libesp_driver_mcpwm.a:mcpwm_timer.* *libesp_driver_parlio.a:parlio_common.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_encoder.* *libesp_driver_rmt.a:rmt_rx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_event.a:default_event_loop.* *libesp_event.a:esp_event.* *libesp_hal_ana_conv.a:temperature_sensor_hal.* *libesp_hal_dma.a:gdma_hal_ahb_v2.* *libesp_hal_dma.a:gdma_hal_axi.* *libesp_hal_dma.a:gdma_hal_top.* *libesp_hal_gpio.a:gpio_hal.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_timg.a:timer_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:periph_ctrl.* *libesp_hw_support.a:peripheral_domain_pd.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:rtc_time.* *libesp_hw_support.a:sar_periph_ctrl.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_clock.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_cpu.* *libesp_hw_support.a:sleep_modem.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:esp_time_impl.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_phy.a:phy_override.* *libesp_pm.a:pm_impl.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_ringbuf.a:ringbuf.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:esp_system_chip.* *libesp_system.a:freertos_hooks.* *libesp_system.a:image_process.* *libesp_system.a:panic.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:system_time.* *libesp_system.a:ubsan.* *libesp_timer.a:esp_timer_impl_common.* *libesp_timer.a:esp_timer_impl_systimer.* *libesp_wifi.a:esp_adapter.* *libesp_wifi.a:wifi_netif.* *libfreertos.a:event_groups.* *libfreertos.a:list.* *libfreertos.a:port.* *libfreertos.a:port_systick.* *libfreertos.a:portasm.* *libfreertos.a:queue.* *libfreertos.a:stream_buffer.* *libfreertos.a:tasks.* *libfreertos.a:timers.* *libgcc.a:_divsf3.* *libgcc.a:lib2funcs.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libheap.a:multi_heap.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_event.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_pib.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_timer.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp.* *liblog.a:log_timestamp_common.* *liblog.a:log_write.* *liblog.a:tag_log_level.* *liblog.a:util.* *libriscv.a:interrupt.* *libriscv.a:rv_utils.* *libriscv.a:vectors.* *libsoc.a:lldesc.* *libspi_flash.a:esp_flash_api.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_os_func_noos.* *libspi_flash.a:spi_flash_wrap.*) .text EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *librtc.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_ana_cmpr.a:ana_cmpr.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_gptimer.a:gptimer.* *libesp_driver_i2c.a:i2c_master.* *libesp_driver_mcpwm.a:mcpwm_cap.* *libesp_driver_mcpwm.a:mcpwm_cmpr.* *libesp_driver_mcpwm.a:mcpwm_fault.* *libesp_driver_mcpwm.a:mcpwm_oper.* *libesp_driver_mcpwm.a:mcpwm_timer.* *libesp_driver_parlio.a:parlio_common.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_encoder.* *libesp_driver_rmt.a:rmt_rx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_event.a:default_event_loop.* *libesp_event.a:esp_event.* *libesp_hal_ana_conv.a:temperature_sensor_hal.* *libesp_hal_dma.a:gdma_hal_ahb_v2.* *libesp_hal_dma.a:gdma_hal_axi.* *libesp_hal_dma.a:gdma_hal_top.* *libesp_hal_gpio.a:gpio_hal.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_timg.a:timer_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:periph_ctrl.* *libesp_hw_support.a:peripheral_domain_pd.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:rtc_time.* *libesp_hw_support.a:sar_periph_ctrl.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_clock.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_cpu.* *libesp_hw_support.a:sleep_modem.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:esp_time_impl.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_phy.a:phy_override.* *libesp_pm.a:pm_impl.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_ringbuf.a:ringbuf.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:esp_system_chip.* *libesp_system.a:freertos_hooks.* *libesp_system.a:image_process.* *libesp_system.a:panic.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:system_time.* *libesp_system.a:ubsan.* *libesp_timer.a:esp_timer_impl_common.* *libesp_timer.a:esp_timer_impl_systimer.* *libesp_wifi.a:esp_adapter.* *libesp_wifi.a:wifi_netif.* *libfreertos.a:event_groups.* *libfreertos.a:list.* *libfreertos.a:port.* *libfreertos.a:port_systick.* *libfreertos.a:portasm.* *libfreertos.a:queue.* *libfreertos.a:stream_buffer.* *libfreertos.a:tasks.* *libfreertos.a:timers.* *libgcc.a:_divsf3.* *libgcc.a:lib2funcs.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libheap.a:multi_heap.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_event.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_pib.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_timer.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp.* *liblog.a:log_timestamp_common.* *liblog.a:log_write.* *liblog.a:tag_log_level.* *liblog.a:util.* *libriscv.a:interrupt.* *libriscv.a:rv_utils.* *libriscv.a:vectors.* *libsoc.a:lldesc.* *libspi_flash.a:esp_flash_api.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_os_func_noos.* *libspi_flash.a:spi_flash_wrap.*) .text.*)
 *(EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifi0iram EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifi0iram.*)
 *(EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifiextrairam EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifiextrairam.*)
 *(EXCLUDE_FILE(*libpp.a) .wifiorslpiram EXCLUDE_FILE(*libpp.a) .wifiorslpiram.*)
 *(EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifirxiram EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifirxiram.*)
 *(EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifislpiram EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifislpiram.*)
 *(EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifislprxiram EXCLUDE_FILE(*libnet80211.a *libpp.a) .wifislprxiram.*)
 *libesp_driver_ana_cmpr.a:ana_cmpr.*(.text .text._ana_cmpr_build_intr_mask .text._ana_cmpr_build_scan_mask .text._ana_cmpr_check_pad_conflict .text._ana_cmpr_gpio_to_pad_id .text._ana_cmpr_init_default_channels .text._ana_cmpr_refresh_masks .text.ana_cmpr_add_src_chan .text.ana_cmpr_del_unit .text.ana_cmpr_destroy_unit .text.ana_cmpr_disable .text.ana_cmpr_enable .text.ana_cmpr_get_capture_timestamps .text.ana_cmpr_get_channel_gpio .text.ana_cmpr_get_clock_resolution_hz .text.ana_cmpr_get_gpio .text.ana_cmpr_get_output_level .text.ana_cmpr_new_unit .text.ana_cmpr_publish_unit_slot .text.ana_cmpr_register_event_callbacks .text.ana_cmpr_release_unit_slot .text.ana_cmpr_remove_src_chan .text.ana_cmpr_reserve_unit_slot .text.ana_cmpr_set_debounce .text.ana_cmpr_set_internal_reference .text.ana_cmpr_set_scan_config .text.ana_cmpr_set_src_chan_cross_type .text.ana_cmpr_trigger_scan .text.ana_cmpr_unpublish_unit_slot_for_delete .text.analog_cmpr_ll_set_clk_src)
 *libesp_driver_dma.a:dma2d.*(.text .text.claim_rx_transaction .text.dma2d_acquire_pool .text.dma2d_append .text.dma2d_apply_strategy .text.dma2d_configure_color_space_conversion .text.dma2d_configure_dscr_port_mode .text.dma2d_connect .text.dma2d_dequeue .text.dma2d_enqueue .text.dma2d_force_end .text.dma2d_get_trans_elm_size .text.dma2d_register_rx_event_callbacks .text.dma2d_register_tx_event_callbacks .text.dma2d_release_pool .text.dma2d_reset .text.dma2d_set_desc_addr .text.dma2d_set_transfer_ability .text.dma2d_start .text.dma2d_stop)
 *libesp_driver_dma.a:esp_dma_utils.*(.text .text.esp_dma_calculate_node_count)
 *libesp_driver_dma.a:gdma.*(.text .text._gdma_ll_reset_register .text.do_allocate_gdma_channel .text.gdma_apply_strategy .text.gdma_config_transfer .text.gdma_connect .text.gdma_del_channel .text.gdma_del_rx_channel .text.gdma_del_tx_channel .text.gdma_disconnect .text.gdma_get_alignment_constraints .text.gdma_get_free_m2m_trig_id_mask .text.gdma_get_group_channel_id .text.gdma_install_rx_interrupt .text.gdma_install_tx_interrupt .text.gdma_new_ahb_channel .text.gdma_new_axi_channel .text.gdma_new_lp_ahb_channel .text.gdma_register_rx_event_callbacks .text.gdma_register_tx_event_callbacks .text.gdma_request_link_switch_event .text.gdma_set_priority .text.gdma_try_alloc_group_handle .text.gdma_try_alloc_pair_handle .text.gdma_try_free_group_handle .text.gdma_try_free_pair_handle)
 *libesp_driver_dma.a:gdma_link.*(.text .text.gdma_del_link_list .text.gdma_link_get_item_addr .text.gdma_link_get_owner .text.gdma_new_link_list)
 *libesp_driver_gptimer.a:gptimer.*(.text .text.gptimer_del_timer .text.gptimer_destroy .text.gptimer_disable .text.gptimer_enable .text.gptimer_get_captured_count .text.gptimer_get_raw_count .text.gptimer_get_resolution .text.gptimer_new_timer .text.gptimer_register_event_callbacks .text.gptimer_register_to_group .text.gptimer_set_alarm_action .text.gptimer_set_raw_count .text.gptimer_start .text.gptimer_stop .text.gptimer_unregister_from_group)
 *libesp_driver_i2c.a:i2c_master.*(.text .text.i2c_del_master_bus .text.i2c_ll_master_set_fractional_divider .text.i2c_ll_set_source_clk .text.i2c_master_bus_add_device .text.i2c_master_bus_destroy .text.i2c_master_bus_reset .text.i2c_master_bus_rm_device .text.i2c_master_bus_wait_all_done .text.i2c_master_device_change_address .text.i2c_master_execute_defined_operations .text.i2c_master_get_bus_handle .text.i2c_master_multi_buffer_transmit .text.i2c_master_probe .text.i2c_master_receive .text.i2c_master_register_event_callbacks .text.i2c_master_transmit .text.i2c_master_transmit_receive .text.i2c_new_master_bus .text.i2c_param_master_config .text.lp_i2c_ll_set_source_clk .text.s_i2c_asynchronous_transaction .text.s_i2c_err_log_print .text.s_i2c_hw_fsm_reset .text.s_i2c_master_clear_bus .text.s_i2c_read_command .text.s_i2c_send_command_async .text.s_i2c_send_commands .text.s_i2c_start_end_command .text.s_i2c_synchronous_transaction .text.s_i2c_transaction_start .text.s_i2c_write_command)
 *libesp_driver_mcpwm.a:mcpwm_cap.*(.text .text.mcpwm_cap_timer_destroy .text.mcpwm_cap_timer_register_to_group .text.mcpwm_cap_timer_unregister_from_group .text.mcpwm_capture_channel_destroy .text.mcpwm_capture_channel_disable .text.mcpwm_capture_channel_enable .text.mcpwm_capture_channel_register_event_callbacks .text.mcpwm_capture_channel_register_to_timer .text.mcpwm_capture_channel_trigger_soft_catch .text.mcpwm_capture_channel_unregister_from_timer .text.mcpwm_capture_get_latched_value .text.mcpwm_capture_timer_disable .text.mcpwm_capture_timer_enable .text.mcpwm_capture_timer_get_resolution .text.mcpwm_capture_timer_set_phase_on_sync .text.mcpwm_capture_timer_start .text.mcpwm_capture_timer_stop .text.mcpwm_del_capture_channel .text.mcpwm_del_capture_timer .text.mcpwm_ll_capture_set_prescale .text.mcpwm_new_capture_channel .text.mcpwm_new_capture_timer)
 *libesp_driver_mcpwm.a:mcpwm_cmpr.*(.text .text.mcpwm_comparator_destroy .text.mcpwm_comparator_register_event_callbacks .text.mcpwm_comparator_register_to_operator .text.mcpwm_comparator_set_compare_value .text.mcpwm_comparator_unregister_from_operator .text.mcpwm_del_comparator .text.mcpwm_ll_operator_enable_update_compare_on_sync .text.mcpwm_ll_operator_enable_update_compare_on_tep .text.mcpwm_ll_operator_enable_update_compare_on_tez .text.mcpwm_new_comparator .text.mcpwm_new_event_comparator)
 *libesp_driver_mcpwm.a:mcpwm_fault.*(.text .text.mcpwm_del_fault .text.mcpwm_del_gpio_fault .text.mcpwm_del_soft_fault .text.mcpwm_fault_register_event_callbacks .text.mcpwm_gpio_fault_destroy .text.mcpwm_gpio_fault_register_to_group .text.mcpwm_gpio_fault_unregister_from_group .text.mcpwm_ll_fault_set_active_level .text.mcpwm_new_gpio_fault .text.mcpwm_new_soft_fault .text.mcpwm_soft_fault_activate)
 *libesp_driver_mcpwm.a:mcpwm_oper.*(.text .text.mcpwm_del_operator .text.mcpwm_ll_brake_enable_cbc_mode .text.mcpwm_ll_brake_enable_oneshot_mode .text.mcpwm_ll_carrier_set_first_pulse_width .text.mcpwm_ll_carrier_set_prescale .text.mcpwm_ll_deadtime_enable_update_delay_on_sync .text.mcpwm_ll_deadtime_enable_update_delay_on_tep .text.mcpwm_ll_deadtime_enable_update_delay_on_tez .text.mcpwm_new_operator .text.mcpwm_operator_apply_carrier .text.mcpwm_operator_connect_timer .text.mcpwm_operator_destroy .text.mcpwm_operator_recover_from_fault .text.mcpwm_operator_register_event_callbacks .text.mcpwm_operator_register_to_group .text.mcpwm_operator_set_brake_on_fault .text.mcpwm_operator_unregister_from_group)
 *libesp_driver_mcpwm.a:mcpwm_timer.*(.text .text.mcpwm_del_timer .text.mcpwm_ll_timer_set_clock_prescale .text.mcpwm_ll_timer_set_count_mode .text.mcpwm_ll_timer_set_start_stop_command .text.mcpwm_new_timer .text.mcpwm_timer_destroy .text.mcpwm_timer_disable .text.mcpwm_timer_enable .text.mcpwm_timer_get_phase .text.mcpwm_timer_register_event_callbacks .text.mcpwm_timer_register_to_group .text.mcpwm_timer_set_period .text.mcpwm_timer_set_phase_on_sync .text.mcpwm_timer_start_stop .text.mcpwm_timer_unregister_from_group)
 *libesp_driver_parlio.a:parlio_common.*(.text .text.parlio_acquire_group_handle .text.parlio_register_unit_to_group .text.parlio_release_group_handle .text.parlio_unregister_unit_from_group)
 *libesp_driver_parlio.a:parlio_rx.*(.text .text._parlio_ll_rx_set_clock_source .text.parlio_del_rx_delimiter .text.parlio_del_rx_unit .text.parlio_destroy_rx_unit .text.parlio_ll_rx_set_bus_width .text.parlio_ll_rx_set_clock_div .text.parlio_new_rx_level_delimiter .text.parlio_new_rx_pulse_delimiter .text.parlio_new_rx_soft_delimiter .text.parlio_new_rx_unit .text.parlio_rx_create_dma_link .text.parlio_rx_soft_delimiter_start_stop .text.parlio_rx_unit_disable .text.parlio_rx_unit_do_transaction .text.parlio_rx_unit_enable .text.parlio_rx_unit_init_dma .text.parlio_rx_unit_receive .text.parlio_rx_unit_register_event_callbacks .text.parlio_rx_unit_set_gpio .text.parlio_rx_unit_wait_all_done .text.parlio_select_periph_clock)
 *libesp_driver_parlio.a:parlio_tx.*(.text .text.parlio_del_tx_unit .text.parlio_destroy_tx_unit .text.parlio_ll_tx_set_bus_width .text.parlio_ll_tx_set_clock_div .text.parlio_ll_tx_set_valid_delay .text.parlio_new_tx_unit .text.parlio_select_periph_clock .text.parlio_tx_create_trans_queue .text.parlio_tx_get_alignment_constraints .text.parlio_tx_unit_configure_gpio .text.parlio_tx_unit_disable .text.parlio_tx_unit_enable .text.parlio_tx_unit_init_dma .text.parlio_tx_unit_register_event_callbacks .text.parlio_tx_unit_transmit .text.parlio_tx_unit_wait_all_done)
 *libesp_driver_rmt.a:rmt_encoder.*(.text .text.rmt_alloc_encoder_mem .text.rmt_del_encoder)
 *libesp_driver_rmt.a:rmt_rx.*(.text .text.rmt_del_rx_channel .text.rmt_ll_rx_enable_dma .text.rmt_ll_rx_set_carrier_high_low_ticks .text.rmt_new_rx_channel .text.rmt_receive .text.rmt_rx_demodulate_carrier .text.rmt_rx_destroy .text.rmt_rx_disable .text.rmt_rx_enable .text.rmt_rx_init_dma_link .text.rmt_rx_register_event_callbacks .text.rmt_rx_register_to_group .text.rmt_rx_unregister_from_group)
 *libesp_driver_rmt.a:rmt_tx.*(.text .text.rmt_del_sync_manager .text.rmt_del_tx_channel .text.rmt_ll_tx_enable_dma .text.rmt_ll_tx_set_carrier_high_low_ticks .text.rmt_new_sync_manager .text.rmt_new_tx_channel .text.rmt_sync_reset .text.rmt_transmit .text.rmt_tx_create_trans_queue .text.rmt_tx_destroy .text.rmt_tx_disable .text.rmt_tx_enable .text.rmt_tx_init_dma_link .text.rmt_tx_modulate_carrier .text.rmt_tx_register_event_callbacks .text.rmt_tx_register_to_group .text.rmt_tx_switch_gpio .text.rmt_tx_unregister_from_group .text.rmt_tx_wait_all_done)
 *libesp_event.a:default_event_loop.*(.text .text.esp_event_handler_instance_register .text.esp_event_handler_instance_unregister .text.esp_event_handler_register .text.esp_event_handler_unregister .text.esp_event_loop_create_default .text.esp_event_loop_delete_default .text.esp_event_post)
 *libesp_event.a:esp_event.*(.text .text.base_node_add_handler .text.base_node_remove_all_handler .text.base_node_remove_handler .text.esp_event_dump .text.esp_event_handler_instance_register_with .text.esp_event_handler_instance_unregister_with .text.esp_event_handler_register_with .text.esp_event_handler_register_with_internal .text.esp_event_handler_unregister_with .text.esp_event_handler_unregister_with_internal .text.esp_event_loop_create .text.esp_event_loop_delete .text.esp_event_loop_run .text.esp_event_loop_run_task .text.esp_event_post_to .text.event_loop_has_posts_in_flight .text.find_and_unregister_handler .text.handler_execute .text.handler_instances_add .text.handler_instances_remove .text.handler_instances_remove_all .text.loop_node_add_handler .text.loop_node_remove_all_handler .text.loop_node_remove_handler .text.loop_remove_handler)
 *libesp_hal_ana_conv.a:temperature_sensor_hal.*(.text .text.temperature_sensor_hal_get_degree .text.temperature_sensor_hal_init .text.temperature_sensor_hal_sync_tsens_idx)
 *libesp_hal_dma.a:gdma_hal_ahb_v2.*(.text .text.ahb_dma_ll_rx_set_burst_size .text.ahb_dma_ll_tx_set_burst_size .text.gdma_ahb_hal_connect_mem .text.gdma_ahb_hal_connect_peri .text.gdma_ahb_hal_disconnect_all .text.gdma_ahb_hal_enable_burst .text.gdma_ahb_hal_enable_etm_task .text.gdma_ahb_hal_enable_intr .text.gdma_ahb_hal_get_intr_status_reg .text.gdma_ahb_hal_init .text.gdma_ahb_hal_set_burst_size .text.gdma_ahb_hal_set_priority .text.gdma_ahb_hal_set_strategy .text.gdma_lp_ahb_hal_init)
 *libesp_hal_dma.a:gdma_hal_axi.*(.text .text.axi_dma_ll_rx_set_burst_size .text.axi_dma_ll_tx_request_link_switch_event .text.axi_dma_ll_tx_set_burst_size .text.gdma_axi_hal_connect_mem .text.gdma_axi_hal_connect_peri .text.gdma_axi_hal_disconnect_all .text.gdma_axi_hal_enable_burst .text.gdma_axi_hal_enable_etm_task .text.gdma_axi_hal_enable_intr .text.gdma_axi_hal_get_intr_status_reg .text.gdma_axi_hal_init .text.gdma_axi_hal_request_link_switch_event .text.gdma_axi_hal_set_burst_size .text.gdma_axi_hal_set_priority .text.gdma_axi_hal_set_strategy)
 *libesp_hal_dma.a:gdma_hal_top.*(.text .text.gdma_hal_connect_mem .text.gdma_hal_connect_peri .text.gdma_hal_deinit .text.gdma_hal_disconnect_all .text.gdma_hal_enable_burst .text.gdma_hal_enable_etm_task .text.gdma_hal_enable_intr .text.gdma_hal_get_intr_status_reg .text.gdma_hal_request_link_switch_event .text.gdma_hal_set_burst_size .text.gdma_hal_set_priority .text.gdma_hal_set_strategy)
 *libesp_hal_gpio.a:gpio_hal.*(.text .text.gpio_hal_hysteresis_soft_enable .text.gpio_hal_intr_disable .text.gpio_hal_intr_enable_on_core .text.gpio_hal_iomux_in .text.gpio_hal_iomux_out .text.gpio_hal_matrix_in .text.gpio_hal_matrix_interconnect .text.gpio_hal_matrix_out)
 *libesp_hal_timg.a:timer_hal.*(.text .text.timer_hal_deinit .text.timer_hal_init .text.timer_hal_set_counter_value)
 *libesp_hw_support.a:adc_share_hw_ctrl.*(.text .text.adc2_wifi_acquire .text.adc2_wifi_release .text.adc_lock_acquire .text.adc_lock_release .text.adc_lock_try_acquire)
 *libesp_hw_support.a:cpu.*(.text .text.esp_cpu_clear_breakpoint .text.esp_cpu_clear_watchpoint .text.esp_cpu_set_breakpoint .text.esp_cpu_set_watchpoint)
 *libesp_hw_support.a:esp_clk.*(.text .text.esp_clk_rtc_time)
 *libesp_hw_support.a:esp_clk_tree.*(.text .text._clk_gate_ll_ref_120m_clk_en .text._clk_gate_ll_ref_160m_clk_en .text._clk_gate_ll_ref_20m_clk_en .text._clk_gate_ll_ref_240m_clk_en .text._clk_gate_ll_ref_25m_clk_en .text._clk_gate_ll_ref_50m_clk_en .text._clk_gate_ll_ref_60m_clk_en .text._clk_gate_ll_ref_80m_clk_en .text.clk_ll_pll_f25m_set_divider .text.clk_ll_pll_f50m_set_divider .text.esp_clk_tree_get_derived_clk_desc .text.esp_clk_tree_initialize .text.esp_clk_tree_parent_bbpll .text.esp_clk_tree_parent_rc_fast .text.esp_clk_tree_port_is_power_on .text.esp_clk_tree_ref_500m_derived_acquire_parent .text.esp_clk_tree_ref_500m_derived_release_parent .text.esp_clk_tree_ref_500m_parent_power .text.esp_clk_tree_ref_500m_pll_get_freq_hz .text.esp_clk_tree_ref_500m_set_src .text.esp_clk_tree_ref_80m_derived_acquire_parent .text.esp_clk_tree_ref_80m_derived_release_parent .text.esp_clk_tree_root_pll_power_acquire .text.esp_clk_tree_root_pll_power_release .text.esp_clk_tree_src_get_freq_hz .text.esp_clk_tree_src_set_freq_hz)
 *libesp_hw_support.a:esp_clk_tree_common.*(.text .text.clk_tree_rtc_slow_calibration .text.esp_clk_tree_apll_freq_set .text.esp_clk_tree_derived_clk_acquire .text.esp_clk_tree_derived_clk_freq_set .text.esp_clk_tree_derived_clk_release .text.esp_clk_tree_get_derived_clk_desc .text.esp_clk_tree_lp_fast_get_freq_hz .text.esp_clk_tree_lp_slow_get_freq_hz .text.esp_clk_tree_rc_fast_get_freq_hz .text.esp_clk_tree_src_select_upstream .text.esp_clk_tree_xtal32k_get_freq_hz .text.s_derived_pick_config)
 *libesp_hw_support.a:periph_ctrl.*(.text .text.periph_module_disable .text.periph_module_enable)
 *libesp_hw_support.a:peripheral_domain_pd.*(.text)
 *libesp_hw_support.a:sar_periph_ctrl.*(.text .text.s_sar_power_acquire .text.s_sar_power_release .text.sar_periph_ctrl_adc_continuous_power_acquire .text.sar_periph_ctrl_adc_continuous_power_release .text.sar_periph_ctrl_adc_oneshot_power_acquire .text.sar_periph_ctrl_adc_oneshot_power_release .text.sar_periph_ctrl_init .text.sar_periph_ctrl_pwdet_power_acquire .text.sar_periph_ctrl_pwdet_power_release)
 *libesp_hw_support.a:sar_periph_ctrl_common.*(.text)
 *libesp_hw_support.a:sar_tsens_ctrl.*(.text)
 *libesp_hw_support.a:sleep_clock.*(.text .text.__esp_system_init_fn_sleep_clock_startup_init .text.__esp_system_init_sleep_clock_startup_init .text.sleep_clock_system_retention_init)
 *libesp_hw_support.a:sleep_cpu.*(.text .text.esp_sleep_cpu_retention_deinit .text.esp_sleep_cpu_retention_init .text.sleep_cpu_configure .text.sleep_cpu_retention_finish .text.sleep_cpu_retention_start)
 *libesp_hw_support.a:sleep_modem.*(.text .text.esp_pm_light_sleep_default_params_config .text.esp_pm_register_inform_out_light_sleep_overhead_callback .text.esp_pm_register_light_sleep_default_params_config_callback .text.esp_pm_unregister_inform_out_light_sleep_overhead_callback .text.esp_pm_unregister_light_sleep_default_params_config_callback .text.sleep_modem_configure .text.sleep_modem_phy_deinit .text.sleep_modem_phy_init .text.sleep_modem_phy_link_done .text.sleep_modem_phy_link_enabled)
 *libesp_hw_support.a:sleep_modes.*(.text .text.esp_deep_sleep .text.esp_deep_sleep_deregister_hook .text.esp_deep_sleep_deregister_phy_hook .text.esp_deep_sleep_register_hook .text.esp_deep_sleep_register_phy_hook .text.esp_deep_sleep_try .text.esp_sleep_acquire_lp_use_xtal .text.esp_sleep_disable_bt_wakeup .text.esp_sleep_disable_ext1_wakeup_io .text.esp_sleep_disable_usb_wakeup .text.esp_sleep_disable_wakeup_source .text.esp_sleep_disable_wifi_beacon_wakeup .text.esp_sleep_disable_wifi_wakeup .text.esp_sleep_enable_adc_tsens_monitor .text.esp_sleep_enable_bt_wakeup .text.esp_sleep_enable_ext1_wakeup .text.esp_sleep_enable_ext1_wakeup_io .text.esp_sleep_enable_ext1_wakeup_with_level_mask .text.esp_sleep_enable_gpio_wakeup .text.esp_sleep_enable_touchpad_wakeup .text.esp_sleep_enable_uart_wakeup .text.esp_sleep_enable_ulp_wakeup .text.esp_sleep_enable_usb_wakeup .text.esp_sleep_enable_wifi_beacon_wakeup .text.esp_sleep_enable_wifi_wakeup .text.esp_sleep_enter_critical .text.esp_sleep_enter_critical_safe .text.esp_sleep_exit_critical .text.esp_sleep_exit_critical_safe .text.esp_sleep_get_ext1_wakeup_status .text.esp_sleep_get_touchpad_wakeup_status .text.esp_sleep_get_wakeup_cause .text.esp_sleep_get_wakeup_causes .text.esp_sleep_is_valid_wakeup_gpio .text.esp_sleep_overhead_out_time_refresh .text.esp_sleep_pd_config .text.esp_sleep_periph_use_8m .text.esp_sleep_release_lp_use_xtal .text.esp_sleep_sub_mode_config .text.esp_sleep_sub_mode_dump_config .text.esp_sleep_sub_mode_force_disable .text.ext1_wakeup_prepare .text.rtc_sleep_enable_ultra_low .text.rtcio_ll_force_hold_enable .text.rtcio_ll_function_select .text.s_do_deep_sleep_phy_callback .text.s_sleep_hook_deregister .text.s_sleep_hook_register .text.touch_wakeup_prepare)
 *libesp_libc.a:esp_time_impl.*(.text .text.esp_sync_timekeeping_timers .text.esp_time_impl_get_time .text.esp_time_impl_get_time_since_boot)
 *libesp_phy.a:phy_init.*(.text .text.esp_phy_erase_cal_data_in_nvs .text.esp_phy_get_init_data .text.esp_phy_load_cal_and_init .text.esp_phy_load_cal_data_from_nvs .text.esp_phy_modem_deinit .text.esp_phy_modem_init .text.esp_phy_release_init_data .text.esp_phy_store_cal_data_to_nvs .text.esp_phy_update_country_info .text.load_cal_data_from_nvs_handle .text.phy_get_lock .text.store_cal_data_to_nvs_handle)
 *libesp_phy.a:phy_override.*(.text .text.esp_phy_efuse_get_chip_ver_pkg .text.esp_phy_efuse_get_mac .text.include_esp_phy_override .text.phy_set_pwdet_power .text.set_xpd_sar)
 *libesp_pm.a:pm_impl.*(.text .text.esp_pm_configure .text.esp_pm_get_configuration .text.esp_pm_impl_get_mode .text.esp_pm_impl_idle_hook .text.esp_pm_impl_init .text.esp_pm_impl_waiti)
 *libesp_ringbuf.a:ringbuf.*(.text .text.prvGetAlignedBufferSize .text.prvGetCurMaxSizeAllowSplit .text.prvGetCurMaxSizeByteBuf .text.prvGetCurMaxSizeNoSplit .text.prvGetFreeSize .text.prvInitializeNewRingbuffer .text.prvReceiveGeneric .text.prvSendAcquireGeneric .text.vRingbufferDelete .text.vRingbufferDeleteWithCaps .text.vRingbufferGetInfo .text.vRingbufferReset .text.vRingbufferReturnItem .text.xRingbufferAddToQueueSetRead .text.xRingbufferCreate .text.xRingbufferCreateNoSplit .text.xRingbufferCreateStatic .text.xRingbufferCreateWithCaps .text.xRingbufferGetCurFreeSize .text.xRingbufferGetMaxItemSize .text.xRingbufferGetStaticBuffer .text.xRingbufferPrintInfo .text.xRingbufferReceive .text.xRingbufferReceiveSplit .text.xRingbufferReceiveUpTo .text.xRingbufferRemoveFromQueueSetRead .text.xRingbufferSend .text.xRingbufferSendAcquire .text.xRingbufferSendComplete)
 *libesp_system.a:esp_system_chip.*(.text .text.esp_get_free_heap_size .text.esp_get_free_internal_heap_size .text.esp_get_idf_version .text.esp_get_minimum_free_heap_size)
 *libesp_system.a:freertos_hooks.*(.text .text.esp_deregister_freertos_idle_hook .text.esp_deregister_freertos_idle_hook_for_cpu .text.esp_deregister_freertos_tick_hook .text.esp_deregister_freertos_tick_hook_for_cpu .text.esp_register_freertos_idle_hook .text.esp_register_freertos_idle_hook_for_cpu .text.esp_register_freertos_tick_hook .text.esp_register_freertos_tick_hook_for_cpu .text.esp_vApplicationIdleHook)
 *libesp_system.a:panic.*(.text .text.esp_panic_handler .text.esp_panic_handler_disable_timg_wdts .text.esp_panic_handler_enable_rtc_wdt .text.esp_panic_handler_feed_wdts .text.esp_panic_handler_increment_entry_count .text.esp_panic_trigger_event .text.esp_reset_reason_get_hint .text.esp_reset_reason_set_hint .text.panic_disable_all_wdts .text.panic_print_char .text.panic_print_char_uart .text.panic_print_char_usb_serial_jtag .text.panic_print_dec .text.panic_print_hex .text.panic_print_str .text.print_abort_details .text.semihosting_call_noerrno)
 *libesp_system.a:reset_reason.*(.text .text.esp_reset_reason .text.esp_reset_reason_get_hint .text.esp_reset_reason_init .text.get_reset_reason)
 *libesp_system.a:system_internal.*(.text)
 *libesp_system.a:system_time.*(.text)
 *libesp_timer.a:esp_timer_impl_common.*(.text)
 *libesp_timer.a:esp_timer_impl_systimer.*(.text .text.esp_timer_impl_deinit .text.esp_timer_impl_early_init .text.esp_timer_impl_get_alarm_reg .text.esp_timer_impl_init)
 *libesp_wifi.a:esp_adapter.*(.text .text.clear_intr_wrapper .text.coex_configure_preemption_end_cb_wrapper .text.coex_deinit_wrapper .text.coex_disable_wrapper .text.coex_enable_wrapper .text.coex_init_wrapper .text.coex_register_start_cb_wrapper .text.coex_schm_curr_period_get_wrapper .text.coex_schm_curr_phase_get_wrapper .text.coex_schm_flexible_period_get_wrapper .text.coex_schm_flexible_period_set_wrapper .text.coex_schm_get_phase_by_idx_wrapper .text.coex_schm_interval_get_wrapper .text.coex_schm_process_restart_wrapper .text.coex_schm_register_cb_wrapper .text.coex_schm_status_bit_clear_wrapper .text.coex_schm_status_bit_set_wrapper .text.coex_wifi_channel_set_wrapper .text.coex_wifi_request_wrapper .text.disable_intr_wrapper .text.enable_intr_wrapper .text.esp_event_post_wrapper .text.esp_log_write_wrapper .text.esp_log_writev_wrapper .text.esp_phy_disable_wrapper .text.esp_phy_enable_wrapper .text.esp_phy_wifi_bb_sleep_retention_attach_wrapper .text.esp_phy_wifi_bb_sleep_retention_detach_wrapper .text.esp_read_mac_wrapper .text.esp_wifi_disable_ac_ax_wrapper .text.esp_wifi_mac_sleep_retention_attach_wrapper .text.esp_wifi_mac_sleep_retention_detach_wrapper .text.event_group_wait_bits_wrapper .text.get_time_wrapper .text.mutex_create_wrapper .text.mutex_delete_wrapper .text.nvs_open_wrapper .text.queue_create_wrapper .text.queue_delete_wrapper .text.queue_recv_wrapper .text.queue_send_to_back_wrapper .text.queue_send_to_front_wrapper .text.queue_send_wrapper .text.recursive_mutex_create_wrapper .text.set_intr_wrapper .text.set_isr_wrapper .text.task_create_pinned_to_core_wrapper .text.task_create_wrapper .text.task_get_max_priority_wrapper .text.wifi_create_queue .text.wifi_create_queue_wrapper .text.wifi_delete_queue .text.wifi_delete_queue_wrapper .text.wifi_reset_mac_wrapper .text.wifi_thread_semphr_free .text.wifi_thread_semphr_get_wrapper)
 *libesp_wifi.a:wifi_netif.*(.text .text.esp_wifi_create_if_driver .text.esp_wifi_destroy_if_driver .text.esp_wifi_get_if_mac .text.esp_wifi_is_if_ready_when_started .text.esp_wifi_netif_get_ip6_linklocal_from_mac .text.esp_wifi_register_if_rxcb .text.wifi_ap_receive .text.wifi_driver_start .text.wifi_free .text.wifi_transmit)
 *libfreertos.a:event_groups.*(.text .text.prvTestWaitCondition .text.vEventGroupClearBitsCallback .text.vEventGroupDelete .text.vEventGroupSetBitsCallback .text.xEventGroupClearBits .text.xEventGroupCreate .text.xEventGroupCreateStatic .text.xEventGroupGetStaticBuffer .text.xEventGroupSetBits .text.xEventGroupSync .text.xEventGroupWaitBits)
 *libfreertos.a:list.*(.text .text.vListInitialise .text.vListInitialiseItem .text.vListInsert)
 *libfreertos.a:port.*(.text .text.Atomic_CompareAndSwapPointers_p32 .text.pxPortGetCoprocArea .text.pxPortInitialiseStack .text.pxPortUpdateCoprocOwner .text.vApplicationStackOverflowHook .text.vPortCleanUpCoprocArea .text.vPortEndScheduler .text.vPortExitCriticalCompliance .text.vPortTCBPreDeleteHook .text.vPortTLSPointersDelCb .text.vPortTaskPinToCore .text.vPortTaskUsedPIEOnCPU0 .text.vPortTaskWrapper .text.xPortEnterCriticalTimeoutCompliance .text.xPortGetTickRateHz .text.xPortStartScheduler .text.xPortThreadSafeClaim .text.xPortThreadSafeDisclaim)
 *libfreertos.a:port_systick.*(.literal.vPortSetupTimer .text.vPortSetupTimer)
 *libfreertos.a:port_systick.*(.literal.vSystimerSetup .text.vSystimerSetup)
 *libfreertos.a:queue.*(.text .text.prvGetDisinheritPriorityAfterTimeout .text.prvInitialiseMutex .text.prvInitialiseNewQueue .text.uxQueueMessagesWaiting .text.uxQueueSpacesAvailable .text.vQueueDelete .text.vQueueWaitForMessageRestricted .text.xQueueAddToSet .text.xQueueCreateCountingSemaphore .text.xQueueCreateCountingSemaphoreStatic .text.xQueueCreateMutex .text.xQueueCreateMutexStatic .text.xQueueCreateSet .text.xQueueGenericCreate .text.xQueueGenericCreateStatic .text.xQueueGenericGetStaticBuffers .text.xQueueGenericReset .text.xQueueGenericSend .text.xQueueGetMutexHolder .text.xQueueGiveMutexRecursive .text.xQueuePeek .text.xQueueReceive .text.xQueueRemoveFromSet .text.xQueueSelectFromSet .text.xQueueSemaphoreTake .text.xQueueTakeMutexRecursive)
 *libfreertos.a:stream_buffer.*(.text .text.prvInitialiseNewStreamBuffer .text.prvReadBytesFromBuffer .text.prvWriteBytesToBuffer .text.vStreamBufferDelete .text.xStreamBufferBytesAvailable .text.xStreamBufferGenericCreate .text.xStreamBufferGenericCreateStatic .text.xStreamBufferGetStaticBuffers .text.xStreamBufferIsEmpty .text.xStreamBufferIsFull .text.xStreamBufferNextMessageLengthBytes .text.xStreamBufferReceive .text.xStreamBufferReset .text.xStreamBufferSend .text.xStreamBufferSetTriggerLevel .text.xStreamBufferSpacesAvailable)
 *libfreertos.a:tasks.*(.text .text.eTaskGetState .text.pcTaskGetName .text.prvAddCurrentTaskToDelayedList .text.prvAddNewTaskToReadyList .text.prvCheckTasksWaitingTermination .text.prvCreateIdleTasks .text.prvDeleteTCB .text.prvIdleTask .text.prvInitialiseNewTask .text.prvInitialiseTaskLists .text.prvReleaseKernelLock .text.prvSearchForNameWithinSingleList .text.prvTakeKernelLock .text.prvTaskCheckFreeStackSpace .text.prvTaskCreateDynamicPinnedToCoreWithCaps .text.prvTaskPriorityRaise .text.prvTaskPriorityRestore .text.pvTaskGetCurrentTCBForCore .text.pvTaskGetThreadLocalStoragePointer .text.pvTaskIncrementMutexHeldCount .text.pxGetTaskListByIndex .text.pxTaskGetStackStart .text.ulTaskGenericNotifyTake .text.ulTaskGenericNotifyValueClear .text.uxTaskGetNumberOfTasks .text.uxTaskGetSnapshotAll .text.uxTaskGetStackHighWaterMark .text.uxTaskGetStackHighWaterMark2 .text.uxTaskPriorityGet .text.uxTaskResetEventItemValue .text.vTaskDelay .text.vTaskDelete .text.vTaskEndScheduler .text.vTaskInternalSetTimeOutState .text.vTaskMissedYield .text.vTaskPlaceOnEventList .text.vTaskPlaceOnEventListRestricted .text.vTaskPlaceOnUnorderedEventList .text.vTaskPriorityDisinheritAfterTimeout .text.vTaskPrioritySet .text.vTaskRemoveFromUnorderedEventList .text.vTaskResume .text.vTaskSetThreadLocalStoragePointer .text.vTaskSetThreadLocalStoragePointerAndDelCallback .text.vTaskSetTimeOutState .text.vTaskStartScheduler .text.vTaskSuspend .text.vTaskSuspendAll .text.xTaskAbortDelay .text.xTaskCatchUpTicks .text.xTaskCheckForTimeOut .text.xTaskCreatePinnedToCore .text.xTaskCreateStaticPinnedToCore .text.xTaskDelayUntil .text.xTaskGenericNotify .text.xTaskGenericNotifyStateClear .text.xTaskGenericNotifyWait .text.xTaskGetCoreID .text.xTaskGetCurrentTaskHandle .text.xTaskGetCurrentTaskHandleForCore .text.xTaskGetHandle .text.xTaskGetIdleTaskHandle .text.xTaskGetIdleTaskHandleForCore .text.xTaskGetNext .text.xTaskGetStackStart .text.xTaskGetStaticBuffers .text.xTaskPriorityDisinherit .text.xTaskPriorityInherit .text.xTaskResumeAll .text.xTimerCreateTimerTask)
 *libfreertos.a:timers.*(.text .text.pcTimerGetName .text.prvCheckForValidListAndQueue .text.prvGetNextExpireTime .text.prvInitialiseNewTimer .text.prvInsertTimerInActiveList .text.prvProcessExpiredTimer .text.prvProcessReceivedCommands .text.prvProcessTimerOrBlockTask .text.prvReloadTimer .text.prvSampleTimeNow .text.prvSwitchTimerLists .text.prvTimerTask .text.pvTimerGetTimerID .text.uxTimerGetReloadMode .text.vTimerSetReloadMode .text.vTimerSetTimerID .text.xTimerCreate .text.xTimerCreateStatic .text.xTimerCreateTimerTask .text.xTimerGetExpiryTime .text.xTimerGetPeriod .text.xTimerGetReloadMode .text.xTimerGetStaticBuffer .text.xTimerGetTimerDaemonTaskHandle .text.xTimerIsTimerActive .text.xTimerPendFunctionCall)
 *libheap.a:multi_heap.*(.text .text.multi_heap_reset_minimum_free_bytes .text.multi_heap_restore_minimum_free_bytes)
 *libieee802154.a:esp_ieee802154.*(.text .text.esp_ieee802154_add_pending_addr .text.esp_ieee802154_cca .text.esp_ieee802154_cca_done .text.esp_ieee802154_clear_pending_addr .text.esp_ieee802154_disable .text.esp_ieee802154_ed_failed .text.esp_ieee802154_enable .text.esp_ieee802154_energy_detect .text.esp_ieee802154_energy_detect_done .text.esp_ieee802154_event_callback_list_register .text.esp_ieee802154_event_callback_list_unregister .text.esp_ieee802154_get_ack_timeout .text.esp_ieee802154_get_auto_ack_rx .text.esp_ieee802154_get_auto_ack_tx .text.esp_ieee802154_get_cca_mode .text.esp_ieee802154_get_cca_threshold .text.esp_ieee802154_get_channel .text.esp_ieee802154_get_coex_config .text.esp_ieee802154_get_coordinator .text.esp_ieee802154_get_panid .text.esp_ieee802154_get_pending_mode .text.esp_ieee802154_get_power_table .text.esp_ieee802154_get_power_with_channel .text.esp_ieee802154_get_promiscuous .text.esp_ieee802154_get_rx_when_idle .text.esp_ieee802154_get_short_address .text.esp_ieee802154_get_state .text.esp_ieee802154_get_txpower .text.esp_ieee802154_receive_at_done .text.esp_ieee802154_receive_done .text.esp_ieee802154_receive_failed .text.esp_ieee802154_receive_handle_done .text.esp_ieee802154_receive_sfd_done .text.esp_ieee802154_reset_pending_table .text.esp_ieee802154_set_ack_timeout .text.esp_ieee802154_set_auto_ack_rx .text.esp_ieee802154_set_auto_ack_tx .text.esp_ieee802154_set_cca_mode .text.esp_ieee802154_set_cca_threshold .text.esp_ieee802154_set_channel .text.esp_ieee802154_set_coex_config .text.esp_ieee802154_set_coordinator .text.esp_ieee802154_set_extended_address .text.esp_ieee802154_set_panid .text.esp_ieee802154_set_pending_mode .text.esp_ieee802154_set_power_table .text.esp_ieee802154_set_power_with_channel .text.esp_ieee802154_set_promiscuous .text.esp_ieee802154_set_rx_when_idle .text.esp_ieee802154_set_short_address .text.esp_ieee802154_set_txpower .text.esp_ieee802154_sleep .text.esp_ieee802154_transmit_done .text.esp_ieee802154_transmit_failed .text.esp_ieee802154_transmit_sfd_done .text.ieee802154_ll_get_multipan_ext_addr .text.ieee802154_ll_set_multipan_ext_addr)
 *libieee802154.a:esp_ieee802154_ack.*(.text .text.ieee802154_add_pending_addr .text.ieee802154_clear_pending_addr .text.ieee802154_reset_pending_table)
 *libieee802154.a:esp_ieee802154_dev.*(.text .text.enable_rx .text.ieee802154_cca .text.ieee802154_disable .text.ieee802154_enable .text.ieee802154_energy_detect .text.ieee802154_get_state .text.ieee802154_mac_deinit .text.ieee802154_mac_init .text.ieee802154_mac_is_inited .text.ieee802154_receive_done .text.ieee802154_receive_handle_done .text.ieee802154_rx_ack_timeout_callback .text.ieee802154_sleep .text.ieee802154_sleep_deinit .text.ieee802154_sleep_init .text.ieee802154_transmit_done .text.ieee802154_transmit_internal .text.rx_init .text.start_ed .text.tx_init)
 *libieee802154.a:esp_ieee802154_event.*(.text .text.ieee802154_event_callback_list_register .text.ieee802154_event_callback_list_unregister)
 *libieee802154.a:esp_ieee802154_frame.*(.text .text.ieee802154_frame_get_ie_field_len .text.ieee802154_frame_get_mic_len .text.ieee802154_frame_get_type .text.ieee802154_frame_get_version .text.ieee802154_frame_ie_header_offset .text.ieee802154_frame_is_ack_required)
 *libieee802154.a:esp_ieee802154_pib.*(.text .text.IEEE802154_TXPOWER_VALUE_MAX .text.ieee802154_pib_get_auto_ack_rx .text.ieee802154_pib_get_auto_ack_tx .text.ieee802154_pib_get_cca_mode .text.ieee802154_pib_get_cca_threshold .text.ieee802154_pib_get_channel .text.ieee802154_pib_get_coordinator .text.ieee802154_pib_get_enhance_ack_tx .text.ieee802154_pib_get_power .text.ieee802154_pib_get_power_table .text.ieee802154_pib_get_power_with_channel .text.ieee802154_pib_get_promiscuous .text.ieee802154_pib_init .text.ieee802154_pib_is_pending .text.ieee802154_pib_set_auto_ack_rx .text.ieee802154_pib_set_auto_ack_tx .text.ieee802154_pib_set_cca_mode .text.ieee802154_pib_set_cca_threshold .text.ieee802154_pib_set_channel .text.ieee802154_pib_set_coordinator .text.ieee802154_pib_set_enhance_ack_tx .text.ieee802154_pib_set_pending_mode .text.ieee802154_pib_set_power .text.ieee802154_pib_set_power_table .text.ieee802154_pib_set_power_with_channel .text.ieee802154_pib_set_promiscuous .text.ieee802154_pib_set_rx_when_idle)
 *libieee802154.a:esp_ieee802154_sec.*(.text .text.ieee802154_ll_set_security_addr .text.ieee802154_ll_set_security_key)
 *libieee802154.a:esp_ieee802154_timer.*(.text .text.ieee802154_timer0_get_value .text.ieee802154_timer1_get_value)
 *libieee802154.a:esp_ieee802154_util.*(.text .text.bt_bb_get_tx_pwr_table .text.ieee802154_etm_set_event_task .text.ieee802154_freq_to_channel .text.ieee802154_get_coex_config .text.ieee802154_set_coex_config .text.ieee802154_set_txrx_pti)
 *liblog.a:log_timestamp.*(.text)
 *liblog.a:log_write.*(.text .text.esp_log_set_vprintf)
 *liblog.a:tag_log_level.*(.text .text.esp_log_level_get .text.esp_log_level_set .text.log_level_get .text.log_level_set)
 *libriscv.a:interrupt.*(.literal.intr_handler_get .text.intr_handler_get)
 *libriscv.a:interrupt.*(.literal.intr_handler_set .text.intr_handler_set)
 *libspi_flash.a:esp_flash_api.*(.text .text.esp_flash_app_disable_protect .text.esp_flash_get_protectable_regions .text.esp_flash_read_chip_id .text.esp_flash_read_id .text.esp_flash_read_unique_chip_id .text.esp_flash_suspend_cmd_init .text.find_region)
 *libspi_flash.a:flash_ops.*(.text .text.esp_mspi_pin_reserve)
 *libspi_flash.a:spi_flash_os_func_app.*(.text .text.esp_flash_app_enable_os_functions .text.esp_flash_app_init_os_functions .text.esp_flash_deinit_os_functions .text.esp_flash_init_os_functions .text.esp_flash_set_dangerous_write_protection .text.use_bus_lock)
 *libspi_flash.a:spi_flash_os_func_noos.*(.text)

    *(.stub)
    *(.gnu.linkonce.t.*)
    *(.gnu.warning)
    *(.irom0.text) /* catch stray ICACHE_RODATA_ATTR */
    /**
     * CPU will try to prefetch up to 16 bytes of instructions.
     * This means that any configuration (e.g. MMU, PMS) must allow
     * safe access to up to 16 bytes after the last real instruction.
     * Add dummy bytes to ensure this.
     */
    . += 16;
    _text_end = ABSOLUTE(.);
    /**
     * Mark the flash.text end.
     * This can be used for MMU driver to maintain virtual address.
     */
    _instruction_reserved_end = ABSOLUTE(.);
    _etext = .;
    /**
     * Similar to _iram_start, this symbol goes here so it is
     * resolved by addr2line in preference to the first symbol in
     * the flash.text segment.
     */
    _flash_cache_start = ABSOLUTE(0);
  } > flash_text_seg
  /**
   * Dummy section represents the .flash.text section but in flash_rodata_seg.
   * Thus, it must have its alignment and (at least) its size.
   */
  .flash_rodata_dummy (NOLOAD) :
  {
    _flash_rodata_dummy_start = .;
    . = ALIGN(ALIGNOF(.flash.text)) + SIZEOF(.flash.text);
    /* Add alignment of MMU page size + 0x20 bytes for the mapping header */
    . = ALIGN(0x10000) + 0x20;
  } > flash_rodata_seg
  .flash.appdesc : ALIGN(0x10)
  {
    /**
     * Mark flash.rodata start.
     * This can be used for MMU driver to maintain virtual address.
     */
    _rodata_reserved_start = ABSOLUTE(.);
    _rodata_start = ABSOLUTE(.);
    /* !DO NOT PUT ANYTHING BEFORE THIS! */
    /* Should be the first: App version info */
    *(.rodata_desc .rodata_desc.*)
    /* Should be the second: Custom app version info */
    *(.rodata_custom_desc .rodata_custom_desc.*)
    /**
     * Create an empty gap within this section. Thanks to this, the end of this
     * section will match .flash.rodata's begin address. Thus, both sections
     * will be merged when creating the final bin image.
     */
    . = ALIGN(ALIGNOF(.flash.rodata));
  } > flash_rodata_seg
  ASSERT((ADDR(.flash.rodata) == ADDR(.flash.appdesc) + SIZEOF(.flash.appdesc)), "The gap between .flash.appdesc and .flash.rodata must not exist to produce the final bin image.")
  .flash.rodata : ALIGN(0x10)
  {
    _flash_rodata_start = ABSOLUTE(.);
    
 
 _esp_err_msg_tbl_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_NAME(.esp_err_msg_tbl) SORT_BY_NAME(.esp_err_msg_tbl.*)))
 _esp_err_msg_tbl_end = ABSOLUTE(.);
 _esp_libc_clock_array_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_NAME(.esp_libc_clock_desc)))
 _esp_libc_clock_array_end = ABSOLUTE(.);
 _esp_trace_encoder_array_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_NAME(.esp_trace_encoder_desc)))
 _esp_trace_encoder_array_end = ABSOLUTE(.);
 _esp_trace_transport_array_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_NAME(.esp_trace_transport_desc)))
 _esp_trace_transport_array_end = ABSOLUTE(.);
 . = ALIGN(4);
 _esysev_initc_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_INIT_PRIORITY(.esysev_initc) SORT_BY_INIT_PRIORITY(.esysev_initc.*)))
 _esysev_initc_end = ABSOLUTE(.);
 . = ALIGN(4);
 _esysev_inits_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_INIT_PRIORITY(.esysev_inits) SORT_BY_INIT_PRIORITY(.esysev_inits.*)))
 _esysev_inits_end = ABSOLUTE(.);
 . = ALIGN(4);
 _esysev_paneb_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_INIT_PRIORITY(.esysev_paneb) SORT_BY_INIT_PRIORITY(.esysev_paneb.*)))
 _esysev_paneb_end = ABSOLUTE(.);
 . = ALIGN(4);
 _esysev_panic_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_INIT_PRIORITY(.esysev_panic) SORT_BY_INIT_PRIORITY(.esysev_panic.*)))
 _esysev_panic_end = ABSOLUTE(.);
 . = ALIGN(4);
 _esysev_shdn_start = ABSOLUTE(.);
 KEEP(*(SORT_BY_INIT_PRIORITY(.esysev_shdn) SORT_BY_INIT_PRIORITY(.esysev_shdn.*)))
 _esysev_shdn_end = ABSOLUTE(.);
 *(EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *libphy.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_hal_ana_conv.a:temperature_sensor_periph.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_parlio.a:parlio_periph.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:image_process.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:ubsan.* *libgcc.a:_divsf3.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp_common.* *liblog.a:util.* *libsoc.a:lldesc.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_wrap.*) .rodata EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *libphy.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_hal_ana_conv.a:temperature_sensor_periph.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_parlio.a:parlio_periph.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:image_process.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:ubsan.* *libgcc.a:_divsf3.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp_common.* *liblog.a:util.* *libsoc.a:lldesc.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_wrap.*) .rodata.* EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *libphy.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_hal_ana_conv.a:temperature_sensor_periph.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_parlio.a:parlio_periph.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:image_process.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:ubsan.* *libgcc.a:_divsf3.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp_common.* *liblog.a:util.* *libsoc.a:lldesc.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_wrap.*) .sdata2 EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *libphy.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_hal_ana_conv.a:temperature_sensor_periph.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_parlio.a:parlio_periph.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:image_process.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:ubsan.* *libgcc.a:_divsf3.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp_common.* *liblog.a:util.* *libsoc.a:lldesc.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_wrap.*) .sdata2.* EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *libphy.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_hal_ana_conv.a:temperature_sensor_periph.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_parlio.a:parlio_periph.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:image_process.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:ubsan.* *libgcc.a:_divsf3.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp_common.* *liblog.a:util.* *libsoc.a:lldesc.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_wrap.*) .srodata EXCLUDE_FILE(*libesp_hal_regi2c.a *libesp_hal_systimer.a *libgcov.a *libphy.a *libclang_rt.builtins.a:_divsf3.* *libclang_rt.builtins.a:restore.* *libclang_rt.builtins.a:save.* *libesp_driver_dma.a:dma2d.* *libesp_driver_dma.a:esp_dma_utils.* *libesp_driver_dma.a:gdma_link.* *libesp_driver_parlio.a:parlio_rx.* *libesp_driver_parlio.a:parlio_tx.* *libesp_driver_rmt.a:rmt_tx.* *libesp_hal_ana_conv.a:temperature_sensor_periph.* *libesp_hal_gpspi.a:spi_hal_iram.* *libesp_hal_gpspi.a:spi_slave_hal_iram.* *libesp_hal_i2c.a:i2c_hal_iram.* *libesp_hal_ledc.a:ledc_hal_iram.* *libesp_hal_mspi.a:spi_flash_encrypt_hal_iram.* *libesp_hal_mspi.a:spi_flash_hal_gpspi.* *libesp_hal_mspi.a:spi_flash_hal_iram.* *libesp_hal_parlio.a:parlio_periph.* *libesp_hal_pmu.a:pmu_hal.* *libesp_hal_wdt.a:rom_patch.* *libesp_hw_support.a:adc_share_hw_ctrl.* *libesp_hw_support.a:clk_utils.* *libesp_hw_support.a:cpu.* *libesp_hw_support.a:esp_clk_tree.* *libesp_hw_support.a:esp_clk_tree_common.* *libesp_hw_support.a:esp_gpio_reserve.* *libesp_hw_support.a:esp_memory_utils.* *libesp_hw_support.a:mspi_timing_by_dqs.* *libesp_hw_support.a:mspi_timing_config.* *libesp_hw_support.a:mspi_timing_tuning.* *libesp_hw_support.a:pmu_sleep.* *libesp_hw_support.a:regi2c_ctrl.* *libesp_hw_support.a:rtc_clk.* *libesp_hw_support.a:sar_periph_ctrl_common.* *libesp_hw_support.a:sar_tsens_ctrl.* *libesp_hw_support.a:sleep_cache.* *libesp_hw_support.a:sleep_console.* *libesp_hw_support.a:sleep_modes.* *libesp_hw_support.a:sleep_mspi.* *libesp_hw_support.a:sleep_usb.* *libesp_hw_support.a:systimer.* *libesp_libc.a:abort.* *libesp_libc.a:assert.* *libesp_libc.a:heap.* *libesp_libc.a:stdatomic.* *libesp_mm.a:esp_cache_msync.* *libesp_mm.a:esp_cache_utils.* *libesp_phy.a:phy_init.* *libesp_psram.a:esp_psram_impl_ap_oct.* *libesp_rom.a:esp_rom_cache_writeback_esp32p4_esp32s31.* *libesp_rom.a:esp_rom_print.* *libesp_rom.a:esp_rom_spiflash.* *libesp_rom.a:esp_rom_sys.* *libesp_system.a:esp_err.* *libesp_system.a:image_process.* *libesp_system.a:reset_reason.* *libesp_system.a:system_internal.* *libesp_system.a:ubsan.* *libgcc.a:_divsf3.* *libgcc.a:save-restore.* *libhal.a:cache_hal.* *libhal.a:mmu_hal.* *libieee802154.a:esp_ieee802154.* *libieee802154.a:esp_ieee802154_ack.* *libieee802154.a:esp_ieee802154_dev.* *libieee802154.a:esp_ieee802154_frame.* *libieee802154.a:esp_ieee802154_sec.* *libieee802154.a:esp_ieee802154_util.* *liblog.a:log.* *liblog.a:log_format_text.* *liblog.a:log_lock.* *liblog.a:log_print.* *liblog.a:log_timestamp_common.* *liblog.a:util.* *libsoc.a:lldesc.* *libspi_flash.a:flash_brownout_hook.* *libspi_flash.a:flash_ops.* *libspi_flash.a:memspi_host_driver.* *libspi_flash.a:spi_flash_chip_boya.* *libspi_flash.a:spi_flash_chip_gd.* *libspi_flash.a:spi_flash_chip_generic.* *libspi_flash.a:spi_flash_chip_issi.* *libspi_flash.a:spi_flash_chip_mxic.* *libspi_flash.a:spi_flash_chip_th.* *libspi_flash.a:spi_flash_chip_winbond.* *libspi_flash.a:spi_flash_os_func_app.* *libspi_flash.a:spi_flash_wrap.*) .srodata.*)
 *(.rodata_wlog_error .rodata_wlog_error.*)
 *(.rodata_wlog_info .rodata_wlog_info.*)
 *(.rodata_wlog_warning .rodata_wlog_warning.*)
 *libesp_driver_dma.a:dma2d.*(.rodata.__FUNCTION__.1 .rodata.__FUNCTION__.10 .rodata.__FUNCTION__.11 .rodata.__FUNCTION__.12 .rodata.__FUNCTION__.14 .rodata.__FUNCTION__.15 .rodata.__FUNCTION__.16 .rodata.__FUNCTION__.17 .rodata.__FUNCTION__.2 .rodata.__FUNCTION__.20 .rodata.__FUNCTION__.22 .rodata.__FUNCTION__.25 .rodata.__FUNCTION__.3 .rodata.__FUNCTION__.4 .rodata.__FUNCTION__.7 .rodata.__FUNCTION__.8 .rodata.__FUNCTION__.9 .rodata.__func__.0 .rodata.__func__.13 .rodata.__func__.18 .rodata.__func__.19 .rodata.__func__.21 .rodata.__func__.23 .rodata.__func__.24 .rodata.dma2d_acquire_pool.str1.4 .rodata.dma2d_configure_color_space_conversion.str1.4 .rodata.dma2d_connect.str1.4 .rodata.dma2d_enqueue.str1.4 .rodata.dma2d_force_end.str1.4 .rodata.dma2d_register_tx_event_callbacks.str1.4 .rodata.dma2d_release_pool.str1.4 .rodata.dma2d_set_desc_addr.str1.4 .rodata.dma2d_set_transfer_ability.str1.4 .rodata.dma2d_start.str1.4)
 *libesp_driver_dma.a:esp_dma_utils.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.1 .rodata.__FUNCTION__.2 .rodata.esp_dma_calculate_node_count.str1.4)
 *libesp_driver_dma.a:gdma_link.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.1 .rodata.__FUNCTION__.2 .rodata.gdma_new_link_list.str1.4)
 *libesp_driver_parlio.a:parlio_rx.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.1 .rodata.__FUNCTION__.10 .rodata.__FUNCTION__.12 .rodata.__FUNCTION__.13 .rodata.__FUNCTION__.14 .rodata.__FUNCTION__.18 .rodata.__FUNCTION__.19 .rodata.__FUNCTION__.2 .rodata.__FUNCTION__.20 .rodata.__FUNCTION__.21 .rodata.__FUNCTION__.22 .rodata.__FUNCTION__.3 .rodata.__FUNCTION__.4 .rodata.__FUNCTION__.5 .rodata.__FUNCTION__.6 .rodata.__FUNCTION__.7 .rodata.__FUNCTION__.8 .rodata.__FUNCTION__.9 .rodata.__func__.11 .rodata.__func__.15 .rodata.__func__.16 .rodata.__func__.17 .rodata._parlio_ll_rx_set_clock_source.str1.4 .rodata.parlio_del_rx_delimiter.str1.4 .rodata.parlio_del_rx_unit.str1.4 .rodata.parlio_destroy_rx_unit.str1.4 .rodata.parlio_ll_rx_set_clock_div.str1.4 .rodata.parlio_new_rx_level_delimiter.str1.4 .rodata.parlio_new_rx_pulse_delimiter.str1.4 .rodata.parlio_new_rx_soft_delimiter.str1.4 .rodata.parlio_new_rx_unit.str1.4 .rodata.parlio_rx_create_dma_link.str1.4 .rodata.parlio_rx_soft_delimiter_start_stop.str1.4 .rodata.parlio_rx_unit_disable.str1.4 .rodata.parlio_rx_unit_do_transaction.str1.4 .rodata.parlio_rx_unit_enable.str1.4 .rodata.parlio_rx_unit_init_dma.str1.4 .rodata.parlio_rx_unit_receive.str1.4 .rodata.parlio_rx_unit_set_gpio.str1.4 .rodata.parlio_rx_unit_wait_all_done.str1.4 .rodata.parlio_select_periph_clock.str1.4)
 *libesp_driver_parlio.a:parlio_tx.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.11 .rodata.__FUNCTION__.13 .rodata.__FUNCTION__.14 .rodata.__FUNCTION__.17 .rodata.__FUNCTION__.18 .rodata.__FUNCTION__.2 .rodata.__FUNCTION__.4 .rodata.__FUNCTION__.5 .rodata.__FUNCTION__.6 .rodata.__FUNCTION__.7 .rodata.__FUNCTION__.8 .rodata.__func__.1 .rodata.__func__.10 .rodata.__func__.12 .rodata.__func__.15 .rodata.__func__.16 .rodata.__func__.3 .rodata.parlio_del_tx_unit.str1.4 .rodata.parlio_destroy_tx_unit.str1.4 .rodata.parlio_ll_tx_set_bus_width.str1.4 .rodata.parlio_ll_tx_set_clock_div.str1.4 .rodata.parlio_new_tx_unit.str1.4 .rodata.parlio_select_periph_clock.str1.4 .rodata.parlio_tx_create_trans_queue.str1.4 .rodata.parlio_tx_get_alignment_constraints.str1.4 .rodata.parlio_tx_unit_disable.str1.4 .rodata.parlio_tx_unit_enable.str1.4 .rodata.parlio_tx_unit_init_dma.str1.4 .rodata.parlio_tx_unit_register_event_callbacks.str1.4 .rodata.parlio_tx_unit_transmit.str1.4 .rodata.parlio_tx_unit_wait_all_done.str1.4)
 *libesp_driver_rmt.a:rmt_tx.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.10 .rodata.__FUNCTION__.12 .rodata.__FUNCTION__.13 .rodata.__FUNCTION__.14 .rodata.__FUNCTION__.15 .rodata.__FUNCTION__.19 .rodata.__FUNCTION__.21 .rodata.__FUNCTION__.22 .rodata.__FUNCTION__.3 .rodata.__FUNCTION__.4 .rodata.__FUNCTION__.5 .rodata.__FUNCTION__.6 .rodata.__FUNCTION__.7 .rodata.__FUNCTION__.9 .rodata.__func__.1 .rodata.__func__.11 .rodata.__func__.16 .rodata.__func__.17 .rodata.__func__.18 .rodata.__func__.2 .rodata.__func__.20 .rodata.__func__.8 .rodata.rmt_del_tx_channel.str1.4 .rodata.rmt_ll_tx_enable_dma.str1.4 .rodata.rmt_ll_tx_set_carrier_high_low_ticks.str1.4 .rodata.rmt_new_sync_manager.str1.4 .rodata.rmt_new_tx_channel.str1.4 .rodata.rmt_transmit.str1.4 .rodata.rmt_tx_create_trans_queue.str1.4 .rodata.rmt_tx_destroy.str1.4 .rodata.rmt_tx_disable.str1.4 .rodata.rmt_tx_enable.str1.4 .rodata.rmt_tx_init_dma_link.str1.4 .rodata.rmt_tx_register_event_callbacks.str1.4 .rodata.rmt_tx_register_to_group.str1.4 .rodata.rmt_tx_switch_gpio.str1.4 .rodata.rmt_tx_wait_all_done.str1.4)
 *libesp_hal_parlio.a:parlio_periph.*(.rodata.str1.4)
 *libesp_hw_support.a:adc_share_hw_ctrl.*(.rodata.__FUNCTION__.1 .rodata.__func__.0 .rodata.adc_lock_release.str1.4)
 *libesp_hw_support.a:cpu.*(.rodata.__func__.0 .rodata.__func__.1 .rodata.__func__.2)
 *libesp_hw_support.a:esp_clk_tree.*(.rodata.__FUNCTION__.2 .rodata.__FUNCTION__.3 .rodata.__func__.0 .rodata.__func__.1 .rodata.__func__.4 .rodata.__func__.5 .rodata.__func__.6 .rodata.__func__.7 .rodata.__func__.8 .rodata.clk_ll_pll_f50m_set_divider.str1.4 .rodata.esp_clk_tree_ref_500m_derived_acquire_parent.str1.4 .rodata.esp_clk_tree_ref_500m_set_src.str1.4 .rodata.esp_clk_tree_root_pll_power_acquire.str1.4 .rodata.esp_clk_tree_root_pll_power_release.str1.4 .rodata.esp_clk_tree_src_get_freq_hz.str1.4 .rodata.esp_clk_tree_src_set_freq_hz.str1.4 .rodata.s_derived_pll_descs .rodata.s_gated_ref_clks .rodata.s_ref_500m_upstreams)
 *libesp_hw_support.a:esp_clk_tree_common.*(.rodata.__FUNCTION__.1 .rodata.__FUNCTION__.3 .rodata.__FUNCTION__.6 .rodata.__FUNCTION__.7 .rodata.__func__.0 .rodata.__func__.10 .rodata.__func__.2 .rodata.__func__.4 .rodata.__func__.5 .rodata.__func__.8 .rodata.__func__.9 .rodata.clk_tree_rtc_slow_calibration.str1.4 .rodata.esp_clk_tree_apll_freq_set.str1.4 .rodata.esp_clk_tree_derived_clk_freq_set.str1.4 .rodata.esp_clk_tree_derived_clk_release.str1.4 .rodata.esp_clk_tree_lp_fast_get_freq_hz.str1.4 .rodata.esp_clk_tree_src_select_upstream.str1.4 .rodata.str1.4)
 *libesp_hw_support.a:sar_tsens_ctrl.*(.rodata.__func__.0)
 *libesp_hw_support.a:sleep_modes.*(.rodata.__func__.0 .rodata.esp_sleep_acquire_lp_use_xtal.str1.4 .rodata.esp_sleep_disable_ext1_wakeup_io.str1.4 .rodata.esp_sleep_disable_wakeup_source.str1.4 .rodata.esp_sleep_enable_ext1_wakeup_io.str1.4 .rodata.esp_sleep_pd_config.str1.4 .rodata.esp_sleep_release_lp_use_xtal.str1.4 .rodata.esp_sleep_sub_mode_config.str1.4 .rodata.esp_sleep_sub_mode_dump_config.str1.4 .rodata.s_sleep_hook_register.str1.4 .rodata.s_submode2str .rodata.str1.4)
 *libesp_phy.a:phy_init.*(.rodata.__func__.0 .rodata.__func__.1 .rodata.__func__.2 .rodata.__func__.4 .rodata.__func__.5 .rodata.__func__.6 .rodata.esp_phy_erase_cal_data_in_nvs.str1.4 .rodata.esp_phy_load_cal_and_init.str1.4 .rodata.esp_phy_load_cal_data_from_nvs.str1.4 .rodata.load_cal_data_from_nvs_handle.str1.4 .rodata.store_cal_data_to_nvs_handle.str1.4)
 *libesp_system.a:reset_reason.*(.rodata.__func__.0)
 *libesp_system.a:system_internal.*(.rodata.__func__.1)
 *libieee802154.a:esp_ieee802154.*(.rodata.__func__.0 .rodata.__func__.1 .rodata.__func__.10 .rodata.__func__.2 .rodata.__func__.3 .rodata.__func__.4 .rodata.__func__.5 .rodata.__func__.6 .rodata.__func__.7 .rodata.__func__.8 .rodata.__func__.9 .rodata.esp_ieee802154_get_power_table.str1.4 .rodata.esp_ieee802154_get_power_with_channel.str1.4 .rodata.esp_ieee802154_get_state.str1.4 .rodata.esp_ieee802154_set_ack_timeout.str1.4 .rodata.esp_ieee802154_set_channel.str1.4)
 *libieee802154.a:esp_ieee802154_ack.*(.rodata.__func__.0)
 *libieee802154.a:esp_ieee802154_dev.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.1 .rodata.__func__.2 .rodata.__func__.3 .rodata.__func__.4 .rodata.__func__.5 .rodata.__func__.6 .rodata.__func__.7 .rodata.ieee802154_mac_deinit.str1.4 .rodata.ieee802154_mac_init.str1.4 .rodata.ieee802154_rx_ack_timeout_callback.str1.4 .rodata.str1.4)
 *libieee802154.a:esp_ieee802154_frame.*(.rodata.__FUNCTION__.0 .rodata.__FUNCTION__.1 .rodata.__FUNCTION__.2 .rodata.__FUNCTION__.3 .rodata.__FUNCTION__.4 .rodata.str1.4)
 *libieee802154.a:esp_ieee802154_sec.*(.rodata.__func__.0)
 *libieee802154.a:esp_ieee802154_util.*(.rodata.__func__.0 .rodata.__func__.1 .rodata.__func__.2 .rodata.__func__.3 .rodata.bt_bb_get_tx_pwr_table.str1.4 .rodata.ieee802154_freq_to_channel.str1.4 .rodata.ieee802154_set_txrx_pti.str1.4)
 *libspi_flash.a:flash_ops.*(.rodata.__func__.0)
 *libspi_flash.a:spi_flash_os_func_app.*(.rodata.__func__.0 .rodata.__func__.1 .rodata.esp_flash_spi23_default_os_functions .rodata.str1.4)

    *(.got .got.plt) /* TODO: GCC-439 */
    *(.irom1.text) /* catch stray ICACHE_RODATA_ATTR */
    *(.gnu.linkonce.r.*)
    *(.rodata1)
    *(.gcc_except_table .gcc_except_table.*)
    *(.gnu.linkonce.e.*)
    . = ALIGN(ALIGNOF(.flash.init_array));
  } > flash_rodata_seg
  ASSERT((ADDR(.flash.init_array) == ADDR(.flash.rodata) + SIZEOF(.flash.rodata)), "The gap between .flash.rodata and .flash.init_array must not exist to produce the final bin image.")
  .flash.init_array :
  {
    /**
     * C++ constructor tables.
     *
     * Excluding crtbegin.o/crtend.o since IDF doesn't use the toolchain crt.
     */
    
 . = ALIGN(4); 
 __preinit_array_start = ABSOLUTE(.);
    
 . = ALIGN(4); 
 __bothinit_array_start = ABSOLUTE(.);
    KEEP (*(.preinit_array))
    __preinit_array_end = ABSOLUTE(.);
    
 . = ALIGN(4); 
 __init_array_start = ABSOLUTE(.);
    KEEP (*(SORT_BY_INIT_PRIORITY(EXCLUDE_FILE (*crtend.* *crtbegin.*) .init_array.*)))
    KEEP (*(EXCLUDE_FILE (*crtend.* *crtbegin.*) .init_array))
    __init_array_end = ABSOLUTE(.);
    __bothinit_array_end = ABSOLUTE(.);
    /* Addresses of memory regions reserved via SOC_RESERVE_MEMORY_REGION() */
    
 . = ALIGN(4); 
 soc_reserved_memory_region_start = ABSOLUTE(.);
    KEEP (*(.reserved_memory_address))
    soc_reserved_memory_region_end = ABSOLUTE(.);
    _rodata_end = ABSOLUTE(.);
    . = ALIGN(ALIGNOF(.flash.tdata));
  } > flash_rodata_seg
  ASSERT((ADDR(.flash.tdata) == ADDR(.flash.init_array) + SIZEOF(.flash.init_array)), "The gap between .flash.init_array and .flash.tdata must not exist to produce the final bin image.")
  .flash.tdata :
  {
    /**
     * IMPORTANT: Keep tdata and tbss sections contiguous (no gaps between them).
     * The TLS runtime code calculates offsets assuming these sections are
     * adjacent. Gaps would cause incorrect address calculations, leading
     * to accessing wrong memory.
     */
    /* Thread-local data sections */
    _thread_local_data_start = ABSOLUTE(.);
    _picolibc_reent_stub_start = ABSOLUTE(.);
    KEEP(*(.tdata.errno))
    /* Reproduce the public fields from struct _reent */
    KEEP(*(.tdata.tls_stdin))
    KEEP(*(.tdata.tls_stdout))
    KEEP(*(.tdata.tls_stderr))
    _picolibc_reent_stub_end = ABSOLUTE(.);
    *(.tdata .tdata.* .gnu.linkonce.td.*)
    . = ALIGN(ALIGNOF(.flash.tbss));
    _thread_local_data_end = ABSOLUTE(.);
  } > flash_rodata_seg
  ASSERT((ADDR(.flash.tbss) == ADDR(.flash.tdata) + SIZEOF(.flash.tdata)), "The gap between .flash.tdata and .flash.tbss must not exist to produce the final bin image.")
  ASSERT((_picolibc_reent_stub_end - _picolibc_reent_stub_start) == 16, "Newlib _reent stub have wrong size")
  .flash.tbss (NOLOAD) :
  {
    /* Thread-local BSS sections */
    _thread_local_bss_start = ABSOLUTE(.);
    *(.tbss .tbss.* .gnu.linkonce.tb.*)
    *(.tcommon .tcommon.*)
    _thread_local_bss_end = ABSOLUTE(.);
  } > flash_rodata_seg
  ASSERT(_thread_local_data_end == _thread_local_bss_start,
         "tdata and tbss must be contiguous.")
  /**
   * This section contains all the rodata that is not used at runtime,
   * helping to avoid an increase in binary size.
   */
  .flash.rodata_noload (NOLOAD) :
  {
    /**
     * This symbol marks the end of flash.rodata. It can be utilized by the MMU
     * driver to maintain the virtual address.
     * NOLOAD rodata may not be included in this section.
     */
    _rodata_reserved_end = .;
    
 *(.rodata_wlog_debug .rodata_wlog_debug.*)
 *(.rodata_wlog_verbose .rodata_wlog_verbose.*)
  } > flash_rodata_seg
  /**
   * If rodata default segment is placed in `flash_rodata_seg`, then flash's first
   * rodata section must also be first in the segment.
   */
  ASSERT(_flash_rodata_dummy_start == ORIGIN(flash_rodata_seg),
         ".flash_rodata_dummy section must be placed at the beginning of the rodata segment.")
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  .dram0.heap_start (NOLOAD) :
  {
    
 . = ALIGN(16); 
 _heap_start = ABSOLUTE(.);
  } > dram_seg
  ASSERT(((_heap_start - ORIGIN(dram_seg)) <= LENGTH(dram_seg)),
          "DRAM segment data does not fit.")
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  /**
   * This section is not included in the binary image; it is only present in the ELF file.
   * It is used to keep certain symbols in the ELF file.
   */
  .noload 0 (INFO) :
  {
    /* Reserve first 4 bytes as zero for vars pointed to NULL */
    . = 0;
    LONG(0);
    _noload_keep_in_elf_start = ABSOLUTE(.);
    
    KEEP(*(.noload_keep_in_elf .noload_keep_in_elf.*))
    _noload_keep_in_elf_end = ABSOLUTE(.);
  }
  /* DWARF 1 */
  .debug 0 : { *(.debug) }
  .line 0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo 0 : { *(.debug_srcinfo) }
  .debug_sfnames 0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges 0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info 0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev 0 : { *(.debug_abbrev) }
  .debug_line 0 : { *(.debug_line) }
  .debug_frame 0 : { *(.debug_frame) }
  .debug_str 0 : { *(.debug_str) }
  .debug_loc 0 : { *(.debug_loc) }
  .debug_macinfo 0 : { *(.debug_macinfo) }
  .debug_pubtypes 0 : { *(.debug_pubtypes) }
  /* DWARF 3 */
  .debug_ranges 0 : { *(.debug_ranges) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames 0 : { *(.debug_varnames) }
  /* GNU DWARF 2 extensions */
  .debug_gnu_pubnames 0 : { *(.debug_gnu_pubnames) }
  .debug_gnu_pubtypes 0 : { *(.debug_gnu_pubtypes) }
  /* DWARF 4 */
  .debug_types 0 : { *(.debug_types) }
  /* DWARF 5 */
  .debug_addr 0 : { *(.debug_addr) }
  .debug_line_str 0 : { *(.debug_line_str) }
  .debug_loclists 0 : { *(.debug_loclists) }
  .debug_macro 0 : { *(.debug_macro) }
  .debug_names 0 : { *(.debug_names) }
  .debug_rnglists 0 : { *(.debug_rnglists) }
  .debug_str_offsets 0 : { *(.debug_str_offsets) }
  /**
   * Miscellaneous sections
   */
  .comment 0 : { *(.comment) }
  .note.GNU-stack 0 : { *(.note.GNU-stack) }
  .riscv.attributes 0 : { *(.riscv.attributes) }
/**
 * .xt.prop and .xt.lit sections will be used by the debugger and disassembler
 * to get more information about raw data present in the code.
 * Indeed, it may be required to add some padding at some points in the code
 * in order to align a branch/jump destination on a particular bound.
 * Padding these instructions will generate null bytes that shall be
 * interpreted as data, and not code by the debugger or disassembler.
 * This section will only be present in the ELF file, not in the final binary
 * For more details, check GCC-212
 */
  .xtensa.info 0 : { *(.xtensa.info) }
  .xt.prop 0 : { *(.xt.prop .xt.prop.* .gnu.linkonce.prop.*) }
  .xt.lit 0 : { *(.xt.lit .xt.lit.* .gnu.linkonce.p.*) }
/*
 * SPDX-FileCopyrightText: 2021-2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* CPU instruction prefetch padding size for flash mmap scenario */
/*
 * PMP region granularity size
 * Software may determine the PMP granularity by writing zero to pmp0cfg, then writing all ones
 * to pmpaddr0, then reading back pmpaddr0. If G is the index of the least-significant bit set,
 * the PMP granularity is 2^G+2 bytes.
 */
/* CPU instruction prefetch padding size for memory protection scenario */
/* Memory alignment size for PMS */
    /* rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files). For rtc_timer_data_in_rtc_mem section. */
/*
 * APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING
 *
 * Aligns the current location (.) to CONFIG_APP_BUILD_MINIMIZE_BINARY_CHANGES_PADDING.
 * If more than half of the alignment block is already consumed,
 * extra padding is applied to skip to the next boundary.
 * For example, if the current location (.) is 0x1900 and the padding is 4 KB,
 * the location will be moved to 0x3000 instead of 0x2000 because less than
 * half of the current 4 KB block remains (0x2000 - 0x1900 < 2 KB).
 */
  /DISCARD/ :
  {
   /**
    * Discarding .rela.* sections results in the following mapping:
    * .rela.text.* -> .text.*
    * .rela.data.* -> .data.*
    * And so forth...
    */
   *(.rela.*)
   *(.fini)
   *(.eh_frame_hdr)
   *(.eh_frame)
  }
}
