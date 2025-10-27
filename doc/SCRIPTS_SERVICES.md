# Scripts and Services Documentation

## Overview

This document describes the shell scripts and init services included in the rotation implementation. While the core rotation functionality is provided by the Settings UI implementation, these scripts offer additional features for advanced use cases.

**Note**: The primary rotation implementation (documented in `TOUCHSCREEN_ROTATION_CHANGES.md`) works without these scripts. These are included for completeness and alternative approaches.

---

## Init Services

### 1. init.rotation.rc

**Location**: `scripts/init.rotation.rc`
**Purpose**: Init service definition for rotation restoration and monitoring

**Services Defined**:

```rc
# One-time rotation restore after boot
service restore_rotation_once /system/bin/restore_rotation.sh
    user root
    group root
    oneshot
    seclabel u:r:su:s0
    disabled

# Background service to monitor and auto-save Settings UI rotation changes
service monitor_rotation_service /system/bin/monitor_rotation.sh
    user root
    group root
    seclabel u:r:su:s0
    disabled
```

**Trigger**:
```rc
on property:sys.boot_completed=1
    exec_start restore_rotation_once
    start monitor_rotation_service
```

**When to Use**: If you need automatic rotation restoration after reboot or monitoring of rotation changes.

---

### 2. hdmi_force.rc

**Location**: `scripts/hdmi_force.rc`
**Purpose**: Init service for HDMI resolution detection and configuration

**Services Defined**:
- HDMI resolution detection at boot
- HDMI hotplug monitoring

**When to Use**: For HDMI display configurations.

---

### 3. init.usb_permissions.rc

**Location**: `scripts/init.usb_permissions.rc`
**Purpose**: Init service for USB device permissions

**When to Use**: For USB peripheral access control.

---

## Rotation Scripts

### 1. restore_rotation.sh

**Location**: `scripts/restore_rotation.sh`
**Purpose**: Restores saved rotation after reboot

**Functionality**:
- Reads rotation from `persist.vendor.rotation.user_rotation`
- Applies saved rotation on boot
- Monitors for system resets during boot stabilization
- Fights unwanted rotation resets for 60 seconds

**Usage**:
```bash
# Manual execution
adb shell /system/bin/restore_rotation.sh
```

**When to Use**: If rotation doesn't persist across reboots with standard Settings mechanism.

---

### 2. monitor_rotation.sh

**Location**: `scripts/monitor_rotation.sh`
**Purpose**: Background service that monitors and auto-saves rotation changes

**Functionality**:
- Waits 70 seconds after boot (avoids saving boot-time resets)
- Polls `Settings.System.USER_ROTATION` every 2 seconds
- Validates rotation value (0-3)
- Saves to `persist.vendor.rotation.user_rotation`

**Usage**:
```bash
# Start monitoring
adb shell /system/bin/monitor_rotation.sh &
```

**When to Use**: For automatic persistence of rotation changes to vendor properties.

---

### 3. apply_rotation.sh

**Location**: `scripts/apply_rotation.sh`
**Purpose**: Helper script to apply rotation settings

**Usage**:
```bash
# Apply 90° rotation
adb shell /system/bin/apply_rotation.sh 1
```

**Parameters**:
- 0 = 0° (portrait)
- 1 = 90° (landscape)
- 2 = 180° (inverted portrait)
- 3 = 270° (inverted landscape)

---

### 4. save_rotation.sh

**Location**: `scripts/save_rotation.sh`
**Purpose**: Manually save current rotation to persistent property

**Usage**:
```bash
# Save current rotation
adb shell /system/bin/save_rotation.sh
```

**When to Use**: To manually persist the current rotation setting.

---

### 5. fix_rotation.sh

**Location**: `scripts/fix_rotation.sh`
**Purpose**: Manual rotation fix utility

**Usage**:
```bash
# Fix rotation issues
adb shell /system/bin/fix_rotation.sh
```

**When to Use**: Troubleshooting rotation problems.

---

### 6. rotation_init.sh

**Location**: `scripts/rotation_init.sh`
**Purpose**: Initial rotation setup during first boot

**Usage**: Called automatically by init system

**When to Use**: First-time device configuration.

---

### 7. enable_rotation_settings.sh

**Location**: `scripts/enable_rotation_settings.sh`
**Purpose**: Enable rotation settings in framework

**Usage**:
```bash
adb shell /system/bin/enable_rotation_settings.sh
```

**When to Use**: To ensure rotation settings are enabled.

---

### 8. touch_rotation_fix.sh

**Location**: `scripts/touch_rotation_fix.sh`
**Purpose**: Fix touch input orientation after rotation

**Usage**:
```bash
adb shell /system/bin/touch_rotation_fix.sh
```

**When to Use**: If touch input doesn't follow screen rotation.

---

### 9. rotate_hdmi.sh

**Location**: `scripts/rotate_hdmi.sh`
**Purpose**: HDMI-specific rotation handling

**Usage**:
```bash
# Rotate HDMI display
adb shell /system/bin/rotate_hdmi.sh [rotation]
```

**When to Use**: For HDMI display rotation.

---

## HDMI Scripts

### 1. hdmi_resolution_detect.sh

**Location**: `scripts/hdmi_resolution_detect.sh`
**Purpose**: Detect connected HDMI display resolution

**Usage**: Called automatically by hdmi_force.rc

---

### 2. hdmi_switch.sh

**Location**: `scripts/hdmi_switch.sh`
**Purpose**: Handle HDMI hotplug events

**Usage**: Called automatically by hdmi_force.rc

---

## USB Scripts

### 1. usb_permissions.sh

**Location**: `scripts/usb_permissions.sh`
**Purpose**: Configure USB device permissions

**Usage**: Called automatically by init.usb_permissions.rc

---

## Power Management Scripts

### 1. power_actions.sh

**Location**: `scripts/power_actions.sh`
**Purpose**: Handle power-related actions

**Usage**: Called automatically on power events

---

## Installation

To install these scripts in your build:

### Option 1: Add to Device Makefile

Add to `device/rockchip/rk356x/rk356x_rock_3c_r/rk356x_rock_3c_r.mk`:

```makefile
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.rotation.rc:system/etc/init/init.rotation.rc \
    $(LOCAL_PATH)/restore_rotation.sh:system/bin/restore_rotation.sh \
    $(LOCAL_PATH)/monitor_rotation.sh:system/bin/monitor_rotation.sh \
    $(LOCAL_PATH)/apply_rotation.sh:system/bin/apply_rotation.sh \
    $(LOCAL_PATH)/save_rotation.sh:system/bin/save_rotation.sh \
    $(LOCAL_PATH)/fix_rotation.sh:system/bin/fix_rotation.sh \
    $(LOCAL_PATH)/rotation_init.sh:system/bin/rotation_init.sh \
    $(LOCAL_PATH)/enable_rotation_settings.sh:system/bin/enable_rotation_settings.sh \
    $(LOCAL_PATH)/touch_rotation_fix.sh:system/bin/touch_rotation_fix.sh \
    $(LOCAL_PATH)/rotate_hdmi.sh:system/bin/rotate_hdmi.sh \
    $(LOCAL_PATH)/hdmi_force.rc:system/etc/init/hdmi_force.rc \
    $(LOCAL_PATH)/hdmi_resolution_detect.sh:system/bin/hdmi_resolution_detect.sh \
    $(LOCAL_PATH)/hdmi_switch.sh:system/bin/hdmi_switch.sh \
    $(LOCAL_PATH)/init.usb_permissions.rc:system/etc/init/init.usb_permissions.rc \
    $(LOCAL_PATH)/usb_permissions.sh:system/bin/usb_permissions.sh \
    $(LOCAL_PATH)/power_actions.sh:system/bin/power_actions.sh
```

### Option 2: Manual Installation

```bash
# Copy scripts to device
for script in scripts/*.sh; do
    adb push "$script" /system/bin/
    adb shell chmod 755 "/system/bin/$(basename $script)"
done

# Copy init files
for rc in scripts/*.rc; do
    adb push "$rc" /system/etc/init/
done

# Reboot
adb reboot
```

---

## Properties Used

These scripts interact with the following system properties:

### Rotation Properties

- `persist.vendor.rotation.user_rotation` - Saved rotation value (0-3)
- `persist.sys.rockchip.rotation` - Rotation in degrees (0, 90, 180, 270)
- `persist.sys.rotation` - System rotation value (0-3)
- `Settings.System.USER_ROTATION` - Current rotation from Settings

### Display Properties

- `sys.boot_completed` - Boot completion flag
- Various HDMI-related properties

---

## Integration with Settings UI

The Settings UI implementation (`TOUCHSCREEN_ROTATION_CHANGES.md`) can work independently or in conjunction with these scripts:

### Standalone Settings UI (Recommended)

- Uses `Settings.System.USER_ROTATION` only
- No scripts required
- Simpler, cleaner implementation

### Settings UI + Scripts (Advanced)

- Settings UI for user interaction
- Scripts for enhanced persistence and monitoring
- `monitor_rotation.sh` syncs Settings changes to vendor properties
- `restore_rotation.sh` enforces rotation at boot

**When to combine**: If you need guaranteed persistence across factory resets or custom boot-time behavior.

---

## Debugging

### Check if Services are Running

```bash
adb shell ps -A | grep rotation
```

### Check Rotation Properties

```bash
adb shell getprop | grep rotation
```

### Monitor Logs

```bash
# Rotation scripts
adb logcat | grep -E "restore_rotation|monitor_rotation"

# Settings controller
adb logcat | grep RotationPrefController
```

---

**Document Version**: 1.0
**Date**: 2025-10-25
**Author**: Carlos Almeida Jr <carlos@aroeira.io>
