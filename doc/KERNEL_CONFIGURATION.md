# Kernel and Device Tree Configuration

## Overview

This document describes the kernel and device tree configurations for the Radxa Rock 3C (RK3566). The device tree file includes voltage regulator configurations that are critical for stable operation.

**Target Device**: Radxa Rock 3C (RK3566)
**Device Tree**: `rk3566-rock-3c.dts`

---

## Device Tree File

**Location**: `kernel/dts/rk3566-rock-3c.dts`
**Source Path**: `kernel/arch/arm64/boot/dts/rockchip/rk3566-rock-3c.dts`

---

## Voltage Regulator Configuration

The device tree includes several voltage regulators that provide power to different subsystems. These configurations are critical for stable operation.

### 1. VCC_SYS - Main System Power

```dts
vcc_sys: vcc-sys {
    compatible = "regulator-fixed";
    regulator-name = "vcc_sys";
    regulator-always-on;
    regulator-boot-on;
    regulator-min-microvolt = <5000000>;  // 5.0V
    regulator-max-microvolt = <5000000>;  // 5.0V
};
```

**Purpose**: Main 5V system power rail
**Critical**: Must be always-on for system stability

---

### 2. VCC3V3_SYS - 3.3V System Power

```dts
vcc3v3_sys: vcc3v3-sys {
    compatible = "regulator-fixed";
    regulator-name = "vcc3v3_sys";
    regulator-always-on;
    regulator-boot-on;
    regulator-min-microvolt = <3300000>;  // 3.3V
    regulator-max-microvolt = <3300000>;  // 3.3V
};
```

**Purpose**: 3.3V system power for peripherals
**Critical**: Powers I/O and peripheral devices

---

### 3. VCC5V0_SYS - 5V System Rail

```dts
vcc5v0_sys: vcc5v0-sys {
    compatible = "regulator-fixed";
    regulator-name = "vcc5v0_sys";
    regulator-always-on;
    regulator-boot-on;
    regulator-min-microvolt = <5000000>;  // 5.0V
    regulator-max-microvolt = <5000000>;  // 5.0V
};
```

**Purpose**: Secondary 5V power rail
**Critical**: Powers USB and other 5V peripherals

---

### 4. VCC5V0_HOST - USB Host Power

```dts
vcc5v0_host: vcc5v0-host-regulator {
    compatible = "regulator-fixed";
    regulator-name = "vcc5v0_host";
    regulator-always-on;
    // Enable GPIO and other configurations
};
```

**Purpose**: USB host port power
**When to Modify**: If USB devices are not powering on correctly

---

### 5. VCC5V0_OTG - USB OTG Power

```dts
vcc5v0_otg: vcc5v0-otg-regulator {
    compatible = "regulator-fixed";
    regulator-name = "vcc5v0_otg";
    // OTG-specific configurations
};
```

**Purpose**: USB OTG port power
**When to Modify**: If USB OTG functionality is not working

---

### 6. PCIE20_3V3 - PCIe Power (GPIO-Controlled)

```dts
pcie20_3v3: gpio-regulator {
    compatible = "regulator-gpio";
    regulator-name = "pcie20_3v3";
    regulator-min-microvolt = <100000>;   // 0.1V
    regulator-max-microvolt = <3300000>;  // 3.3V
    // GPIO control configurations
};
```

**Purpose**: PCIe/WiFi module power
**Type**: GPIO-controlled variable regulator
**When to Modify**: If WiFi or PCIe devices are not detected

---

## Voltage-Related Issues and Fixes

### Issue 1: System Instability / Random Crashes

**Symptom**: System crashes or freezes randomly

**Diagnosis**: Check if voltage regulators are properly configured

```bash
# Check regulator status
adb shell cat /sys/class/regulator/*/name
adb shell cat /sys/class/regulator/*/microvolts
adb shell cat /sys/class/regulator/*/state
```

**Solution**: Ensure `regulator-always-on` and `regulator-boot-on` are set for critical rails:
- vcc_sys
- vcc3v3_sys
- vcc5v0_sys

---

### Issue 2: USB Devices Not Working

**Symptom**: USB devices not detected or not powered

**Diagnosis**: Check USB power regulators

```bash
# Check USB regulator status
adb shell cat /sys/class/regulator/vcc5v0_host/microvolts
adb shell cat /sys/class/regulator/vcc5v0_otg/microvolts
```

**Solution**: Verify USB host and OTG regulators are enabled and providing 5V

---

### Issue 3: WiFi Module Not Detected

**Symptom**: WiFi not available in Settings

**Diagnosis**: Check PCIe power regulator

```bash
# Check PCIe regulator
adb shell cat /sys/class/regulator/pcie20_3v3/microvolts
adb shell cat /sys/class/regulator/pcie20_3v3/state
```

**Solution**:
1. Verify pcie20_3v3 regulator is enabled
2. Check GPIO configurations for PCIe power control
3. Ensure voltage is set to 3.3V (3300000 microvolts)

---

### Issue 4: Undervoltage / Brownout

**Symptom**: System resets under load, especially when peripherals are active

**Diagnosis**: Voltage drops below minimum threshold

**Solution**:
1. Check power supply provides adequate current (recommend 5V/3A minimum)
2. Verify voltage regulator configurations allow sufficient voltage range
3. Add decoupling capacitors if needed (hardware modification)

---

## How to Modify Device Tree

### Method 1: Edit Source File

```bash
# Edit device tree source
cd kernel/arch/arm64/boot/dts/rockchip
vim rk3566-rock-3c.dts

# Rebuild device tree
cd kernel
make dtbs

# Flash new device tree
adb reboot bootloader
fastboot flash dtbo path/to/dtbo.img
fastboot reboot
```

### Method 2: Device Tree Overlay

Create a device tree overlay to modify specific nodes without editing the main DTS:

```dts
/dts-v1/;
/plugin/;

/ {
    fragment@0 {
        target-path = "/";
        __overlay__ {
            vcc_sys: vcc-sys {
                regulator-always-on;
            };
        };
    };
};
```

---

## Kernel Configuration

### Required Kernel Configs for Rotation

```
CONFIG_DRM=y
CONFIG_DRM_ROCKCHIP=y
CONFIG_DRM_PANEL_ORIENTATION_QUIRKS=y
CONFIG_INPUT_TOUCHSCREEN=y
CONFIG_TOUCHSCREEN_GOODIX=y  # or your touchscreen driver
```

### Required Kernel Configs for Voltage Regulators

```
CONFIG_REGULATOR=y
CONFIG_REGULATOR_FIXED_VOLTAGE=y
CONFIG_REGULATOR_GPIO=y
CONFIG_REGULATOR_PWM=y
CONFIG_REGULATOR_RK808=y  # If using RK808 PMIC
```

### Check Current Kernel Config

```bash
# On device
adb shell cat /proc/config.gz | gunzip | grep REGULATOR

# Or from kernel source
cd kernel
grep REGULATOR .config
```

---

## Voltage Monitoring

### Monitor System Voltages

```bash
# List all regulators
adb shell ls /sys/class/regulator/

# Check specific regulator voltage
adb shell cat /sys/class/regulator/regulator.X/microvolts

# Check regulator state (enabled/disabled)
adb shell cat /sys/class/regulator/regulator.X/state

# Check regulator name
adb shell cat /sys/class/regulator/regulator.X/name
```

### Create Voltage Monitoring Script

```bash
#!/bin/bash
echo "=== Voltage Regulator Status ==="
for reg in /sys/class/regulator/regulator.*; do
    name=$(cat $reg/name 2>/dev/null)
    voltage=$(cat $reg/microvolts 2>/dev/null)
    state=$(cat $reg/state 2>/dev/null)

    if [ -n "$name" ]; then
        voltage_v=$(echo "scale=2; $voltage/1000000" | bc)
        echo "$name: ${voltage_v}V ($state)"
    fi
done
```

---

## Troubleshooting Voltage Issues

### 1. Check Power Supply

```bash
# Measure actual voltage at device power input
# Should be stable 5.0V ± 0.25V

# Check for voltage drop under load
# Connect multimeter and monitor while running stress test
```

### 2. Check Regulator Status via Kernel Logs

```bash
# Check kernel logs for regulator issues
adb shell dmesg | grep -i regulator
adb shell dmesg | grep -i voltage

# Look for:
# - "regulator X disabled"
# - "voltage out of range"
# - "regulator constraint violation"
```

### 3. Verify Device Tree Compilation

```bash
# Check device tree compilation
adb shell cat /proc/device-tree/compatible
adb shell ls /proc/device-tree/

# Verify your regulators are present
adb shell ls /proc/device-tree/vcc*/
```

---

## Critical Voltage Configurations for Rock 3C

### Minimum Required Voltages

| Rail | Voltage | Tolerance | Purpose |
|------|---------|-----------|---------|
| vcc_sys | 5.0V | ±5% | Main system power |
| vcc3v3_sys | 3.3V | ±5% | I/O and peripherals |
| vcc5v0_host | 5.0V | ±5% | USB host power |
| pcie20_3v3 | 3.3V | ±5% | PCIe/WiFi module |

### Power Budget

- Idle: ~1.5W (300mA @ 5V)
- Active: ~3-4W (600-800mA @ 5V)
- Peak (all peripherals): ~7.5W (1.5A @ 5V)
- **Recommended PSU**: 5V/3A (15W) minimum

---

## Integration with Build System

The device tree is automatically compiled during kernel build:

```makefile
# In kernel Makefile
dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3566-rock-3c.dtb

# Build command
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- dtbs
```

The compiled device tree blob (DTB) is included in the boot image or dtbo partition.

---

## Related Files

- Device Tree Source: `kernel/arch/arm64/boot/dts/rockchip/rk3566-rock-3c.dts`
- Compiled DTB: `kernel/arch/arm64/boot/dts/rockchip/rk3566-rock-3c.dtb`
- DTBO Image: `out/target/product/rk356x_rock_3c_r/dtbo.img`

---

## References

### Rockchip Documentation

- RK3566 Datasheet (voltage specifications)
- RK3566 TRM (Technical Reference Manual)
- Linux Regulator Framework Documentation

### Device Tree Bindings

- `Documentation/devicetree/bindings/regulator/fixed-regulator.txt`
- `Documentation/devicetree/bindings/regulator/gpio-regulator.txt`
- `Documentation/devicetree/bindings/regulator/pwm-regulator.txt`

---

**Document Version**: 1.0
**Date**: 2025-10-25
**Author**: Carlos Almeida Jr <carlos@aroeira.io>
