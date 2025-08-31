# 📘 Полное руководство по созданию TWRP для Unisoc устройств
🔍 Введение в TWRP и основные понятия
TWRP (Team Win Recovery Project) — это кастомное рекавери для Android-устройств, которое заменяет стандартное рекавери с ограниченными функциями. TWRP предоставляет полнофункциональный сенсорный интерфейс и расширенные возможности для управления устройством7.

- Boot Control HAL — это критически важный компонент Android, который управляет механизмом A/B (Seamless) обновлений. Для устройств на разных чипсетах (Unisoc, MediaTek, Qualcomm) этот компонент имеет свои специфические реализации.

- Device Tree (DT) в разработке Android — это структура данных, описывающая аппаратные компоненты (SoC, память, периферия).
- "Дерево устройств TWRP" — это репозиторий с конфигурационными файлами для сборочной системы TWRP6.

# 🏗️ Архитектура Unisoc устройств
🔧 Особенности Unisoc процессоров
- Unisoc (ранее Spreadtrum) процессоры имеют свою специфику, которую необходимо учитывать при создании TWRP. Основные отличия от MediaTek:
- Архитектура процессора: Unisoc использует комбинацию Cortex-A75 и Cortex-A55
- Параметры ядра: Различные параметры командной строки и размер страницы (обычно 2048 вместо 4096)
- Boot Control HAL: Специфичная реализация для Unisoc платформ
- Пути к оборудованию: Различные sysfs пути для управления дисплеем и другим оборудованием

📊 Ключевые характеристики Unisoc Tiger T610 (ums512) (realme c21y)
```makefile
# Архитектура Unisoc Tiger T610
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a75

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# Платформа и загрузчик
TARGET_BOARD_PLATFORM := ums512
TARGET_BOOTLOADER_BOARD_NAME := ums512_1h10
TARGET_NO_BOOTLOADER := false
```
# 🛠️ Создание Device Tree для Unisoc
📋 Структура дерева устройств
Дерево устройств TWRP для Unisoc располагается в device/<brand>/<codename> и содержит:

- Android.mk: Определяет модули для сборки
- AndroidProducts.mk: Связывает продукты с twrp_*.mk
- BoardConfig.mk: Центральный конфигурационный файл
- recovery.fstab: Таблица монтирования разделов
- vendorsetup.sh: Добавляет продукт в AOSP
- twrp_*.mk: Основной файл продукта

⚙️ BoardConfig.mk для realme c21y
```makefile
#
# Copyright (C) 2024 The TWRP Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE_PATH := device/realme/RMX3261

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 := 
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a75

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# 64-bit поддержка
TARGET_SUPPORTS_64_BIT_APPS := true
TARGET_IS_64_BIT := true
TARGET_USES_64_BIT_BINDER := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := ums512_1h10
TARGET_NO_BOOTLOADER := false

# Display
TARGET_SCREEN_DENSITY := 320

# Kernel (Unisoc специфика)
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_CMDLINE := console=ttyS1,115200n8 video=HDMI-A-1:1280x800@60 buildvariant=user
BOARD_KERNEL_CMDLINE += androidboot.init_fatal_reboot_target=recovery
BOARD_KERNEL_PAGESIZE := 2048  # Unisoc обычно использует 2048 вместо 4096
BOARD_RAMDISK_OFFSET := 0x05400000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
TARGET_KERNEL_CONFIG := RMX3261_defconfig
TARGET_KERNEL_SOURCE := kernel/realme/RMX3261

# Kernel - prebuilt
TARGET_FORCE_PREBUILT_KERNEL := true
ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_INCLUDE_DTB_IN_BOOTIMG := 
endif

# AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_VBMETA_SYSTEM := system
BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 2

# Platform
TARGET_BOARD_PLATFORM := ums512

# Security patch обход
PLATFORM_SECURITY_PATCH := 2022-07-05
PLATFORM_VERSION := 11.0.0
VENDOR_SECURITY_PATCH := 2022-07-05

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
BOARD_USES_RECOVERY_AS_BOOT := true
TARGET_NO_RECOVERY := true
TARGET_USES_MKE2FS := true

# System properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Unisoc specific modules
TARGET_RECOVERY_DEVICE_MODULES += \
    libcap \
    libion \
    libxml2 \
    libandroidicu

TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libcap.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libxml2.so

## Inherit partitions flags
include device/realme/RMX3261/partitions.mk

## Inherit TWRP flags
include device/realme/RMX3261/TW_flags.mk
```
🔧 TW_flags.mk для realme c21y
```makefile
# Build hacks
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true
BUILD_BROKEN_PREBUILT_ELF_FILES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true
RELAX_USES_LIBRARY_CHECK := true

# TWRP Configuration
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_BRIGHTNESS_PATH := "/sys/devices/platform/soc/soc:ap-ahb/20400000.dsi/20400000.dsi.0/display/panel0/sprd_backlight/brightness"
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_NTFS_3G := true
TW_USE_TOOLBOX := true
RECOVERY_SDCARD_ON_DATA := true
TW_USE_EXTERNAL_STORAGE := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_EXCLUDE_TWRPAPP := true
TW_NO_BIND_SYSTEM := true
TW_NO_SCREEN_BLANK := true
TW_NO_LEGACY_PROPS := true
TW_OVERRIDE_SYSTEM_PROPS := "ro.build.version.sdk"
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
TW_DEFAULT_BRIGHTNESS := 500
TW_MAX_BRIGHTNESS := 4000

# Maintainer info
BOARD_MAINTAINER_NAME := KSN
TW_DEVICE_VERSION := $(BOARD_MAINTAINER_NAME)
OF_MAINTAINER := $(BOARD_MAINTAINER_NAME)
PB_MAIN_VERSION := $(BOARD_MAINTAINER_NAME)

# Resetprop & repacktools
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_LIBRESETPROP := true

# Debugging
TWRP_EVENT_LOGGING := true
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true

# Kernel modules
TW_LOAD_VENDOR_MODULES := "incrementalfs.ko kheaders.ko trace_irqsoff_bytedancy.ko trace_noschedule_bytedancy.ko trace_runqlat_bytedancy.ko"
```
📊 Partitions.mk для realme c21y
```makefile
# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vbmeta_product \
    vbmeta_system_ext \
    dtbo \
    boot \
    system \
    system_ext \
    vendor \
    product

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072 
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Filesystem types
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# Copy out directories
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext

# Dynamic partitions
BOARD_SUPER_PARTITION_SIZE := 9126805504 
BOARD_SUPER_PARTITION_GROUPS := realme_dynamic_partitions
BOARD_REALME_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext vendor product
BOARD_REALME_DYNAMIC_PARTITIONS_SIZE := 9122611200 

# Symbolic links
BOARD_ROOT_EXTRA_SYMLINKS := \
    /vendor/bt_firmware:/bt_firmware \
    /mnt/vendor/socko:/socko \
    /mnt/sdcard/:sdcrad \
    /system/product/:product \
    /system/system_ext/:system_ext
```
📦 Device.mk для realme c21y
```makefile
#
# Copyright (C) 2024 The TWRP Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := device/realme/RMX3261

# Dynamic partitions support
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# A/B configuration
TARGET_IS_VAB := true
ENABLE_VIRTUAL_AB := true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# F2FS utilities
PRODUCT_PACKAGES += \
    sg_write_buffer \
    f2fs_io \
    check_f2fs

# Userdata checkpoint
PRODUCT_PACKAGES += \
    checkpoint_gc

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

# Health HAL
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Unisoc specific bootctrl HAL
PRODUCT_PACKAGES += \
    bootctrl.default \
    bootctrl.unisoc \
    bootctrl.ums512.recovery

# OTA packages
PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh \
    update_engine \
    update_verifier \
    update_engine_sideload \
    checkpoint_gc

PRODUCT_PACKAGES_DEBUG += \
    bootctl

# Fastbootd
PRODUCT_PACKAGES += \
    fastbootd \
    android.hardware.fastboot@1.0-impl-mock \
    android.hardware.fastboot@1.0-impl-mock.recovery

# HIDL
PRODUCT_ENFORCE_VINTF_MANIFEST := true
```
# 📚 Заключение
Создание TWRP для устройств на Unisoc требует учета специфических особенностей этой платформы.
