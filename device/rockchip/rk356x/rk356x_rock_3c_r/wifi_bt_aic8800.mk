#
# AIC8800 wifi bt config
#

#
# BOARD_CONNECTIVITY_VENDOR:
# for AIC8800 wifi, bt
# AIC:
#           aic8800,           #AIC8800 WiFi and Bluetooth combo
#
# AIC8800 is a WiFi + Bluetooth combo chip that supports:
# - WiFi: 802.11 b/g/n/ac
# - Bluetooth: 4.2/5.0 BLE
# - Interface: SDIO for WiFi, UART for Bluetooth
#
# The firmware is embedded in the kernel driver as C arrays
# in aicwf_firmware_array.c, so no external firmware files needed
#

BOARD_CONNECTIVITY_VENDOR := AIC
BOARD_CONNECTIVITY_MODULE := aic8800

# WiFi configuration for AIC8800 (using standard nl80211)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_WLAN_DEVICE := bcmdhd

# Disable firmware path switching (aic8800 doesn't use it like Broadcom)
WIFI_DRIVER_FW_PATH_PARAM := ""
WIFI_DRIVER_FW_PATH_STA := ""
WIFI_DRIVER_FW_PATH_P2P := ""
WIFI_DRIVER_FW_PATH_AP := ""

# Bluetooth configuration
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_AIC := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/rockchip/rk356x/bluetooth

# Include AIC Bluetooth vendor library
$(call inherit-product-if-exists, hardware/aic/aicbt/aicbt.mk)

# Enable wireless
BOARD_HAVE_WIFI := true

# AIC8800 specific configuration
# The driver modules are built as loadable modules:
# - aic8800_bsp: Base support platform driver
# - aic8800_fdrv: WiFi driver
# - aic8800_btlpm: Bluetooth low power mode driver

# Module loading order (handled by init scripts):
# 1. aic8800_bsp (base platform support)
# 2. aic8800_fdrv (WiFi driver)
# 3. aic8800_btlpm (Bluetooth driver)

# Firmware path (set in kernel config)
# CONFIG_AIC_FW_PATH="/vendor/etc/firmware"
# Note: Firmware is embedded in driver source, not external files

PRODUCT_COPY_FILES += \
    kernel/drivers/net/wireless/aic8800/aic8800_bsp/aic8800_bsp.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aic8800_bsp.ko \
    kernel/drivers/net/wireless/aic8800/aic8800_fdrv/aic8800_fdrv.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aic8800_fdrv.ko \
    kernel/drivers/net/wireless/aic8800/aic8800_btlpm/aic8800_btlpm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aic8800_btlpm.ko
