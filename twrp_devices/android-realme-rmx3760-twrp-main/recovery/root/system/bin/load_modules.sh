#!/sbin/sh

# Team Hovatek Touch Fix
load_panel()
{
	insmod /lib/modules/gslX680.ko
	insmod /lib/modules/adaptive-ts.ko
	insmod /lib/modules/gpio.ko
	insmod /lib/modules/gpio-sprd.ko
	insmod /lib/modules/focaltech_ft8756_spi_ts.ko
	insmod /lib/modules/nvt_nt36xxx_spi_ts.ko
	insmod /lib/modules/fortsense_fp.ko
	insmod /lib/modules/sc27xx_tsensor_thermal.ko
	insmod /lib/modules/tran_gesture.ko
}


load_panel
wait 1
setprop modules.loaded 1
exit 0
