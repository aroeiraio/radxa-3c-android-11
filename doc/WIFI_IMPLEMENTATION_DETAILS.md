# AIC8800 WiFi Implementation - Detailed Technical Changes

This document provides line-by-line details of all code changes required to enable AIC8800 WiFi support on Radxa Rock 3C running Android 11.

## Table of Contents

1. [Device Configuration Changes](#device-configuration-changes)
2. [HAL Layer Changes](#hal-layer-changes)
3. [Framework Changes](#framework-changes)
4. [wpa_supplicant Configuration](#wpa-supplicant-configuration)
5. [Build System Integration](#build-system-integration)

---

## Device Configuration Changes

### 1. wifi_bt_aic8800.mk

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk`

**Change Summary**: Modified WiFi HAL device type to use Broadcom compatibility layer

#### Line 27 - Critical HAL Selection

**BEFORE**:
```makefile
BOARD_WLAN_DEVICE := aic8800
```

**AFTER**:
```makefile
BOARD_WLAN_DEVICE := bcmdhd
```

**Purpose**:
- Tells Android build system to use Broadcom's WiFi HAL implementation
- Broadcom HAL supports standard nl80211 interface (same as AIC8800)
- Avoids need to develop custom AIC8800-specific HAL
- Leverages existing, well-tested Broadcom HAL infrastructure

**Impact**:
- Build system will link against `libwifi-hal-bcm` instead of looking for `libwifi-hal-aic8800`
- WiFi HAL service will use Broadcom's legacy HAL functions (compatible with nl80211)
- Enables HAL initialization without Broadcom-specific hardware features

**Context Around Line 27**:
```makefile
# WiFi configuration for AIC8800 (using standard nl80211)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_WLAN_DEVICE := bcmdhd  # ← Changed from aic8800

# Disable firmware path switching (aic8800 doesn't use it like Broadcom)
WIFI_DRIVER_FW_PATH_PARAM := ""
```

**Why This Works**:
- Both Broadcom bcmdhd and AIC8800 use nl80211 (generic netlink 802.11)
- nl80211 provides standardized kernel-userspace WiFi interface
- HAL only needs to support nl80211 operations, not chip-specific features
- Broadcom HAL gracefully handles missing vendor-specific extensions

---

### 2. init.aic8800.rc

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/init.aic8800.rc`

**Change Summary**: New file for early kernel module loading and interface initialization

#### Complete File Content:

```bash
# AIC8800 WiFi initialization
#
# The aic8800 driver uses standard nl80211, but the Rockchip WiFi HAL
# is hardcoded for Broadcom chips and fails to initialize.
# As a workaround, we bring up the wlan0 interface manually.
#

on early-init
    # Load AIC8800 kernel modules early in boot
    insmod /vendor/lib/modules/aic8800_bsp.ko
    insmod /vendor/lib/modules/aic8800_fdrv.ko
    insmod /vendor/lib/modules/aic8800_btlpm.ko

on boot
    # Wait for wlan0 interface to be created by the driver
    wait /sys/class/net/wlan0 5

    # Bring up the wlan0 interface
    exec_background - wifi - -- /system/bin/ip link set wlan0 up

    # Set WiFi interface property
    setprop wifi.interface wlan0

on property:sys.boot_completed=1
    # Ensure wlan0 is up after boot completes
    exec_background - wifi - -- /system/bin/ip link set wlan0 up
```

**Section Breakdown**:

#### Lines 8-12: Early Module Loading
```bash
on early-init
    insmod /vendor/lib/modules/aic8800_bsp.ko
    insmod /vendor/lib/modules/aic8800_fdrv.ko
    insmod /vendor/lib/modules/aic8800_btlpm.ko
```

**Purpose**:
- Loads modules during `early-init` phase (before most services start)
- Ensures modules are loaded before WiFi HAL attempts initialization
- Correct loading order is critical for driver initialization

**Module Descriptions**:
1. `aic8800_bsp.ko` (2.5 MB) - Base Support Platform
   - Initializes SDIO bus communication
   - Sets up power management
   - Creates device nodes

2. `aic8800_fdrv.ko` (16 MB) - Full Driver
   - WiFi protocol stack implementation
   - Creates wlan0 network interface
   - Implements nl80211 ops

3. `aic8800_btlpm.ko` (539 KB) - Bluetooth Low Power Mode
   - Bluetooth protocol support
   - Power saving features
   - UART communication for BT

#### Lines 14-22: Interface Initialization
```bash
on boot
    wait /sys/class/net/wlan0 5
    exec_background - wifi - -- /system/bin/ip link set wlan0 up
    setprop wifi.interface wlan0
```

**Purpose**:
- Waits up to 5 seconds for driver to create wlan0 interface
- Brings up interface so it's ready for WiFi HAL
- Sets system property for framework to discover interface

**exec_background Syntax**:
- `-` : No SELinux context change
- `wifi` : Run as wifi user
- `-` : Run in wifi group
- `--` : End of options
- `/system/bin/ip link set wlan0 up` : Command to execute

#### Lines 24-26: Post-Boot Verification
```bash
on property:sys.boot_completed=1
    exec_background - wifi - -- /system/bin/ip link set wlan0 up
```

**Purpose**:
- Re-ensures interface is up after full boot
- Handles race conditions where HAL might start before interface is ready
- Provides recovery if interface goes down during boot

---

### 3. rk356x_rock_3c_r.mk

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/rk356x_rock_3c_r.mk`

**Change**: Added init.aic8800.rc to PRODUCT_COPY_FILES

#### Modified Section (around line 105-109):

**BEFORE**:
```makefile
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hdmi_force.rc:system/etc/init/hdmi_force.rc \
    $(LOCAL_PATH)/init.rotation.rc:system/etc/init/init.rotation.rc \
    $(LOCAL_PATH)/init.usb_permissions.rc:system/etc/init/init.usb_permissions.rc
```

**AFTER**:
```makefile
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hdmi_force.rc:system/etc/init/hdmi_force.rc \
    $(LOCAL_PATH)/init.rotation.rc:system/etc/init/init.rotation.rc \
    $(LOCAL_PATH)/init.usb_permissions.rc:system/etc/init/init.usb_permissions.rc \
    $(LOCAL_PATH)/init.aic8800.rc:system/etc/init/init.aic8800.rc
```

**Purpose**:
- Installs init.aic8800.rc to system partition
- Init system will automatically parse and execute during boot
- Placed in `/system/etc/init/` (standard location for device-specific init scripts)

---

## HAL Layer Changes

### 4. rk_wifi_ctrl.cpp

**File**: `frameworks/opt/net/wifi/libwifi_hal/rk_wifi_ctrl.cpp`

**Change Summary**: Added AIC8800 device IDs to supported WiFi devices database

#### Lines 75-79: Device Database Update

**BEFORE** (lines 75-78):
```cpp
    {"RTL8822BE",   "10ec:b822"},
    {"MVL88W8977",  "02df:9145"},
    {"SPRDWL",      "0000:0000"},
};
```

**AFTER** (lines 75-80):
```cpp
    {"RTL8822BE",   "10ec:b822"},
    {"MVL88W8977",  "02df:9145"},
    {"SPRDWL",      "0000:0000"},
    {"AIC8800",     "c8a1:0082"},
    {"AIC8800",     "c8a1:0182"},
};
```

**Purpose**:
- Adds AIC8800 vendor/product IDs to Rockchip's chip detection database
- Enables `librkwifi-ctrl` to recognize AIC8800 when scanning SDIO bus
- Two entries because AIC8800 has two SDIO functions:
  - `c8a1:0082` - WiFi function (aicwf_sdio driver)
  - `c8a1:0182` - Base platform function (aicbsp_sdio driver)

**Impact**:
- `get_wifi_device_id()` function will match AIC8800 during bus enumeration
- Prevents "unknown device" errors in HAL initialization
- Allows HAL to load correct kernel module path

**How IDs Were Discovered**:
```bash
$ adb shell cat /sys/bus/sdio/devices/*/uevent
DRIVER=aicwf_sdio
SDIO_ID=C8A1:0082      # ← WiFi function
DRIVER=aicbsp_sdio
SDIO_ID=C8A1:0182      # ← Base platform function
```

**Context in Code** (function that uses this array):
```cpp
int get_wifi_device_id(const char *bus_dir, const char *prefix)
{
    int idnum = sizeof(supported_wifi_devices) / sizeof(supported_wifi_devices[0]);

    // Scans SDIO bus for devices
    // Compares device IDs against supported_wifi_devices array
    // Returns index if found, invalid_wifi_device_id if not found
}
```

---

### 5. wifi_hal_common.cpp

**File**: `frameworks/opt/net/wifi/libwifi_hal/wifi_hal_common.cpp`

**Change Summary**: Copied complete file from AIC8800 vendor patch

**Purpose**:
- Provides common HAL functions for WiFi initialization
- Module loading logic
- Firmware path management
- Country code configuration

**Key Functions**:
```cpp
// Load WiFi driver module
int wifi_load_driver() {
    // Loads kernel module based on device detection
    // Sets firmware paths
    // Initializes country code
}

// Unload WiFi driver module
int wifi_unload_driver() {
    // Removes kernel module
    // Cleans up resources
}

// Change firmware mode (STA/AP/P2P)
int wifi_change_fw_path(const char *fwpath) {
    // Updates firmware mode via sysfs
    // Note: AIC8800 doesn't use this (firmware embedded)
}
```

**Integration**:
- Linked into `libwifi-hal.so` via `LOCAL_WHOLE_STATIC_LIBRARIES`
- Called by `android.hardware.wifi@1.0-service` during initialization
- Provides abstraction between HAL service and kernel driver

---

## Framework Changes

### 6. ClientModeImpl.java

**File**: `packages/apps/Settings/src/com/android/settings/wifi/ClientModeImpl.java`

**Change Summary**: Modified permission logic to allow privileged apps to connect WiFi even when other networks (Ethernet) are active

#### Lines 4073-4087: Permission Logic Modification

**BEFORE**:
```java
if (mNetworkAgent == null) {
    loge("connect(nid=" + networkId + ") called with no network agent");
    return;
} else if (!checkNetworkSettingsPermission(uid)) {
    loge("connect(nid=" + networkId + ") called without NETWORK_SETTINGS permission");
    return;
}
```

**Problem**: Required active network requests OR (existing connection AND permissions)
- If Ethernet satisfies default network request, WiFi can't connect
- Even Settings app (uid 1000) couldn't initiate connections

**AFTER**:
```java
// Allow user-initiated connections from Settings even without active network requests
// This is necessary because when Ethernet is connected, it satisfies the default
// network request, blocking WiFi connections that the user explicitly wants
if (mNetworkAgent == null && !checkNetworkSettingsPermission(uid)) {
    loge("connect(nid=" + networkId + ") called with no NetworkAgent and "
            + "without NETWORK_SETTINGS permission");
    return;
} else if (mNetworkAgent != null && !checkNetworkSettingsPermission(uid)) {
    loge("connect(nid=" + networkId + ") called without NETWORK_SETTINGS permission");
    return;
}

// Log when allowing a connection from a privileged caller
if (checkNetworkSettingsPermission(uid)) {
    Log.i(TAG, "Allowing WiFi connection from privileged uid " + uid
            + " even without active network requests");
}
```

**Solution**: Two separate permission checks
1. If NO NetworkAgent AND NO permissions → Block
2. If NetworkAgent exists AND NO permissions → Block
3. If permissions exist → Allow (with logging)

**Key Change Logic**:
```
BEFORE: (NetworkAgent == null) → Block
        (NetworkAgent != null AND !permissions) → Block

AFTER:  (NetworkAgent == null AND !permissions) → Block
        (NetworkAgent != null AND !permissions) → Block
        (permissions) → Allow
```

**Impact**:
- Settings app (uid 1000) has NETWORK_SETTINGS permission
- Can now connect WiFi even when Ethernet satisfies network requests
- Other apps without permission still blocked (maintains security)

**Security Considerations**:
- Only apps with `android.permission.NETWORK_SETTINGS` can bypass check
- This is a system permission (signature-level)
- Settings app is system signed, so it has this permission
- Regular apps cannot get this permission

---

## wpa_supplicant Configuration

### 7. wpa_config.txt

**File**: `device/rockchip/common/wpa_config.txt`

**Change Summary**: Added AIC8800-specific configuration section

#### Lines 34-38: New AIC8800 Section

**ADDED**:
```
[AIC8800]
/vendor/bin/hw/wpa_supplicant
-O/data/vendor/wifi/wpa/sockets
-puse_p2p_group_interface=1
-g@android:wpa_wlan0
```

**Purpose**:
- Tells wpa_supplicant how to start for AIC8800 chip
- Chip detected via device ID matching in rk_wifi_ctrl.cpp

**Line-by-Line Explanation**:

**Line 34**: `[AIC8800]`
- Section header
- Matches chip name from device database
- wpa_supplicant uses this when chip is detected

**Line 35**: `/vendor/bin/hw/wpa_supplicant`
- Path to wpa_supplicant binary
- Standard location for vendor hardware binaries

**Line 36**: `-O/data/vendor/wifi/wpa/sockets`
- Control interface directory
- Android WiFi framework connects to sockets here
- Used for scan, connect, disconnect commands

**Line 37**: `-puse_p2p_group_interface=1`
- Enable WiFi Direct (P2P) support
- Creates separate interface for P2P (e.g., p2p-wlan0-0)
- Required for WiFi Direct feature

**Line 38**: `-g@android:wpa_wlan0`
- Global control interface socket name
- Android framework uses this for global commands
- Format: `-g@<socket_type>:<socket_name>`

**How It's Used**:
1. HAL detects AIC8800 chip via SDIO device ID
2. Reads `[AIC8800]` section from wpa_config.txt
3. Starts wpa_supplicant with these arguments
4. wpa_supplicant creates control sockets
5. Android framework connects to sockets for WiFi operations

**Comparison with Broadcom Config**:
```
[AP6XXX]
/vendor/bin/hw/wpa_supplicant
-O/data/vendor/wifi/wpa/sockets
-puse_p2p_group_interface=1
-g@android:wpa_wlan0
```
- Almost identical configuration
- Confirms nl80211 standardization

---

## Build System Integration

### Module Installation

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk`

**Lines 57-60**: Kernel Module Installation

```makefile
PRODUCT_COPY_FILES += \
    kernel/drivers/net/wireless/aic8800/aic8800_bsp/aic8800_bsp.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aic8800_bsp.ko \
    kernel/drivers/net/wireless/aic8800/aic8800_fdrv/aic8800_fdrv.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aic8800_fdrv.ko \
    kernel/drivers/net/wireless/aic8800/aic8800_btlpm/aic8800_btlpm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aic8800_btlpm.ko
```

**Purpose**:
- Copies built kernel modules from kernel source to vendor partition
- Modules must be in vendor partition for init.aic8800.rc to load them
- Using `TARGET_COPY_OUT_VENDOR` ensures correct partition placement

**Module Source Paths**:
- Built during kernel compilation
- Located in `kernel/drivers/net/wireless/aic8800/`
- Compiled as `CONFIG_AIC_WLAN_SUPPORT=m` (loadable modules)

**Destination Paths**:
- `/vendor/lib/modules/aic8800_bsp.ko`
- `/vendor/lib/modules/aic8800_fdrv.ko`
- `/vendor/lib/modules/aic8800_btlpm.ko`

---

## Summary of Changes

### Files Created:
1. `init.aic8800.rc` - Early module loading and interface setup (27 lines)

### Files Modified:
1. `wifi_bt_aic8800.mk` - Line 27: `BOARD_WLAN_DEVICE := bcmdhd` (1 line)
2. `wpa_config.txt` - Lines 34-38: Added `[AIC8800]` section (5 lines)
3. `rk_wifi_ctrl.cpp` - Lines 78-79: Added AIC8800 device IDs (2 lines)
4. `ClientModeImpl.java` - Lines 4073-4087: Modified permission logic (15 lines)
5. `rk356x_rock_3c_r.mk` - Added init.aic8800.rc to PRODUCT_COPY_FILES (1 line)

### Files Copied:
1. `wifi_hal_common.cpp` - Complete file from AIC8800 vendor patch

### Total Lines Changed: ~51 lines
- Device config: 28 lines
- HAL: 2 lines
- Framework: 15 lines
- wpa_supplicant: 5 lines
- Build system: 1 line

---

## Testing Verification

### 1. Module Loading Verification
```bash
adb shell lsmod | grep aic
# Expected output:
# aic8800_btlpm    16384  0
# aic8800_fdrv    483328  0
# aic8800_bsp      90112  2 aic8800_btlpm,aic8800_fdrv
```

### 2. Interface Verification
```bash
adb shell ip link show wlan0
# Expected output:
# 8: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
#     link/ether 78:22:88:75:c5:58 brd ff:ff:ff:ff:ff:ff
```

### 3. HAL Initialization Verification
```bash
adb logcat -d | grep "android.hardware.wifi@1.0-service" | grep -i "failed"
# Expected output: (empty - no failures)
```

### 4. WiFi Scanning Verification
```bash
adb root
adb shell iw wlan0 scan | grep SSID
# Expected output: List of SSIDs
```

### 5. Android Settings Verification
- Navigate to Settings → Network & Internet → Wi-Fi
- Toggle WiFi on
- Observe list of available networks
- Connect to a network
- Verify internet connectivity

---

## Troubleshooting Guide

### Issue: Modules Don't Load

**Symptom**: `lsmod | grep aic` shows nothing

**Debugging Steps**:
```bash
# Check if modules exist
adb shell ls -l /vendor/lib/modules/aic8800*

# Check init.aic8800.rc was installed
adb shell ls -l /system/etc/init/init.aic8800.rc

# Check dmesg for module errors
adb shell dmesg | grep -i aic

# Manually load modules
adb root
adb shell insmod /vendor/lib/modules/aic8800_bsp.ko
adb shell insmod /vendor/lib/modules/aic8800_fdrv.ko
adb shell insmod /vendor/lib/modules/aic8800_btlpm.ko
```

**Solutions**:
- Verify modules were built: Check `kernel/.config` has `CONFIG_AIC_WLAN_SUPPORT=m`
- Verify modules were copied: Rebuild vendor image with `m vendorimage`
- Verify init script installed: Rebuild system image with `m systemimage`

### Issue: HAL Fails to Initialize

**Symptom**: `logcat` shows "Failed to initialize legacy HAL"

**Debugging Steps**:
```bash
# Check BOARD_WLAN_DEVICE setting
grep BOARD_WLAN_DEVICE device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk
# Should show: BOARD_WLAN_DEVICE := bcmdhd

# Check if librkwifi-ctrl has AIC8800 IDs
strings /vendor/lib64/librkwifi-ctrl.so | grep -i aic
# Should show: AIC8800

# Check HAL logs
adb logcat -b all | grep -i "wifi.*hal"
```

**Solutions**:
- Verify `BOARD_WLAN_DEVICE := bcmdhd` in wifi_bt_aic8800.mk
- Rebuild vendor image: `m vendorimage`
- Check rk_wifi_ctrl.cpp has AIC8800 entries

### Issue: Can't Connect to WiFi from Settings

**Symptom**: Networks visible but connection fails

**Debugging Steps**:
```bash
# Check wpa_supplicant
adb shell ps -A | grep wpa_supplicant

# Check wpa_supplicant config
adb shell cat /vendor/etc/wifi/wpa_config.txt | grep -A 5 AIC8800

# Check wpa_supplicant logs
adb logcat | grep wpa_supplicant

# Test manual connection
adb shell wpa_cli scan
adb shell wpa_cli scan_results
```

**Solutions**:
- Verify `[AIC8800]` section in wpa_config.txt
- Rebuild vendor image
- Check ClientModeImpl.java has permission fix

---

## References

### Android WiFi Stack Documentation
- **WiFi HAL**: https://source.android.com/devices/connectivity/wifi-hal
- **nl80211**: https://wireless.wiki.kernel.org/en/developers/documentation/nl80211
- **wpa_supplicant**: https://w1.fi/wpa_supplicant/

### Rockchip Documentation
- **RK3566 TRM**: Technical Reference Manual
- **Android 11 BSP**: Rockchip Android 11 SDK

### AIC8800 Documentation
- **Driver Source**: `/data/Projects/Maestro/Radxa/aic8800/`
- **Device IDs**: Discovered via `cat /sys/bus/sdio/devices/*/uevent`

### Android Framework
- **ClientModeImpl.java**: `packages/modules/Wifi/service/java/com/android/server/wifi/ClientModeImpl.java`
- **WifiNative.java**: `packages/modules/Wifi/service/java/com/android/server/wifi/WifiNative.java`
