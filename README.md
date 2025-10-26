# Rotation Settings Implementation for Radxa Rock 3C

This repository contains the rotation settings implementation for the Radxa Rock 3C (RK3566) running Android 11.

## Overview

This implementation adds manual rotation settings to Android Settings → Display, allowing users to rotate the display to 0°, 90°, 180°, or 270° without an accelerometer.

## Implementation Approach

Uses a three-component architecture:

1. **Framework Overlay**: Device-specific configuration to enable rotation features
2. **Settings UI Component**: ListPreference for user interaction
3. **Preference Controller**: Logic to handle rotation changes

**Key Advantage**: No framework code modifications required - uses only overlay mechanism and Settings app changes.

## Build Information

- **Image**: `rk356x_rock_3c_r_20251025.1100_gpt.img`
- **Build Date**: October 25, 2025
- **Build Time**: 10:50 (04:30 build duration)
- **Size**: 4.1 GB

## Files Included

### Framework Overlay
- `device/rockchip/rk356x/rk356x_rock_3c_r/overlay/frameworks/base/core/res/res/values/config.xml`
  - Enables rotation features at framework level
  - Sets `config_supportAutoRotation=true`
  - Sets `config_enableRotationPreference=true` (Rockchip-specific)
  - Allows all 4 rotation orientations

### Settings App
- `packages/apps/Settings/res/xml/display_settings.xml`
  - Adds rotation ListPreference to Display settings

- `packages/apps/Settings/res/values/arrays.xml`
  - Rotation dropdown options (0°, 90°, 180°, 270°)

- `packages/apps/Settings/src/com/android/settings/display/RotationPreferenceController.java`
  - Controller that handles rotation preference interactions
  - Reads/writes `Settings.System.USER_ROTATION`

- `packages/apps/Settings/src/com/android/settings/DisplaySettings.java`
  - Registers RotationPreferenceController

### Device Configuration
- `device/rockchip/rk356x/rk356x_rock_3c_r/rk356x_rock_3c_r.mk`
  - Adds `DEVICE_PACKAGE_OVERLAYS` for directory-based overlay

### Scripts and Services (Optional)
- `scripts/` directory containing 16 shell scripts and init services
  - Rotation scripts: restore_rotation.sh, monitor_rotation.sh, apply_rotation.sh, etc.
  - HDMI scripts: hdmi_resolution_detect.sh, hdmi_switch.sh
  - USB scripts: usb_permissions.sh
  - Init services: init.rotation.rc, hdmi_force.rc, init.usb_permissions.rc
  - See `SCRIPTS_SERVICES.md` for complete documentation

### Kernel Configuration
- `kernel/dts/rk3566-rock-3c.dts`
  - Device tree with voltage regulator configurations
  - Critical for system stability
  - See `KERNEL_CONFIGURATION.md` for voltage specifications

### Documentation
- `TOUCHSCREEN_ROTATION_CHANGES.md`
  - Complete rotation implementation guide
  - Testing procedures and troubleshooting

- `SCRIPTS_SERVICES.md`
  - Documentation for all included scripts
  - Init service configuration
  - Advanced features and usage

- `KERNEL_CONFIGURATION.md`
  - Device tree and voltage regulator documentation
  - Kernel configuration requirements
  - Voltage monitoring and troubleshooting

## How to Apply These Changes

### Option 1: Copy Files to Your Build

```bash
# Copy framework overlay
cp -r device/rockchip/rk356x/rk356x_rock_3c_r/overlay \
   /path/to/your/android/build/device/rockchip/rk356x/rk356x_rock_3c_r/

# Copy Settings files
cp packages/apps/Settings/res/xml/display_settings.xml \
   /path/to/your/android/build/packages/apps/Settings/res/xml/

cp packages/apps/Settings/res/values/arrays.xml \
   /path/to/your/android/build/packages/apps/Settings/res/values/

cp packages/apps/Settings/src/com/android/settings/display/RotationPreferenceController.java \
   /path/to/your/android/build/packages/apps/Settings/src/com/android/settings/display/

cp packages/apps/Settings/src/com/android/settings/DisplaySettings.java \
   /path/to/your/android/build/packages/apps/Settings/src/com/android/settings/

# Update device makefile
# Merge relevant sections from device/rockchip/rk356x/rk356x_rock_3c_r/rk356x_rock_3c_r.mk
# into your device makefile
```

### Option 2: Generate Patch Files

```bash
# Generate patches for each component
cd /path/to/this/repo

# Framework overlay patch (new file, so create as a copy instruction)
# Settings patches
diff -u original/packages/apps/Settings/res/xml/display_settings.xml \
        packages/apps/Settings/res/xml/display_settings.xml \
        > patches/display_settings.patch

# Apply patches in your build tree
cd /path/to/your/android/build
patch -p1 < /path/to/patches/display_settings.patch
```

## Testing

After building and flashing:

### Test 1: Verify Settings UI
```bash
# Open Settings → Display
# Should show "Rotation" dropdown with 4 options
```

### Test 2: Verify Rotation Change
```bash
# Set rotation to 90° via Settings
adb shell settings get system user_rotation
# Should output: 1
```

### Test 3: Verify Framework Config
```bash
adb shell dumpsys display | grep -i rotation
```

### Test 4: Controller Logs
```bash
adb logcat | grep RotationPrefController
# Should show rotation changes
```

## Technical Details

### How It Works

```
User opens Settings → Display
   ↓
ListPreference renders dropdown with rotation options
   ↓
User selects "90 degrees" (value = 1)
   ↓
RotationPreferenceController.onPreferenceChange() called
   ↓
Settings.System.putInt(USER_ROTATION, 1)
   ↓
Framework reads USER_ROTATION and applies rotation
   ↓
Display rotates to 90°
```

### Storage

- Uses standard Android `Settings.System.USER_ROTATION` setting
- Values: 0 (0°), 1 (90°), 2 (180°), 3 (270°)

## Advantages

1. **Simplicity**: Only requires Settings app changes and framework overlay
2. **Maintainability**: No custom framework modifications to merge during AOSP updates
3. **Standard Android**: Uses Settings.System.USER_ROTATION like stock Android
4. **No Root Services**: Doesn't require root-level shell scripts
5. **Cleaner Architecture**: Follows standard PreferenceController pattern

## Limitations

1. **Persistence**: Relies on Android's standard Settings persistence
2. **No Custom Boot Scripts**: Can't fight system resets during boot
3. **Launcher3 Compatibility**: May experience Launcher3 rotation resets without Launcher3 modifications

For more details, see `TOUCHSCREEN_ROTATION_CHANGES.md` section 14.

## Author

- Carlos Almeida Jr <carlos@aroeira.io>
- Date: October 25, 2025
- Implementation Assistant: Claude Code

## License

Same as Android Open Source Project (Apache 2.0)
