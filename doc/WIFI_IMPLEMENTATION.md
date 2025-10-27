# WiFi (AIC8800) Implementation for Radxa Rock 3C

This repository contains the complete WiFi implementation for the Radxa Rock 3C (RK3566) running Android 11 with AIC8800 WiFi/Bluetooth combo chip.

## Overview

This implementation adds full WiFi support for the AIC8800D80 chip, enabling:
- WiFi network scanning and connection through Android Settings
- WPA/WPA2/WPA3 security support
- WiFi Direct (P2P) support
- Bluetooth 4.2/5.0 BLE support
- Hotspot/AP mode support

## Hardware Details

**WiFi Chip**: AIC8800D80 (SDIO interface)
- **Vendor ID**: 0xC8A1
- **Product IDs**: 0x0082 (WiFi), 0x0182 (Base platform)
- **WiFi Standards**: 802.11 b/g/n/ac
- **Bluetooth**: 4.2/5.0 BLE
- **Interface**: SDIO for WiFi, UART for Bluetooth
- **Firmware**: Embedded in kernel driver (no external files needed)

## Implementation Approach

Uses a **HAL compatibility strategy** that leverages existing Broadcom WiFi HAL infrastructure:

1. **HAL Strategy**: Configure build to use Broadcom's nl80211-compatible HAL (`BOARD_WLAN_DEVICE := bcmdhd`)
2. **Kernel Modules**: Load AIC8800 modules early in boot sequence
3. **wpa_supplicant Configuration**: Add AIC8800-specific configuration section
4. **Framework Permissions**: Modify connection logic to allow Settings app to initiate connections
5. **Vendor HAL Updates**: Add AIC8800 device IDs to chip detection database

**Key Insight**: AIC8800 uses standard nl80211 interface, making it compatible with Broadcom's HAL without requiring custom HAL development.

## Problem Statement

### Initial Issues Encountered

1. **Kernel Driver Loading** ✅ SOLVED
   - AIC8800 modules weren't loading automatically
   - Solution: Added `init.aic8800.rc` with early module loading

2. **Missing Configuration File** ✅ SOLVED
   - `aic_userconfig_8800d80.txt` not found by driver
   - Solution: Copied to `/vendor/etc/firmware/`

3. **WiFi HAL Initialization Failure** ✅ SOLVED
   - Rockchip's WiFi HAL didn't recognize AIC8800
   - Error: `Failed to initialize legacy HAL: NOT_SUPPORTED`
   - Solution: Set `BOARD_WLAN_DEVICE := bcmdhd` to use compatible HAL

4. **wpa_supplicant Configuration** ✅ SOLVED
   - No AIC8800-specific configuration
   - Solution: Added `[AIC8800]` section to `wpa_config.txt`

5. **Framework Connection Blocking** ✅ SOLVED
   - Settings app couldn't initiate WiFi connections when Ethernet was active
   - Solution: Modified `ClientModeImpl.java` permission logic

## Files Modified

### Device Configuration
```
device/rockchip/rk356x/rk356x_rock_3c_r/
├── wifi_bt_aic8800.mk          # WiFi/BT build configuration
├── init.aic8800.rc             # Early module loading and interface setup
└── rk356x_rock_3c_r.mk         # Product makefile (includes init.aic8800.rc)

device/rockchip/common/
└── wpa_config.txt              # wpa_supplicant configuration (added AIC8800 section)
```

### Framework/HAL
```
frameworks/opt/net/wifi/libwifi_hal/
├── rk_wifi_ctrl.cpp            # Chip detection database (added AIC8800 IDs)
└── wifi_hal_common.cpp         # Module loading helpers (from AIC8800 vendor patch)
```

### Android Framework
```
packages/apps/Settings/src/com/android/settings/wifi/
└── ClientModeImpl.java         # WiFi connection permission logic (modified)
```

## Technical Details

### 1. HAL Configuration (wifi_bt_aic8800.mk)

**Critical Change**:
```makefile
BOARD_WLAN_DEVICE := bcmdhd
```

This tells the build system to use Broadcom's nl80211-compatible HAL instead of looking for AIC8800-specific HAL.

**Other Key Settings**:
```makefile
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_WLAN_DEVICE := bcmdhd

# Disable firmware path switching (not used by AIC8800)
WIFI_DRIVER_FW_PATH_PARAM := ""
WIFI_DRIVER_FW_PATH_STA := ""
WIFI_DRIVER_FW_PATH_P2P := ""
WIFI_DRIVER_FW_PATH_AP := ""
```

### 2. Early Module Loading (init.aic8800.rc)

Loads kernel modules before WiFi HAL starts:
```
on early-init
    insmod /vendor/lib/modules/aic8800_bsp.ko
    insmod /vendor/lib/modules/aic8800_fdrv.ko
    insmod /vendor/lib/modules/aic8800_btlpm.ko
```

Loading order is critical:
1. `aic8800_bsp.ko` - Base platform support
2. `aic8800_fdrv.ko` - WiFi driver
3. `aic8800_btlpm.ko` - Bluetooth low power mode

### 3. wpa_supplicant Configuration (wpa_config.txt)

Added AIC8800-specific section:
```
[AIC8800]
/vendor/bin/hw/wpa_supplicant
-O/data/vendor/wifi/wpa/sockets
-puse_p2p_group_interface=1
-g@android:wpa_wlan0
```

### 4. Chip Detection (rk_wifi_ctrl.cpp)

Added AIC8800 device IDs to supported devices array:
```cpp
static wifi_device supported_wifi_devices[] = {
    // ... existing devices ...
    {"AIC8800", "c8a1:0082"},  // WiFi driver
    {"AIC8800", "c8a1:0182"},  // Base platform
};
```

### 5. Framework Permissions (ClientModeImpl.java)

Modified permission logic to allow privileged apps (uid 1000 = Settings) to connect even when other networks satisfy the default request:

**Before**: Required active network requests OR (connection + permissions)
**After**: Allows privileged callers to connect without active network requests

## Build Instructions

### 1. Apply Changes

Copy all files from this repository to your Android source tree:

```bash
# Device configuration
cp -r device/* $ANDROID_BUILD_TOP/device/

# Framework/HAL
cp -r frameworks/* $ANDROID_BUILD_TOP/frameworks/

# Settings app (if modified)
cp -r packages/* $ANDROID_BUILD_TOP/packages/
```

### 2. Build Images

```bash
source build/envsetup.sh
lunch rk356x_rock_3c_r-userdebug

# Build vendor image (contains HAL and modules)
m vendorimage

# Build system image (contains init script)
m systemimage

# Or build complete image
m -j$(nproc)
```

### 3. Flash to Device

```bash
# Boot to fastbootd
adb reboot fastboot

# Flash partitions
fastboot flash vendor vendor.img
fastboot flash system system.img

# Reboot
fastboot reboot
```

## Verification

### Check Module Loading
```bash
adb shell lsmod | grep aic
# Should show: aic8800_btlpm, aic8800_fdrv, aic8800_bsp
```

### Check Interface Status
```bash
adb shell ip link show wlan0
# Should show: state UP
```

### Check WiFi HAL
```bash
adb logcat -d | grep "android.hardware.wifi"
# Should NOT show: "Failed to initialize legacy HAL"
```

### Test WiFi Scanning
```bash
adb root
adb shell iw wlan0 scan | grep SSID
# Should list available networks
```

### Test Android Settings
1. Open Settings → Network & Internet → Wi-Fi
2. Toggle WiFi on
3. Should see list of available networks
4. Connect to a network with password
5. Verify internet connectivity

## Known Limitations

1. **WiFi-Ethernet Coexistence**: Original framework logic prioritized Ethernet over WiFi. Modified to allow both.
2. **Firmware Files**: While AIC8800 embeds firmware in driver, config file `aic_userconfig_8800d80.txt` is still required for TX power calibration.
3. **HAL Compatibility**: Uses Broadcom HAL as compatibility layer. Some Broadcom-specific features may not work.

## Troubleshooting

### WiFi Toggle Doesn't Work
- Check logcat for HAL errors: `adb logcat | grep wifi`
- Verify modules loaded: `adb shell lsmod | grep aic`
- Check interface status: `adb shell ip link show wlan0`

### Can See Networks But Can't Connect
- Check wpa_supplicant: `adb shell ps -A | grep wpa_supplicant`
- View wpa logs: `adb logcat | grep wpa_supplicant`
- Test direct connection: `adb shell wpa_cli scan`

### HAL Initialization Fails
- Verify `BOARD_WLAN_DEVICE := bcmdhd` in `wifi_bt_aic8800.mk`
- Check if `rk_wifi_ctrl.cpp` contains AIC8800 IDs
- Rebuild vendor image: `m vendorimage`

## References

- **Android WiFi Architecture**: https://source.android.com/devices/connectivity/wifi-hal
- **nl80211 Interface**: https://wireless.wiki.kernel.org/en/developers/documentation/nl80211
- **wpa_supplicant**: https://w1.fi/wpa_supplicant/
- **AIC8800 Driver Source**: `/data/Projects/Maestro/Radxa/aic8800/`

## License

These modifications follow the same license as the original Android Open Source Project files (Apache 2.0).

## Changelog

### Version 1.0 (2025-10-27)
- Initial WiFi implementation
- AIC8800D80 chip support
- Full Android Settings integration
- Hotspot/AP mode support
- WiFi Direct (P2P) support

## Contributors

- Implementation based on AIC8800 vendor driver patch
- Framework modifications for Radxa Rock 3C
- Rockchip Android 11 BSP customizations
