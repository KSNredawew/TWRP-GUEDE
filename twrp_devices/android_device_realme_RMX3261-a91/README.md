### TWRP device tree for Realme C21Y (RMX3261)

=========================================

The Realme C21Y (codenamed _"RMX3261'RMX3262'RMX3263"_) is a mid-range smartphone from Realme.

It was released in 2021, July 02.

## Device specifications

Basic   | Spec Sheet
-------:|:-------------------------
CPU     | Octa-core (2x1.8 GHz Cortex-A75 & 6x1.8 GHz Cortex-A55)
Chipset | Unisoc T610 (12 nm)
GPU     | Mali-G52 MP2
Memory  | 3GB,4GB RAM
Shipped Android Version | 11 GO
Storage | 32GB,64GB eMMC 5.1
Battery | 5000 mAh, non-removable
Display | 720 x 1600 pixels, 20:9 ratio (~270 ppi density)

## Features

Blocking checks
- [X] Correct screen/recovery size
- [X] Working Touch, screen
- [X] Backup to internal/microSD
- [X] Restore from internal/microSD
- [X] reboot to system
- [X] ADB


Medium checks
- [X] update.zip sideload
- [X] UI colors (red/blue inversions)
- [X] Screen goes off and on
- [X] F2FS/EXT4 Support, exFAT/NTFS where supported
- [X] all important partitions listed in mount/backup lists
- [X] backup/restore to/from external (USB-OTG) storage
- [X] backup/restore to/from adb (https://gerrit.omnirom.org/#/c/15943/)
- [ ] decrypt /data
- [X] Correct date


Minor checks
- [X] MTP export
- [X] reboot to bootloader
- [X] reboot to recovery
- [X] poweroff
- [X] battery level
- [X] temperature
- [ ] encrypted backups
- [X] input devices via USB (USB-OTG) - keyboard, mouse and disks
- [ ] USB mass storage export (device does not support it)
- [X] set brightness
- [ ] vibrate
- [X] screenshot
- [X] partition SD card

## Compile

First checkout minimal twrp with aosp tree:

```
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-11
repo sync -j$(nproc --all)
```

Then add these projects to .repo/manifest.xml:

```xml
<project path="device/realme/RMX3261" name="GitFASTBOOT/android_device_realme_RMX3261" remote="github" revision="android-11" />
```

Finally execute these:

```
source build/envsetup.sh
repopick <needed patch>
lunch twrp_RMX3261-eng
mka bootimage -j$(nproc --all)
```
