# Rotation Settings Implementation for Radxa Rock 3C

## Overview

This document describes the rotation settings implementation for the Radxa Rock 3C (RK3566) running Android 11. This implementation adds manual rotation controls to Android Settings, allowing users to rotate the display to 0°, 90°, 180°, or 270° without an accelerometer.

**Target Device**: Radxa Rock 3C (RK3566)
**Android Version**: Android 11
**Build**: rk356x_rock_3c_r_20251025.1100_gpt.img
**Date**: 2025-10-25

---

## Implementation Architecture

The implementation uses a three-component architecture:

1. **Framework Overlay**: Device-specific configuration to enable rotation features
2. **Settings UI Component**: ListPreference for user interaction
3. **Preference Controller**: Logic to handle rotation changes

**Key Design Decision**: This implementation uses only overlay mechanism and Settings app changes - no framework source code modifications required.

---

## Components

### 1. Framework Overlay Configuration

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/overlay/frameworks/base/core/res/res/values/config.xml`

**Purpose**: Enable rotation features at the framework level without modifying framework source code.

**Configuration Values**:

```xml
<!-- Rotation configuration for Rock 3C (no accelerometer) -->
<bool name="config_supportAutoRotation">true</bool>
<bool name="config_allowAllRotations">true</bool>
<bool name="config_showRotationLock">true</bool>
<bool name="config_enableRotationPreference">true</bool>
<bool name="config_lidControlsScreenLock">false</bool>
<bool name="config_lidControlsSleep">false</bool>
```

**Critical Configurations**:
- `config_supportAutoRotation=true`: Required for RotationPolicy.isRotationSupported() to return true
- `config_enableRotationPreference=true`: Rockchip-specific config that enables rotation UI without accelerometer
- `config_allowAllRotations=true`: Allows all four rotation angles (0°, 90°, 180°, 270°)

---

### 2. Settings UI - ListPreference

**File**: `packages/apps/Settings/res/xml/display_settings.xml`

**Location**: Between `auto_rotate` and `color_mode` preferences (lines 87-93)

**Implementation**:
```xml
<ListPreference
    android:key="rotation"
    android:title="Rotation"
    android:summary="%s"
    android:entries="@array/rotation_entries"
    android:entryValues="@array/rotation_values"
    android:defaultValue="0" />
```

**Purpose**: Provides the visible dropdown UI in Settings → Display for rotation selection.

---

### 3. Rotation Arrays

**File**: `packages/apps/Settings/res/values/arrays.xml`

**Implementation**:
```xml
<string-array name="rotation_entries">
    <item>0 degrees</item>
    <item>90 degrees</item>
    <item>180 degrees</item>
    <item>270 degrees</item>
</string-array>

<string-array name="rotation_values" translatable="false">
    <item>0</item>
    <item>1</item>
    <item>2</item>
    <item>3</item>
</string-array>
```

**Purpose**: Defines the dropdown options and their corresponding values.

---

### 4. Rotation Preference Controller

**File**: `packages/apps/Settings/src/com/android/settings/display/RotationPreferenceController.java`

**Key Methods**:

```java
@Override
public void updateState(Preference preference) {
    final ListPreference rotationPreference = (ListPreference) preference;
    int currentRotation = Settings.System.getInt(mContext.getContentResolver(),
            USER_ROTATION, DEFAULT_ROTATION_VALUE);

    Log.d(TAG, "Current USER_ROTATION value: " + currentRotation);
    rotationPreference.setValue(String.valueOf(currentRotation));
    updateRotationPreferenceDescription(rotationPreference, currentRotation);
}

@Override
public boolean onPreferenceChange(Preference preference, Object newValue) {
    try {
        int rotation = Integer.parseInt((String) newValue);
        Log.d(TAG, "Setting USER_ROTATION to: " + rotation);

        Settings.System.putInt(mContext.getContentResolver(), USER_ROTATION, rotation);
        updateRotationPreferenceDescription((ListPreference) preference, rotation);
        return true;
    } catch (NumberFormatException e) {
        Log.e(TAG, "Could not persist rotation setting", e);
        return false;
    }
}
```

**Purpose**:
- Reads current rotation from `Settings.System.USER_ROTATION`
- Writes new rotation value when user makes a selection
- Updates preference summary to show current selection

**Storage**: Uses `Settings.System.USER_ROTATION` (standard Android setting)

**Rotation Values**:
- 0 = 0° (portrait)
- 1 = 90° (landscape)
- 2 = 180° (inverted portrait)
- 3 = 270° (inverted landscape)

---

### 5. Controller Registration

**File**: `packages/apps/Settings/src/com/android/settings/DisplaySettings.java`

**Changes Required**:

1. **Import statement** (line 30):
```java
import com.android.settings.display.RotationPreferenceController;
```

2. **Key constant** (line 51):
```java
private static final String KEY_ROTATION = "rotation";
```

3. **Controller instantiation** (line 98):
```java
controllers.add(new RotationPreferenceController(context, KEY_ROTATION));
```

**Purpose**: Registers the RotationPreferenceController so it manages the rotation ListPreference.

---

### 6. Build Configuration

**File**: `device/rockchip/rk356x/rk356x_rock_3c_r/rk356x_rock_3c_r.mk`

**Configuration**:
```makefile
# Use directory-based overlay for framework resources
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
```

**Purpose**: Enables the framework overlay mechanism to apply the rotation configuration.

---

## How It Works

### User Flow

```
1. User opens Settings → Display
   ↓
2. System displays "Rotation" ListPreference with dropdown
   ↓
3. RotationPreferenceController.updateState() reads current rotation
   ↓
4. Dropdown shows current selection (e.g., "90 degrees")
   ↓
5. User selects different rotation (e.g., "180 degrees")
   ↓
6. RotationPreferenceController.onPreferenceChange() called with value "2"
   ↓
7. Controller writes to Settings.System.USER_ROTATION = 2
   ↓
8. Framework reads USER_ROTATION and applies rotation
   ↓
9. Display rotates to 180°
```

### Technical Flow

```
Settings UI
    ↓
RotationPreferenceController
    ↓
Settings.System.USER_ROTATION (standard Android setting)
    ↓
Framework WindowManager
    ↓
Display rotation applied
```

---

## Files Modified/Created

| File | Type | Action |
|------|------|--------|
| `device/rockchip/rk356x/rk356x_rock_3c_r/overlay/frameworks/base/core/res/res/values/config.xml` | Framework Overlay | Created |
| `packages/apps/Settings/res/xml/display_settings.xml` | Settings UI | Modified |
| `packages/apps/Settings/res/values/arrays.xml` | Settings Resources | Modified |
| `packages/apps/Settings/src/com/android/settings/display/RotationPreferenceController.java` | Settings Controller | Created |
| `packages/apps/Settings/src/com/android/settings/DisplaySettings.java` | Settings Integration | Modified |
| `device/rockchip/rk356x/rk356x_rock_3c_r/rk356x_rock_3c_r.mk` | Build Config | Modified |

**Total**: 6 files (2 created, 4 modified)

---

## Testing Procedures

### Test 1: Verify Settings UI

```bash
# After flashing, navigate to Settings → Display
# Verify "Rotation" option appears with dropdown showing 4 options:
# - 0 degrees
# - 90 degrees
# - 180 degrees
# - 270 degrees
```

### Test 2: Verify Rotation Change

```bash
# Set rotation to 90° via Settings UI
adb shell settings get system user_rotation
# Expected output: 1

# Set rotation to 180°
adb shell settings get system user_rotation
# Expected output: 2
```

### Test 3: Verify Framework Configuration

```bash
# Check if rotation is enabled at framework level
adb shell dumpsys display | grep -i rotation
# Should show rotation-related configuration
```

### Test 4: Monitor Controller Logs

```bash
# Watch rotation changes in logcat
adb logcat | grep RotationPrefController

# Expected log messages:
# RotationPrefController: Current USER_ROTATION value: 0
# RotationPrefController: Setting USER_ROTATION to: 1
# RotationPrefController: Setting rotation preference summary to: 90 degrees
```

### Test 5: Verify Persistence

```bash
# Set rotation to 90°
# Reboot device
adb reboot
# After boot, check if rotation persists
adb shell settings get system user_rotation
# Should still be: 1
```

---

## Build Information

**Image Name**: `rk356x_rock_3c_r_20251025.1100_gpt.img`
**Build Date**: October 25, 2025
**Build Time**: 10:50 AM (04:30 build duration)
**Image Size**: 4.1 GB
**Location**: `IMAGE/RK356X_ROCK_3C_R_USERDEBUG_RK3566-ROCK-3C_ENG..20251025.110000_20251025.1100/IMAGES/`

**Build Verification**:
- ✅ Settings.apk compiled with RotationPreferenceController
- ✅ Framework overlay present in build output
- ✅ rotation_entries and rotation_values arrays compiled
- ✅ DisplaySettings.java registered controller successfully

---

## Implementation Advantages

1. **No Framework Modifications**: Uses only overlay mechanism - easier to maintain across AOSP updates
2. **Standard Android API**: Uses `Settings.System.USER_ROTATION` like stock Android
3. **Clean Architecture**: Follows standard PreferenceController pattern
4. **Simple Integration**: Only 6 files modified/created
5. **Maintainable**: No custom shell scripts or init services required

---

## Known Limitations

1. **Persistence**: Relies on Android's standard Settings persistence mechanism
2. **Launcher3 Compatibility**: May experience rotation resets when returning to home screen (Launcher3 doesn't respect manual rotation by default)
3. **Boot-time Restoration**: No custom boot scripts to enforce rotation after reboot

---

## Troubleshooting

### Issue: Rotation option doesn't appear in Settings

**Diagnosis**:
```bash
# Check if framework overlay is applied
adb shell dumpsys package | grep -i overlay
```

**Solution**: Verify framework overlay files are in correct location and `DEVICE_PACKAGE_OVERLAYS` is set in device makefile.

### Issue: Rotation changes but doesn't persist after reboot

**Diagnosis**:
```bash
# Check if Settings database persists across reboots
adb shell settings get system user_rotation
# Before and after reboot
```

**Solution**: This is expected behavior with standard Settings persistence. Value may reset to 0 on factory reset.

### Issue: Touch input doesn't follow rotation

**Diagnosis**:
```bash
# Check input device configuration
adb shell getevent -lp
```

**Solution**: Verify input device configuration supports all rotation angles.

### Issue: Launcher3 resets rotation when returning to home

**Diagnosis**: Launcher3 doesn't respect `Settings.System.USER_ROTATION` by default.

**Solution**: This is a known limitation of this implementation. Requires Launcher3 modifications (not included in this implementation).

---

## Developer Notes

### Why This Approach?

This implementation was chosen for its simplicity and maintainability:

- **No framework patches**: Easier to merge AOSP updates
- **Standard Android**: Uses existing Settings infrastructure
- **Minimal changes**: Only 6 files modified
- **Clean separation**: Overlay vs app code clearly separated

### Alternative Approaches Considered

Other rotation implementation methods (not used in this build):

1. **DisplayRotation.java modifications**: More robust but requires framework patches
2. **Shell scripts + init services**: Can enforce rotation at boot but adds complexity
3. **Launcher3 modifications**: Would fix home screen rotation resets but requires app patches

This implementation chose simplicity over those features.

---

## References

### Android Settings System

- `Settings.System.USER_ROTATION`: Standard Android setting for manual rotation
- `Settings.System.ACCELEROMETER_ROTATION`: Auto-rotation toggle (not used here)

### Framework Configuration

- `config_supportAutoRotation`: Enables rotation support in WindowManager
- `config_allowAllRotations`: Permits 180° rotation
- `config_enableRotationPreference`: Rockchip-specific flag for manual rotation UI

### Code References

- Framework overlay: `device/rockchip/rk356x/rk356x_rock_3c_r/overlay/frameworks/base/core/res/res/values/config.xml:156-167`
- ListPreference: `packages/apps/Settings/res/xml/display_settings.xml:87-93`
- Controller: `packages/apps/Settings/src/com/android/settings/display/RotationPreferenceController.java`
- Registration: `packages/apps/Settings/src/com/android/settings/DisplaySettings.java:30,51,98`

---

**Document Version**: 2.0
**Last Updated**: 2025-10-25
**Author**: Carlos Almeida Jr <carlos@aroeira.io>
**Implementation Assistant**: Claude Code
