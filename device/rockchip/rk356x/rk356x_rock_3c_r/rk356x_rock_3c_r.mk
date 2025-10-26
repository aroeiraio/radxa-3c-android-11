#
# Copyright 2014 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# First lunching is R, api_level is 30
PRODUCT_SHIPPING_API_LEVEL := 30
PRODUCT_DTBO_TEMPLATE := $(LOCAL_PATH)/dt-overlay.in
PRODUCT_SDMMC_DEVICE := fe2b0000.dwmmc

include device/rockchip/common/build/rockchip/DynamicPartitions.mk
include $(LOCAL_PATH)/BoardConfig.mk
include device/rockchip/common/BoardConfig.mk
$(call inherit-product, device/rockchip/rk356x/device.mk)
$(call inherit-product, device/rockchip/common/device.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Note: Rotation configuration is provided via DEVICE_PACKAGE_OVERLAYS directory overlay
# No separate APK package needed

PRODUCT_CHARACTERISTICS := tablet

PRODUCT_NAME := rk356x_rock_3c_r
PRODUCT_DEVICE := rk356x_rock_3c_r
PRODUCT_BRAND := Radxa
PRODUCT_MODEL := rk356x_rock_3c_r
PRODUCT_MANUFACTURER := Radxa
PRODUCT_AAPT_PREF_CONFIG := mdpi
#
## add Rockchip properties
#
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=240
PRODUCT_PROPERTY_OVERRIDES += ro.wifi.sleep.power.down=true
PRODUCT_PROPERTY_OVERRIDES += persist.wifi.sleep.delay.ms=0
PRODUCT_PROPERTY_OVERRIDES += persist.bt.power.down=true
# HDMI configuration - Force HDMI as primary display
# PRODUCT_PROPERTY_OVERRIDES += ro.vendor.hdmirotationlock=true
PRODUCT_PROPERTY_OVERRIDES += vendor.hwc.device.primary=HDMI-A
PRODUCT_PROPERTY_OVERRIDES += vendor.hwc.device.extend=DSI
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.has_wide_color_display=false
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.protected_contents=false
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.use_color_management=false

# Display orientation - allow user_rotation to control display
# Note: Don't force rotation=0 as it conflicts with user_rotation
# PRODUCT_PROPERTY_OVERRIDES += persist.sys.rockchip.rotation=0
# PRODUCT_PROPERTY_OVERRIDES += persist.sys.rotation=0
PRODUCT_PROPERTY_OVERRIDES += persist.sys.panel.flip=0

# Touch input configuration - enable hardware rotation support
# PRODUCT_PROPERTY_OVERRIDES += ro.sf.hwrotation=0
# Allow input transform to follow display rotation
# PRODUCT_PROPERTY_OVERRIDES += persist.vendor.input.transform.rotate=0

# HDMI resolution detection and optimization
PRODUCT_PROPERTY_OVERRIDES += ro.vendor.hdmi.auto_resolution=true
PRODUCT_PROPERTY_OVERRIDES += persist.vendor.color.primary=BT709
PRODUCT_PROPERTY_OVERRIDES += ro.vendor.hdmi.force_edid_resolution=true

# Manual rotation support (no accelerometer) - FORCE enable Settings UI
PRODUCT_PROPERTY_OVERRIDES += ro.config.support_auto_rotation=false
PRODUCT_PROPERTY_OVERRIDES += ro.config.show_rotation_lock=true
PRODUCT_PROPERTY_OVERRIDES += persist.vendor.sensors.enable=false
PRODUCT_PROPERTY_OVERRIDES += persist.vendor.sensors.hal_trigger_ssr=false
PRODUCT_PROPERTY_OVERRIDES += ro.config.manual_rotation_enabled=true
# Additional rotation UI properties
PRODUCT_PROPERTY_OVERRIDES += ro.config.lockscreen_show_rotation_lock=true
PRODUCT_PROPERTY_OVERRIDES += ro.config.rotation_always_available=true

# Let system handle rotation naturally without forced properties
# PRODUCT_PROPERTY_OVERRIDES += ro.sf.hwrotation=0

# Enable SurfaceFlinger rotation capabilities
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.supports_background_blur=false
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.use_smart_90_for_video=true
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.enable_layer_caching=true
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.set_idle_timer_ms=80
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.set_touch_timer_ms=200

# Display configuration optimizations - enable fake rotation for software rotation support
# MUST be after inherit-product calls to override common device settings
PRODUCT_PROPERTY_OVERRIDES += ro.sf.fakerotation=true
PRODUCT_PROPERTY_OVERRIDES += sys.resolution.changed=false
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.default_composition_pixel_format=1
PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.force_hwc_copy_for_virtual_displays=true

# Boot animation configuration - using system default
PRODUCT_PROPERTY_OVERRIDES += debug.sf.enable_gl_backpressure=1

# Copy init files, scripts and device configurations
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hdmi_force.rc:system/etc/init/hdmi_force.rc \
    $(LOCAL_PATH)/init.rotation.rc:system/etc/init/init.rotation.rc \
    $(LOCAL_PATH)/init.usb_permissions.rc:system/etc/init/init.usb_permissions.rc

# HDMI support scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hdmi_switch.sh:system/bin/hdmi_switch.sh \
    $(LOCAL_PATH)/hdmi_resolution_detect.sh:system/bin/hdmi_resolution_detect.sh

# Rotation scripts - CRITICAL for persistence
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/restore_rotation.sh:system/bin/restore_rotation.sh \
    $(LOCAL_PATH)/monitor_rotation.sh:system/bin/monitor_rotation.sh

# Rotation scripts - OPTIONAL (manual control/debugging)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/save_rotation.sh:system/bin/save_rotation.sh \
    $(LOCAL_PATH)/apply_rotation.sh:system/bin/apply_rotation.sh

# Other system scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/power_actions.sh:system/bin/power_actions.sh \
    $(LOCAL_PATH)/usb_permissions.sh:system/bin/usb_permissions.sh

# 
#     $(LOCAL_PATH)/input/Vendor_0416_Product_c168.idc:system/usr/idc/Vendor_0416_Product_c168.idc \
#    $(LOCAL_PATH)/input/Generic_USB_Touchscreen.idc:system/usr/idc/Generic_USB_Touchscreen.idc \


# Copy AIC8800 WiFi and Bluetooth firmware files
# PRODUCT_COPY_FILES += \
#    $(LOCAL_PATH)/firmware/fmacfw.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fmacfw.bin \
#    $(LOCAL_PATH)/firmware/fmacfw_rf.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fmacfw_rf.bin \
#    $(LOCAL_PATH)/firmware/fmacfwbt.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fmacfwbt.bin \
#    $(LOCAL_PATH)/firmware/fw_adid.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fw_adid.bin \
#    $(LOCAL_PATH)/firmware/fw_adid_u03.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fw_adid_u03.bin \
#    $(LOCAL_PATH)/firmware/fw_patch.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fw_patch.bin \
#    $(LOCAL_PATH)/firmware/fw_patch_table.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fw_patch_table.bin \
#    $(LOCAL_PATH)/firmware/fw_patch_table_u03.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fw_patch_table_u03.bin \
#    $(LOCAL_PATH)/firmware/fw_patch_u03.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/fw_patch_u03.bin


# Hardware features for rotation
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.landscape.xml \
    frameworks/native/data/etc/android.hardware.screen.portrait.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.portrait.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml

# default not close screen
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay_dont_lock_screen


# WiFi/Bluetooth configuration - uncomment one of the following options:
# For Broadcom ap6xxx (default):
#$(call inherit-product-if-exists, device/rockchip/rk356x/wifi_bt.mk)
# For AIC8800 (alternative):
$(call inherit-product-if-exists, $(LOCAL_PATH)/wifi_bt_aic8800.mk)

