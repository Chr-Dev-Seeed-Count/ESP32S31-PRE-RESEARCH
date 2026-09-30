# Install script for directory: D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Program Files (x86)/lcd_06_jpeg_ui")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "D:/Espressif/tools/riscv32-esp-elf/esp-16.1.0_20260609/riscv32-esp-elf/bin/riscv32-esp-elf-objdump.exe")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/mbedtls" TYPE FILE PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ FILES
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/build_info.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/debug.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/error.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/mbedtls_config.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/net_sockets.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/oid.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/pkcs7.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/ssl.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/ssl_cache.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/ssl_ciphersuites.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/ssl_cookie.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/ssl_ticket.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/timing.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/version.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/x509.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/x509_crl.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/x509_crt.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/x509_csr.h"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/mbedtls/private" TYPE FILE PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ FILES
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/private/config_adjust_ssl.h"
    "D:/Espressif-master/.espressif/master/esp-idf/components/mbedtls/mbedtls/include/mbedtls/private/config_adjust_x509.h"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "D:/ESP32S31/examples/lcd/lcd_06_jpeg_ui/build/esp-idf/mbedtls/mbedtls/include/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
