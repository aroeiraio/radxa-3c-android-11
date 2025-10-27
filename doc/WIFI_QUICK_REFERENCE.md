# AIC8800 WiFi Implementation - Quick Reference

This is a quick reference guide for applying the AIC8800 WiFi implementation to Radxa Rock 3C.

## Quick Apply

### 1. Copy Files to Android Source

```bash
cd /data/Projects/Maestro/Radxa/wifi-implementation

# Device configuration
cp device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk \
   $ANDROID_BUILD_TOP/device/rockchip/rk356x/rk356x_rock_3c_r/

cp device/rockchip/rk356x/rk356x_rock_3c_r/init.aic8800.rc \
   $ANDROID_BUILD_TOP/device/rockchip/rk356x/rk356x_rock_3c_r/

cp device/rockchip/rk356x/rk356x_rock_3c_r/wpa_config.txt \
   $ANDROID_BUILD_TOP/device/rockchip/common/

# WiFi HAL
cp frameworks/opt/net/wifi/libwifi_hal/rk_wifi_ctrl.cpp \
   $ANDROID_BUILD_TOP/frameworks/opt/net/wifi/libwifi_hal/

cp frameworks/opt/net/wifi/libwifi_hal/wifi_hal_common.cpp \
   $ANDROID_BUILD_TOP/frameworks/opt/net/wifi/libwifi_hal/
```

### 2. Modify rk356x_rock_3c_r.mk

Add this line to PRODUCT_COPY_FILES section:
```makefile
$(LOCAL_PATH)/init.aic8800.rc:system/etc/init/init.aic8800.rc
```

### 3. Modify ClientModeImpl.java (if needed)

**File**: `packages/apps/Settings/src/com/android/settings/wifi/ClientModeImpl.java`

**Lines 4073-4087**: Replace permission check logic with:
```java
// Allow user-initiated connections from Settings even without active network requests
if (mNetworkAgent == null && !checkNetworkSettingsPermission(uid)) {
    loge("connect(nid=" + networkId + ") called with no NetworkAgent and "
            + "without NETWORK_SETTINGS permission");
    return;
} else if (mNetworkAgent != null && !checkNetworkSettingsPermission(uid)) {
    loge("connect(nid=" + networkId + ") called without NETWORK_SETTINGS permission");
    return;
}

if (checkNetworkSettingsPermission(uid)) {
    Log.i(TAG, "Allowing WiFi connection from privileged uid " + uid
            + " even without active network requests");
}
```

### 4. Build

```bash
source build/envsetup.sh
lunch rk356x_rock_3c_r-userdebug

# Build vendor image (contains HAL and kernel modules)
m vendorimage

# Build system image (contains init script)
m systemimage
```

### 5. Flash

```bash
adb reboot fastboot
fastboot flash vendor vendor.img
fastboot flash system system.img
fastboot reboot
```

---

## File Mapping

| Source File | Destination in Android Tree |
|-------------|----------------------------|
| `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk` | `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk` |
| `device/rockchip/rk356x/rk356x_rock_3c_r/init.aic8800.rc` | `device/rockchip/rk356x/rk356x_rock_3c_r/init.aic8800.rc` |
| `device/rockchip/rk356x/rk356x_rock_3c_r/wpa_config.txt` | `device/rockchip/common/wpa_config.txt` |
| `frameworks/opt/net/wifi/libwifi_hal/rk_wifi_ctrl.cpp` | `frameworks/opt/net/wifi/libwifi_hal/rk_wifi_ctrl.cpp` |
| `frameworks/opt/net/wifi/libwifi_hal/wifi_hal_common.cpp` | `frameworks/opt/net/wifi/libwifi_hal/wifi_hal_common.cpp` |

---

## Critical Changes Summary

### 1. HAL Device Type (wifi_bt_aic8800.mk:27)
```makefile
BOARD_WLAN_DEVICE := bcmdhd  # Changed from aic8800
```

### 2. Early Module Loading (init.aic8800.rc:8-12)
```bash
on early-init
    insmod /vendor/lib/modules/aic8800_bsp.ko
    insmod /vendor/lib/modules/aic8800_fdrv.ko
    insmod /vendor/lib/modules/aic8800_btlpm.ko
```

### 3. wpa_supplicant Config (wpa_config.txt:34-38)
```
[AIC8800]
/vendor/bin/hw/wpa_supplicant
-O/data/vendor/wifi/wpa/sockets
-puse_p2p_group_interface=1
-g@android:wpa_wlan0
```

### 4. Device IDs (rk_wifi_ctrl.cpp:78-79)
```cpp
{"AIC8800", "c8a1:0082"},
{"AIC8800", "c8a1:0182"},
```

### 5. Framework Permissions (ClientModeImpl.java:4073-4087)
- Modified to allow Settings app to connect WiFi
- Even when Ethernet satisfies network requests

---

## Verification Commands

### Check Modules Loaded
```bash
adb shell lsmod | grep aic
```
**Expected**: Shows aic8800_bsp, aic8800_fdrv, aic8800_btlpm

### Check Interface Status
```bash
adb shell ip link show wlan0
```
**Expected**: Shows `state UP`

### Check HAL Initialization
```bash
adb logcat -d | grep "android.hardware.wifi" | grep -i failed
```
**Expected**: No "Failed to initialize legacy HAL" errors

### Test WiFi Scanning
```bash
adb root
adb shell iw wlan0 scan | grep SSID
```
**Expected**: List of available networks

### Check dmesg for AIC8800
```bash
adb shell dmesg | grep -i aic
```
**Expected**: Driver initialization messages, no errors

---

## Troubleshooting Quick Fixes

### Modules Don't Load
```bash
# Manually load modules
adb root
adb shell insmod /vendor/lib/modules/aic8800_bsp.ko
adb shell insmod /vendor/lib/modules/aic8800_fdrv.ko
adb shell insmod /vendor/lib/modules/aic8800_btlpm.ko
```

### Interface Won't Come Up
```bash
# Manually bring up interface
adb root
adb shell ip link set wlan0 up
```

### HAL Fails to Initialize
```bash
# Check BOARD_WLAN_DEVICE setting
grep BOARD_WLAN_DEVICE device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk
# Must show: bcmdhd

# Rebuild vendor image
m vendorimage
```

### Can't Connect from Settings
```bash
# Check if ClientModeImpl.java was modified
# Rebuild system image
m systemimage
```

---

## Build Time Estimates

- **Vendor Image**: ~2-3 minutes (incremental)
- **System Image**: ~30-60 seconds (incremental)
- **Full Build**: ~4-5 hours (clean build)

---

## Partition Sizes

- **vendor.img**: ~307 MB
- **system.img**: ~955 MB
- **Total**: ~1.3 GB

---

## Key Insights

1. **nl80211 Compatibility**: AIC8800 uses standard nl80211, same as Broadcom
2. **HAL Reuse**: No custom HAL needed, use existing Broadcom HAL
3. **Early Loading**: Modules must load in early-init for HAL to find them
4. **Permissions**: Framework needs modification for Settings app to work
5. **wpa_supplicant**: Needs chip-specific configuration section

---

## Related Documentation

- **Full Details**: See `IMPLEMENTATION_DETAILS.md`
- **Overview**: See `README.md`
- **Rotation Implementation**: See `/data/Projects/Maestro/Radxa/rotation-implementation/`

---

## Support

For issues or questions:
1. Check `IMPLEMENTATION_DETAILS.md` for line-by-line explanations
2. Review logcat output: `adb logcat | grep -iE "(wifi|wlan|aic)"`
3. Check dmesg: `adb shell dmesg | grep -i aic`
4. Verify all files were copied correctly
5. Ensure both vendor and system images were rebuilt and flashed
