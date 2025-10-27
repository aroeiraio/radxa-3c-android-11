# AIC8800 Bluetooth Integration Summary

## Changes Made for Bluetooth Support

### 1. Copied AIC8800 Bluetooth Vendor Library
**Source**: `/data/Projects/Maestro/Radxa/aic8800/src/SDIO/patch/for_Rockchip/3566/Android11/mod/android/hardware/aic/aicbt/`
**Destination**: `hardware/aic/aicbt/`

**Contents**:
- `libbt/src/bt_vendor_aicbt.c` - Main vendor interface
- `libbt/src/aic_hardware.c` - Hardware initialization
- `libbt/src/userial_vendor.c` - UART serial communication
- `libbt/src/upio.c` - GPIO control
- `libbt/src/aic_conf.c` - Configuration parsing
- `libbt/include/` - Header files
- `Android.mk` - Build configuration
- `aicbt.mk` - Product makefile

### 2. Modified Device Configuration
**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk`

**Added**:
```makefile
BOARD_HAVE_BLUETOOTH_AIC := true
$(call inherit-product-if-exists, hardware/aic/aicbt/aicbt.mk)
```

### 3. Built Library
**Output**:
- `/vendor/lib/libbt-vendor-aic.so` (32-bit)
- `/vendor/lib64/libbt-vendor-aic.so` (64-bit)

## Bluetooth Architecture

### Hardware Layer
```
AIC8800 Bluetooth Chip (via UART /dev/ttyS1)
    ↓
aic8800_btlpm.ko (kernel module - low power management)
    ↓
rfkill2 (RF kill switch control)
    ↓
/dev/ttyS1 (UART device)
```

### Software Stack
```
Android Bluetooth Framework
    ↓
android.hardware.bluetooth@1.0-service (HAL service)
    ↓
libbt-vendor-aic.so (AIC8800 vendor library)
    ↓
system/bt (Bluedroid stack)
    ↓
/dev/ttyS1 (UART communication)
    ↓
aic8800_btlpm.ko
    ↓
AIC8800 Bluetooth Hardware
```

## Current Status

### ✅ Completed
1. **Kernel Module**: `aic8800_btlpm` loads successfully
2. **Firmware**: BT patch loaded (fw_patch_8800d80_u02_ext0.bin)
3. **rfkill**: BT rfkill initialized (rfkill2)
4. **UART**: Device `/dev/ttyS1` exists with correct permissions
5. **HAL Service**: `android.hardware.bluetooth@1.0-service` running
6. **Vendor Library**: `libbt-vendor-aic.so` built and installed

### Hardware Configuration (from dmesg)
- **UART RTS GPIO**: 77
- **BT Reset GPIO**: 17
- **BT Wake GPIO**: 12
- **BT Wake Host IRQ**: 11
- **UART Baud**: 1500000
- **Flow Control**: Enabled
- **LPM**: Disabled (lpm_enable=0)
- **TX Power**: 28463

### rfkill Status
- `rfkill0`: bt_default (state: 0 - unblocked)
- `rfkill1`: phy0 (WiFi)
- `rfkill2`: bluetooth (AIC8800 BT, state: 0 - unblocked)

## Testing After Flash

### 1. Flash the new vendor image
```bash
cd /data/Projects/Maestro/Radxa/new-build
fastboot flash vendor out/target/product/rk356x_rock_3c_r/vendor.img
fastboot reboot
```

### 2. Verify vendor library
```bash
adb shell "ls -la /vendor/lib*/libbt-vendor-aic.so"
```

Expected output:
```
/vendor/lib/libbt-vendor-aic.so
/vendor/lib64/libbt-vendor-aic.so
```

### 3. Enable Bluetooth
```bash
# From Android Settings: Settings → Connected devices → Bluetooth → Turn ON
# OR via command:
adb shell "svc bluetooth enable"
```

### 4. Check Bluetooth status
```bash
adb shell "dumpsys bluetooth_manager"
```

Expected: `enabled: true`, `state: ON`

### 5. Check HCI device
```bash
adb shell "ls -la /dev/hci*"
```

Expected: `/dev/hci0` device should appear

### 6. Scan for devices
```bash
# From Android Settings: Settings → Connected devices → Bluetooth → Pair new device
# Should show nearby Bluetooth devices
```

## Known Configuration

### BT Mode
- **Mode**: 5 (UART mode with flow control)
- **Baud Rate**: 1,500,000 bps
- **Flow Control**: Enabled (UART RTS/CTS)
- **Low Power Mode**: Disabled

### Coexistence
- WiFi/BT coexistence enabled
- Commands seen in dmesg: BTCOEXMODE, BTCOEXSCAN

## Troubleshooting

### If Bluetooth doesn't enable:
1. Check logs:
   ```bash
   adb logcat -d | grep -iE '(bluetooth|btif|hci|aic.*bt)'
   ```

2. Check rfkill state:
   ```bash
   adb shell "cat /sys/class/rfkill/rfkill*/state"
   ```
   All should show `0` (unblocked)

3. Check UART device:
   ```bash
   adb shell "ls -la /dev/ttyS1"
   ```
   Should show: `crw-rw---- 1 bluetooth net_bt`

4. Check vendor library loaded:
   ```bash
   adb shell "lsof | grep libbt-vendor"
   ```

### If HCI device doesn't appear:
- Check if Bluedroid stack detected AIC vendor library
- Verify UART communication is working
- Check GPIO configuration in device tree

## Files Summary

### New Files
1. `hardware/aic/aicbt/` (entire directory)
   - Bluetooth vendor library source code

### Modified Files
1. `device/rockchip/rk356x/rk356x_rock_3c_r/wifi_bt_aic8800.mk`
   - Added: `BOARD_HAVE_BLUETOOTH_AIC := true`
   - Added: Inherit AIC BT makefile

### Built Artifacts
1. `/vendor/lib/libbt-vendor-aic.so`
2. `/vendor/lib64/libbt-vendor-aic.so`

## Next Steps

1. **Flash vendor image** with new Bluetooth library
2. **Test Bluetooth enable** in Android Settings
3. **Verify HCI device** creation
4. **Test pairing** with another Bluetooth device
5. **Test audio/data** transfers

## Expected Behavior After Fix

- Bluetooth toggle in Settings should work
- Should see nearby Bluetooth devices when scanning
- Should be able to pair with devices
- Should be able to transfer files via Bluetooth
- WiFi and Bluetooth should coexist without issues
