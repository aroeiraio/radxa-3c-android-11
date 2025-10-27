# AIC8800 Bluetooth - Detailed Changes Documentation

## Problem Analysis

### Initial State
- **Kernel**: aic8800_btlpm module loaded ✅
- **Firmware**: BT patch loaded successfully ✅
- **UART**: /dev/ttyS1 device present ✅
- **rfkill**: Bluetooth unblocked ✅
- **HAL Service**: android.hardware.bluetooth@1.0-service running ✅
- **Issue**: Bluetooth enabled but immediately crashed and restarted ❌

### Root Cause
The system was using **Realtek's libbt-vendor.so** instead of AIC8800's vendor library. The Realtek library doesn't know how to communicate with AIC8800 hardware via UART, causing initialization failures and crashes.

---

## Detailed Changes

### Change 1: Copy AIC8800 Bluetooth Vendor Library

**Action**: Copied entire vendor library from AIC8800 SDK to build tree

**Source**: 
```
/data/Projects/Maestro/Radxa/aic8800/src/SDIO/patch/for_Rockchip/3566/Android11/mod/android/hardware/aic/aicbt/
```

**Destination**:
```
hardware/aic/aicbt/
```

**Files Copied**:
```
hardware/aic/aicbt/
├── Android.mk                          # Top-level makefile (conditional build)
├── aicbt.mk                           # Product integration makefile
└── libbt/
    ├── Android.mk                     # Library build configuration
    ├── vnd_buildcfg.mk               # Build configuration generator
    ├── gen-buildcfg.sh               # Script to generate vnd_buildcfg.h
    ├── include/
    │   ├── bt_vendor_aicbt.h         # Vendor interface header
    │   ├── upio.h                    # GPIO control header
    │   ├── userial_vendor.h          # UART serial header
    │   ├── vnd_aic8800.txt           # AIC8800-specific config
    │   └── vnd_generic.txt           # Generic/default config
    └── src/
        ├── bt_vendor_aicbt.c         # Main vendor interface implementation
        ├── aic_hardware.c            # Hardware initialization & power control
        ├── userial_vendor.c          # UART communication layer
        ├── upio.c                    # GPIO control (power, wake)
        └── aic_conf.c                # Configuration file parser
```

**Purpose of Each Source File**:

1. **bt_vendor_aicbt.c** (Main Interface)
   - Implements `BLUETOOTH_VENDOR_LIB_INTERFACE`
   - Entry point for Android Bluetooth stack
   - Functions:
     - `init()` - Initialize vendor library
     - `op()` - Handle operations (power on/off, config)
     - `cleanup()` - Cleanup resources

2. **aic_hardware.c** (Hardware Control)
   - Power management (BT_VND_PWR_ON/OFF)
   - Firmware download
   - UART baud rate configuration
   - Hardware initialization sequence
   - Wake/sleep control

3. **userial_vendor.c** (UART Communication)
   - Opens /dev/ttyS1
   - Configures UART parameters:
     - Baud: 1,500,000 bps
     - Flow control: RTS/CTS enabled
     - 8N1 format (8 data, no parity, 1 stop)
   - Read/write operations for HCI commands

4. **upio.c** (GPIO Control)
   - Manages GPIO pins via rfkill:
     - BT_RESET (GPIO 17)
     - BT_WAKE (GPIO 12)
     - BT_HOST_WAKE (GPIO 11)
   - Power sequencing

5. **aic_conf.c** (Configuration Parser)
   - Reads vnd_*.txt files
   - Parses key=value configuration
   - Provides settings to other modules

**Configuration Files**:

- **vnd_generic.txt** (Used by default):
```
BLUETOOTH_UART_DEVICE_PORT = "/dev/ttyS1"
FW_PATCHFILE_LOCATION = "/vendor/firmware/"
LPM_IDLE_TIMEOUT_MULTIPLE = 5
SCO_USE_I2S_INTERFACE = TRUE
BTVND_DBG = TRUE
BTHW_DBG = TRUE
VNDUSERIAL_DBG = TRUE
UPIO_DBG = TURE
PROC_BTWRITE_TIMER_TIMEOUT_MS = 0
LPM_SLEEP_MODE = 0
```

- **vnd_aic8800.txt** (AIC8800-specific, alternative):
```
BLUETOOTH_UART_DEVICE_PORT = "/dev/ttyO1"
FW_PATCHFILE_LOCATION = "/vendor/firmware/"
[... similar settings ...]
```

---

### Change 2: Modified Library Name (Critical Fix)

**File**: `hardware/aic/aicbt/libbt/Android.mk`

**Before**:
```makefile
LOCAL_MODULE := libbt-vendor-aic
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_OWNER := aic
LOCAL_PROPRIETARY_MODULE := true
```

**After**:
```makefile
LOCAL_MODULE := libbt-vendor
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_OWNER := aic
LOCAL_PROPRIETARY_MODULE := true
LOCAL_OVERRIDES_MODULES := libbt-vendor-realtek
```

**Why This Change Was Critical**:
- Android Bluetooth stack hardcodes loading `/vendor/lib/libbt-vendor.so`
- It doesn't look for chip-specific names like `libbt-vendor-aic.so`
- Without this change, system loads Realtek's `libbt-vendor.so` instead
- Added `LOCAL_OVERRIDES_MODULES` to explicitly replace Realtek library

**Build System Impact**:
```
Old: /vendor/lib/libbt-vendor-aic.so     (not loaded by Android)
     /vendor/lib/libbt-vendor.so         (Realtek - wrong chip!)
     
New: /vendor/lib/libbt-vendor.so         (AIC8800 - correct!)
     /vendor/lib/libbt-vendor-realtek.so (not used)
```

---

### Change 3: Updated Product Makefile

**File**: `hardware/aic/aicbt/aicbt.mk`

**Before**:
```makefile
PRODUCT_PACKAGES += \
	libbt-vendor-aic
```

**After**:
```makefile
PRODUCT_PACKAGES += \
	libbt-vendor
```

**Purpose**: Ensures the correctly-named library is included in vendor image

---

### Change 4: Device Configuration

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk`

**Changes Added**:
```makefile
# Bluetooth configuration
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_AIC := true          # NEW: Enable AIC BT
BOARD_HAVE_BLUETOOTH_BCM := false         # NEW: Disable Broadcom
BOARD_HAVE_BLUETOOTH_RTK := false         # NEW: Disable Realtek
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/rockchip/rk356x/bluetooth

# Include AIC Bluetooth vendor library
$(call inherit-product-if-exists, hardware/aic/aicbt/aicbt.mk)  # NEW
```

**Purpose of Each Flag**:

1. **BOARD_HAVE_BLUETOOTH_AIC := true**
   - Triggers conditional build in `hardware/aic/aicbt/Android.mk`
   - Android.mk checks: `ifneq ($(BOARD_HAVE_BLUETOOTH_AIC),)`
   - Without this, AIC library won't be built

2. **BOARD_HAVE_BLUETOOTH_BCM := false**
   - Prevents Broadcom BT library from building
   - Broadcom's Android.mk also creates `libbt-vendor.so`
   - Would conflict with AIC's version

3. **BOARD_HAVE_BLUETOOTH_RTK := false**
   - Prevents Realtek BT library from building
   - Realtek also creates `libbt-vendor.so`
   - Avoids module name conflicts

4. **inherit-product-if-exists**
   - Includes `aicbt.mk` which adds `libbt-vendor` to PRODUCT_PACKAGES
   - Makes library part of vendor image

---

### Change 5: Disable Conflicting Libraries

**Action**: Renamed Broadcom BT directory to prevent build conflicts

**Commands**:
```bash
mv hardware/broadcom/libbt hardware/broadcom/libbt.disabled
mv hardware/broadcom/libbt.disabled/Android.mk \
   hardware/broadcom/libbt.disabled/Android.mk.disabled
```

**Why Necessary**:
- Setting `BOARD_HAVE_BLUETOOTH_BCM := false` should prevent Broadcom build
- However, `device/rockchip/common/wifi_bt_common.mk` overrides this after our config
- Include order: our mk → common mk (overrides our settings)
- Physical file removal ensures no conflicts

**Conflict Error Without This**:
```
error: hardware/broadcom/libbt: MODULE.TARGET.SHARED_LIBRARIES.libbt-vendor 
already defined by hardware/aic/aicbt/libbt
```

---

### Change 6: Fix Script Permissions

**File**: `hardware/aic/aicbt/libbt/gen-buildcfg.sh`

**Action**:
```bash
chmod +x hardware/aic/aicbt/libbt/gen-buildcfg.sh
```

**Purpose**: 
- This script generates `vnd_buildcfg.h` from `vnd_generic.txt`
- Build system calls it during compilation
- Without execute permission, build fails

**What the Script Does**:
```bash
# Reads vnd_generic.txt
BLUETOOTH_UART_DEVICE_PORT = "/dev/ttyS1"
LPM_SLEEP_MODE = 0

# Generates vnd_buildcfg.h
#define BLUETOOTH_UART_DEVICE_PORT "/dev/ttyS1"
#define LPM_SLEEP_MODE 0
```

---

## Build Process

### Build Commands:
```bash
cd /data/Projects/Maestro/Radxa/new-build

# Build Bluetooth vendor library
m libbt-vendor

# Build vendor image (includes libbt-vendor.so)
m vendorimage

# Flash to device
fastboot flash vendor out/target/product/rk356x_rock_3c_r/vendor.img
fastboot reboot
```

### Build Output:
```
[Building libbt-vendor]
├── Generate vnd_buildcfg.h from vnd_generic.txt
├── Compile bt_vendor_aicbt.c
├── Compile aic_hardware.c  
├── Compile userial_vendor.c
├── Compile upio.c
├── Compile aic_conf.c
├── Link → libbt-vendor.so (32-bit)
└── Link → libbt-vendor.so (64-bit)

[Install]
├── /vendor/lib/libbt-vendor.so
└── /vendor/lib64/libbt-vendor.so
```

---

## How It Works at Runtime

### Bluetooth Initialization Sequence:

1. **User Enables Bluetooth** (Settings → Bluetooth → ON)
   ```
   Android Framework (BluetoothManagerService)
   ```

2. **HAL Service Activation**
   ```
   android.hardware.bluetooth@1.0-service
   └── Loads /vendor/lib64/libbt-vendor.so (AIC library)
   ```

3. **AIC Vendor Library Init** (`bt_vendor_aicbt.c::init()`)
   ```c
   - Register callbacks for events
   - Initialize hardware structures
   - Prepare UART configuration
   ```

4. **Power On Operation** (`aic_hardware.c`)
   ```c
   - Set BT_RESET GPIO (via rfkill)
   - Configure UART /dev/ttyS1
   - Set baud rate to 1,500,000
   - Enable RTS/CTS flow control
   ```

5. **UART Communication** (`userial_vendor.c`)
   ```c
   - Open /dev/ttyS1
   - Configure termios settings:
     - cfsetispeed/cfsetospeed(B1500000)
     - CRTSCTS (hardware flow control)
     - CS8 (8 data bits)
     - No parity
   ```

6. **Firmware Handshake**
   ```
   AIC8800 chip firmware (already loaded by aic8800_btlpm kernel module)
   ↓
   UART HCI commands
   ↓
   Bluedroid stack gets HCI device
   ↓
   /dev/hci0 created
   ```

7. **Bluetooth Ready**
   ```
   - Android Bluetooth UI shows "ON"
   - Can scan for devices
   - Can pair and connect
   ```

---

## Hardware Communication Flow

```
┌─────────────────────────────────────────────────────┐
│  Android Bluetooth Framework                         │
│  (com.android.server.bluetooth)                      │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  Bluetooth HAL Service                               │
│  (android.hardware.bluetooth@1.0-service)            │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  AIC BT Vendor Library (libbt-vendor.so)            │
│  ┌─────────────────────────────────────────────┐   │
│  │ bt_vendor_aicbt.c  - Interface              │   │
│  │ aic_hardware.c     - Power/Init             │   │
│  │ userial_vendor.c   - UART I/O               │   │
│  │ upio.c             - GPIO control           │   │
│  │ aic_conf.c         - Config parser          │   │
│  └─────────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  Bluedroid Stack (system/bt)                        │
│  - HCI Layer                                         │
│  - L2CAP, SDP, RFCOMM protocols                     │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  UART Device (/dev/ttyS1)                           │
│  - Baud: 1,500,000 bps                              │
│  - Flow Control: RTS/CTS                             │
│  - Format: 8N1                                       │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  Kernel Module (aic8800_btlpm.ko)                   │
│  - Low power management                              │
│  - GPIO control (reset, wake)                        │
│  - rfkill interface                                  │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  AIC8800 Bluetooth Hardware                         │
│  - BT 4.2 / 5.0 BLE                                 │
│  - Firmware in kernel module                         │
└─────────────────────────────────────────────────────┘
```

---

## Key Configuration Values

### From vnd_generic.txt:
| Parameter | Value | Purpose |
|-----------|-------|---------|
| BLUETOOTH_UART_DEVICE_PORT | `/dev/ttyS1` | UART device path |
| FW_PATCHFILE_LOCATION | `/vendor/firmware/` | Firmware location (not used, embedded) |
| LPM_IDLE_TIMEOUT_MULTIPLE | 5 | Low power mode timeout multiplier |
| SCO_USE_I2S_INTERFACE | TRUE | Use I2S for SCO audio |
| LPM_SLEEP_MODE | 0 | Disable low power mode |
| BTVND_DBG | TRUE | Enable vendor debug logs |
| BTHW_DBG | TRUE | Enable hardware debug logs |

### From dmesg (Hardware Config):
| Parameter | Value | Purpose |
|-----------|-------|---------|
| UART RTS GPIO | 77 | Request-to-send flow control |
| BT Reset GPIO | 17 | Hardware reset line |
| BT Wake GPIO | 12 | Wake Bluetooth chip |
| BT Wake Host IRQ | 11 | Bluetooth wakes host |
| UART Baud | 1,500,000 | Communication speed |
| BT Mode | 5 | UART mode with flow control |

---

## Verification After Boot

### Check 1: Verify Correct Library Loaded
```bash
adb shell "ls -la /vendor/lib*/libbt-vendor.so"
```
**Expected**: File timestamps match build time, sizes ~24KB/37KB

### Check 2: Check Library Contents
```bash
adb shell "strings /vendor/lib64/libbt-vendor.so | grep -i aic"
```
**Expected**: Should show "AIC", "aic8800", etc. (not "realtek", "rtk")

### Check 3: Enable Bluetooth
```bash
adb shell "svc bluetooth enable"
sleep 3
adb shell "dumpsys bluetooth_manager | grep state"
```
**Expected**: `state: ON` (not OFF or crashing)

### Check 4: Check HCI Device
```bash
adb shell "ls -la /dev/hci0"
```
**Expected**: `crw------- 1 bluetooth bluetooth ... /dev/hci0`

### Check 5: Check Logs
```bash
adb logcat -d | grep -i "bt_vendor\|aicbt"
```
**Expected**: No "Permission denied", "crash", or error messages

---

## Summary of All Changes

| # | File | Change Type | Description |
|---|------|-------------|-------------|
| 1 | `hardware/aic/aicbt/` | **New Directory** | Copied entire AIC BT vendor library |
| 2 | `hardware/aic/aicbt/libbt/Android.mk` | **Modified** | Changed `libbt-vendor-aic` → `libbt-vendor` |
| 3 | `hardware/aic/aicbt/libbt/Android.mk` | **Modified** | Added `LOCAL_OVERRIDES_MODULES := libbt-vendor-realtek` |
| 4 | `hardware/aic/aicbt/aicbt.mk` | **Modified** | Changed package name to `libbt-vendor` |
| 5 | `device/.../wifi_bt_aic8800.mk` | **Modified** | Added `BOARD_HAVE_BLUETOOTH_AIC := true` |
| 6 | `device/.../wifi_bt_aic8800.mk` | **Modified** | Added `BOARD_HAVE_BLUETOOTH_BCM := false` |
| 7 | `device/.../wifi_bt_aic8800.mk` | **Modified** | Added `BOARD_HAVE_BLUETOOTH_RTK := false` |
| 8 | `device/.../wifi_bt_aic8800.mk` | **Modified** | Added inherit for `aicbt.mk` |
| 9 | `hardware/broadcom/libbt/` | **Renamed** | Disabled to prevent conflicts |
| 10 | `hardware/aic/aicbt/libbt/gen-buildcfg.sh` | **chmod +x** | Made script executable |

---

## Why Each Change Was Necessary

1. **Library Name Change** (`libbt-vendor-aic` → `libbt-vendor`)
   - **Without**: Android loads wrong library (Realtek)
   - **Result**: Bluetooth crashes immediately
   - **Fix**: Name must match hardcoded path in Android

2. **Disable BCM/RTK** 
   - **Without**: Multiple libraries define `libbt-vendor`
   - **Result**: Build error (duplicate module)
   - **Fix**: Only one library can have this name

3. **Script Permission**
   - **Without**: Build fails at config generation
   - **Result**: "Permission denied" error
   - **Fix**: Script must be executable

4. **Copy Vendor Library**
   - **Without**: No AIC-specific BT code exists
   - **Result**: Generic fallback can't talk to AIC8800
   - **Fix**: Proper UART/GPIO/power management

---

## Success Indicators

✅ **Bluetooth turns ON in Settings**
✅ **No crash loops or restarts**
✅ **/dev/hci0 device appears**
✅ **Can scan for nearby devices**
✅ **Can pair with devices**
✅ **WiFi and Bluetooth coexist (BT coexistence working)**

---

## Technical Notes

### Why Realtek Library Doesn't Work with AIC8800:
- Different UART configuration
- Different power-on sequence
- Different GPIO pins
- Different firmware loading mechanism
- Different HCI initialization commands

### Why Generic/Fallback Doesn't Work:
- Generic library has stub implementations
- Returns errors for all hardware operations
- Bluetooth stack can't initialize HCI
- No /dev/hci0 device created

### Why Library Name Matters:
- Android's `hardware/interfaces/bluetooth/1.0/default/bluetooth_hci.cc` hardcodes:
  ```c
  #define BLUETOOTH_LIBRARY_NAME "libbt-vendor.so"
  ```
- No chip detection or dynamic loading
- Simply `dlopen("libbt-vendor.so")`
- Must use exact name or won't load

---

## Files Deployed to Device

### Vendor Image Contents:
```
/vendor/lib/libbt-vendor.so           (24,208 bytes, AIC implementation)
/vendor/lib64/libbt-vendor.so         (37,848 bytes, AIC implementation)
/vendor/lib/modules/aic8800_btlpm.ko  (kernel module, already existed)
/vendor/etc/wifi/wpa_config.txt       (has [AIC8800] section for WiFi)
```

### System Image (No BT changes):
- Bluetooth framework unchanged
- HAL service unchanged
- Uses vendor library via HAL interface

---

## Complete Solution

**Problem**: Bluetooth hardware present but Android can't use it
**Root Cause**: Wrong vendor library (Realtek instead of AIC8800)
**Solution**: 
1. Integrate AIC8800 vendor library
2. Name it correctly (`libbt-vendor.so`)
3. Disable conflicting libraries
4. Build and flash vendor image

**Result**: Bluetooth fully functional ✅
