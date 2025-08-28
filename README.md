# Полное руководство по созданию дерева устройств TWRP для Android-устройств

Это руководство представляет собой исчерпывающий ресурс для разработчиков и энтузиастов, стремящихся создать или портировать кастомное рекавери Team Win Recovery Project (TWRP) для Android-устройств. Оно охватывает весь цикл разработки: от теоретической подготовки и сбора данных до компиляции образа и устранения ошибок. Особое внимание уделено специфике работы с современными версиями Android, включая TWRP на базе Android 12.1 и экспериментальную ветку для Android 14. Руководство структурировано для удобства: может использоваться как пошаговая инструкция или справочник по отдельным этапам.

TWRP — это открытое программное обеспечение, заменяющее стандартное рекавери Android с ограниченными функциями (сброс настроек, OTA-обновления) на полнофункциональный сенсорный интерфейс. TWRP позволяет устанавливать кастомные прошивки, модификации, создавать полные резервные копии (nandroid backups) и управлять файлами на всех разделах, что делает его незаменимым инструментом для кастомизации и восстановления Android-устройств.

Термин "Device Tree" (DT) в разработке Android может вводить в заблуждение. На базовом уровне DT — это структура данных, описывающая аппаратные компоненты (SoC, память, периферия), которые ядро Linux не может обнаружить автоматически. Производители создают файлы Device Tree Source (.dts), компилируемые в Device Tree Blob (.dtb) для передачи информации ядру через загрузчик. Однако "дерево устройств TWRP" — это репозиторий с конфигурационными файлами для сборочной системы TWRP, основанной на AOSP. Эти файлы (BoardConfig.mk, recovery.fstab, twrp_*.mk и др.) определяют, как скомпилировать recovery.img для конкретного устройства, используя DTB и проприетарные файлы. Создание дерева — это написание правил для сборки кастомного рекавери.

Для компиляции TWRP требуется 64-битная Linux-система (например, Ubuntu) с минимум 128 ГБ свободного места на диске и 8 ГБ RAM. Необходимые инструменты: adb и fastboot для взаимодействия с устройством; repo для синхронизации кода из Git-репозиториев (выполняет git clone/rebase); git для управления версиями; Python 3.8+ и cpio для скриптов, таких как twrpdtgen. TWRP использует стандартную систему сборки AOSP, поэтому знание repo, lunch и mka обязательно.

Соберите ключевые файлы с устройства для основы конфигурации. Извлеките recovery.img (или boot.img для A/B-устройств): `adb shell su -c "dd if=/dev/block/by-name/recovery of=/sdcard/recovery.img" && adb pull /sdcard/recovery.img`. Файл /system/build.prop (или /product/build.prop) содержит переменные: ro.product.device (кодовое имя), ro.product.board (платформа чипсета), ro.product.brand и ro.product.manufacturer. Неполные данные приведут к ошибкам компиляции или неработоспособному образу.

twrpdtgen — Python-скрипт для генерации базовой структуры дерева, идеальный для новичков. Установите: `pip3 install twrpdtgen`, затем cpio: `sudo apt install cpio`, и запустите: `python3 -m twrpdtgen <path/to/recovery.img>`. Результат: дерево в `output/manufacturer/codename`. Ограничения: поддержка до Android 12; для 12.1+ нужна ручная доработка. Это "черновик", а не финальная версия.

Дерево в `device/<brand>/<codename>` содержит: Android.mk (определяет модули для сборки); AndroidProducts.mk (связывает продукты с twrp_*.mk); BoardConfig.mk (центральный конфиг); recovery.fstab (таблица монтирования разделов); vendorsetup.sh (добавляет продукт в AOSP, например, `add_lunch_combo twrp_<codename>-eng`); twrp_*.mk (основной файл продукта, наследует настройки TWRP).

Ramdisk — виртуальный диск в RAM с файлами для запуска. recovery.img содержит ядро и ramdisk рекавери (init.rc, recovery.fstab); boot.img — ядро и ramdisk ОС; vendor_boot.img (для A/B-устройств) содержит vendor-код. Извлеките файлы из стокового образа: prebuilt для ядра, recovery/root для ramdisk.

BoardConfig.mk — "сердце" дерева. Пример для устройства Tecno LH7n (на базе MT6789):

```makefile
# Copyright (C) 2022 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

DEVICE_PATH := device/tecno/LH7n

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_USES_64_BIT_BINDER := true
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := mt6789
TARGET_NO_BOOTLOADER := true

# Build hacks
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# DTBO
BOARD_KERNEL_SEPARATED_DTBO := true

# Kernel
TARGET_NO_KERNEL := true
BOARD_RAMDISK_USE_LZ4 := true
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img

BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_TAGS_OFFSET := 0x07c88000
BOARD_PAGE_SIZE := 4096
BOARD_TAGS_OFFSET := 0x07c88000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_DTB_SIZE := 209018
BOARD_DTB_OFFSET := 0x07c88000
BOARD_VENDOR_BASE := 0x3fff8000
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2

BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_MKBOOTIMG_ARGS += --vendor_cmdline $(BOARD_VENDOR_CMDLINE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_PAGE_SIZE) --board ""
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# Assert
TARGET_OTA_ASSERT_DEVICE := Tecno-LH7n

# AVB
BOARD_AVB_ENABLE := true

# Partitions configs
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_MAIN_SIZE := 12670140416
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_USES_METADATA_PARTITION := true
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_PARTITION_LIST += \
    odm_dlkm \
    product \
    system \
    system_ext \
    vendor \
    vendor_dlkm

BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Platform
TARGET_BOARD_PLATFORM := mt6789

# VNDK
BOARD_VNDK_VERSION := current

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Recovery
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
TARGET_NO_RECOVERY := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Crypto
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_USE_FSCRYPT_POLICY := 2
TW_FORCE_KEYMASTER_VER := true
OF_DEFAULT_KEYMASTER_VERSION := 4.1

# Hack
PLATFORM_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Tools
TW_INCLUDE_FB2PNG := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LPTOOLS := true

# TWRP Configs
TW_DEFAULT_BRIGHTNESS := 80
TW_EXCLUDE_APEX := true
TW_EXCLUDE_LPDUMP := true
TW_EXTRA_LANGUAGES := true
TW_FRAMERATE := 60
TW_THEME := portrait_hdpi
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TARGET_USES_MKE2FS := true
TW_MAX_BRIGHTNESS := 255
TW_LOAD_VENDOR_BOOT_MODULES := true

# StatusBar
TW_STATUS_ICONS_ALIGN := center
TW_CUSTOM_CPU_POS := "300"
TW_CUSTOM_CLOCK_POS := "70"
TW_CUSTOM_BATTERY_POS := "790"

# Hack depends
ALLOW_MISSING_DEPENDENCIES := true

# Maintainer
TW_DEVICE_VERSION := LH7n-Andreyka445-KSN
```
Проверьте TW_BRIGHTNESS_PATH в sysfs устройства, так как он часто вызывает проблемы с дисплеем (например, черный экран).
TWRP требует проприетарные файлы (vendor blobs) из /vendor для драйверов и расшифровки. Пример device.mk для Tecno LH7n:
```makefile
# Copyright (C) 2022 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

# Enable Virtual A/B OTA
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

ENABLE_VIRTUAL_AB := true
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    lk \
    odm \
    odm_dlkm \
    product \
    system \
    system_ext \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/mtk_plpath_utils \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh

PRODUCT_PROPERTY_OVERRIDES += ro.twrp.vendor_boot=true

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# API
PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_TARGET_VNDK_VERSION := 31

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-mtkimpl \
    android.hardware.boot@1.2-mtkimpl.recovery

PRODUCT_PACKAGES_DEBUG += \
    bootctl

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# Health Hal
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.keymaster@4.1

# Keystore Hal
PRODUCT_PACKAGES += \
    android.system.keystore2

# MTK plpath utils
PRODUCT_PACKAGES += \
    mtk_plpath_utils \
    mtk_plpath_utils.recovery

# Security
PRODUCT_PACKAGES += \
    android.hardware.security.keymint \
    android.hardware.security.secureclock \
    android.hardware.security.sharedsecret

# Update engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Additional configs
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.keymaster@4.1

TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.keymaster@4.1
```
Эти пакеты обеспечивают доступ к зашифрованным данным (FBE) и поддержку A/B-архитектуры. Файл recovery/root/system/etc/twrp.flags настраивает поведение TWRP, например, для поддержки прошивки разделов и обхода проблем с GSI.
Каждая версия Android меняет AOSP (init, sepolicy, безопасность). Дерево для Android 11 не подойдет для 12.1/14 без правок. TWRP 12.1 (на базе Android 12.1) — стабильная ветка, требующая TW_INCLUDE_CRYPTO_FBE, AB_OTA_UPDATER := true для A/B и поддержки vendor_boot. TWRP 14.1 (Android 14) экспериментальна, с проблемами: error 255 в бэкапах data, отсутствие вибрации, сложности с форматированием data (нужен fastboot). Могут требоваться файлы вроде task_profiles.json для logcat.
Для сборки TWRP выполните:

Синхронизация:
```bash
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1  # Для 12.1; для 14 используйте соответствующую ветку
repo sync
```
Сборка:
```bash
source build/envsetup.sh
lunch twrp_<codename>-eng
# тут надо выбрать какой у вас раздел
mka recoveryimage  
mka bootimage      
mka vendorbootimage 
```

Создание дерева TWRP — сложный процесс, требующий глубокого понимания Android. twrpdtgen — хорошая отправная точка, но необходима ручная доработка. TWRP 14.1 экспериментальна и содержит ошибки, поэтому новичкам рекомендуется начинать с TWRP 12.1. Примеры BoardConfig.mk и device.mk для Tecno LH7n иллюстрируют настройку для современных устройств с A/B-архитектурой.
