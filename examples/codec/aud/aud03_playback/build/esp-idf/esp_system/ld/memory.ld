/*
 * SPDX-FileCopyrightText: 2025 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 *                    ESP32-S31 Linker Script Memory Layout
 * This file describes the memory layout (memory blocks) by virtual memory addresses.
 * This linker script is passed through the C preprocessor to include configuration options.
 * Please use preprocessor features sparingly!
 * Restrict to simple macros with numeric values, and/or #if/#endif blocks.
 */
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
/*
 * SPDX-FileCopyrightText: 2026 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/* ESP32-S31 target-specific HP memory definitions shared between HP app and LP Core linker scripts */
MEMORY
{
  /* Flash mapped instruction data */
  irom_seg (RX) : org = 0x40000020, len = (0x10000 << 10) - 0x20
  /**
   * (0x20 offset above is a convenience for the app binary image generation.
   * Flash cache has 64KB pages. The .bin file which is flashed to the chip
   * has a 0x18 byte file header, and each segment has a 0x08 byte segment
   * header. Setting this offset makes it simple to meet the flash cache MMU's
   * constraint that (paddr % 64KB == vaddr % 64KB).)
   */
  /**
   * Shared data RAM, excluding memory reserved for ROM bss/data/stack.
   * Enabling Bluetooth & Trace Memory features in menuconfig will decrease the amount of RAM available.
   */
  sram_seg (RWX) : org = 0x2F000000, len = (0x2F07AFC0 - 0x2F000000)
  /* Flash mapped constant data */
  drom_seg (R) : org = 0x40000020, len = (0x10000 << 10) - 0x20
  /* (See irom_seg for meaning of 0x20 offset in the above.) */
  /**
 *  LP RAM (RTC Memory) Layout for ESP32-S31
 *  Total Size: 32KB (0x8000)
 *  Address Range: 0x2E000000 - 0x2E008000
 *
 *  ESP32-S31 has only unified LP RAM (no separate RTC FAST/SLOW).
 *  The LP RAM persists over deep sleep and is used for:
 *  - ULP coprocessor code and data (optional)
 *  - RTC wake stub code and data
 *  - Data that needs to survive deep sleep
 *  - Bootloader retain memory (for reboot counter, OTA info, etc.)
 *
 *  +-----------------------------+ 0x2E008000 (LP RAM end)
 *  | Secure Boot Image Digest    | ( For ROM using, must keep it at the end CONFIG_SECURE_BOOT_ROM_FAST_WAKE_RESERVE_SIZE bytes of LP RAM)
 *  | for fast wake secure boot.  |
 *  |(only if CONFIG_SECURE_BOOT) |
 *  |- - - - - - - - - - - - - - -|
 *  | bootloader_data_rtc_mem     |
 *  | (ESP_BOOTLOADER_RESERVE_RTC)| lp_reserved_seg (RESERVE_RTC_MEM)
 *  |- - - - - - - - - - - - - - -|
 *  | rtc_timer_data_in_rtc_mem   |
 *  | (RTC_TIMER_RESERVE_RTC=24B) |
 *  +-----------------------------+ 0x2E008000 - RESERVE_RTC_MEM
 *  | .rtc.force_slow             |
 *  | .rtc_noinit (NOLOAD)        |
 *  | .rtc.bss (NOLOAD)           |
 *  | .rtc.data                   | lp_ram_seg (= rtc_iram_seg = rtc_data_seg = rtc_slow_seg)
 *  | .rtc.force_fast             |
 *  |- - - - - - - - - - - - - - -|
 *  | .rtc.text                   | RTC wake stub code
 *  +-----------------------------+ 0x2E000000 + CONFIG_ULP_COPROC_RESERVE_MEM (if ULP enabled)
 *  | ULP Coprocessor Reserve     | (Optional, CONFIG_ULP_COPROC_RESERVE_MEM)
 *  | (code + data)               |
 *  +-----------------------------+ 0x2E000000 (LP RAM start)
 */
  /**
   * lp ram memory (RWX). Persists over deep sleep.
   */
  lp_ram_seg(RW) : org = 0x2E000000, len = 0x8000 - (0 + (24) + 0)
  /* We reduced the size of lp_ram_seg by RESERVE_RTC_MEM value.
     It reserves the amount of LP memory that we use for this memory segment.
     This segment is intended for keeping:
       - (lower addr) rtc timer data (s_rtc_timer_retain_mem, see esp_clk.c files).
       - (higher addr) bootloader rtc data (s_bootloader_retain_mem, when a Kconfig option is on).
     The aim of this is to keep data that will not be moved around and have a fixed address.
  */
  lp_reserved_seg(RW) : org = 0x2E000000 + 0x8000 - (0 + (24) + 0), len = (0 + (24) + 0)
  /* PSRAM seg */
  extern_ram_seg(RWX) : org = 0x50000000, len = (0x10000 << 10)
}
/* Heap ends at top of dram0_0_seg */
_heap_end = 0x40000000;
REGION_ALIAS("iram_text_seg", sram_seg);
REGION_ALIAS("dram_seg", sram_seg);
/**
 *  The lines below define location alias for .rtc.data section
 *  S31 has no distinguished LP(RTC) fast and slow memory sections, instead, there is a unified LP_RAM section
 *  Thus, the following region segments are not configurable like on other targets
 */
REGION_ALIAS("rtc_text_seg", lp_ram_seg);
REGION_ALIAS("rtc_data_seg", lp_ram_seg);
REGION_ALIAS("rtc_slow_seg", lp_ram_seg);
REGION_ALIAS("rtc_force_fast_seg", lp_ram_seg);
REGION_ALIAS("rtc_force_slow_seg", lp_ram_seg);
REGION_ALIAS("rtc_reserved_seg", lp_reserved_seg);
  REGION_ALIAS("flash_text_seg", irom_seg);
  REGION_ALIAS("flash_rodata_seg", drom_seg);
  REGION_ALIAS("ext_ram_seg", extern_ram_seg);
ALIGN_VECTOR_TABLE = 0x40;
