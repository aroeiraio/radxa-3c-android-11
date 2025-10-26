#!/system/bin/sh
# Enable rotation settings in Android Settings for Rock 3C
# This script enables rotation functionality without requiring overlays

echo "=== Enabling Rotation Settings in Android Settings ==="

# 1. Apply the rotation fix first
wm set-fix-to-user-rotation enabled
settings put system accelerometer_rotation 0

# 2. Enable accessibility settings that sometimes reveal rotation options
settings put secure accessibility_display_inversion_enabled 0
settings put secure accessibility_display_daltonizer_enabled 0

# 3. Try to enable developer options rotation settings
settings put global development_settings_enabled 1
settings put global stay_on_while_plugged_in 0

# 4. Force show rotation in quick settings
settings put secure sysui_qs_tiles "wifi,bt,dnd,rotation,flashlight,auto_rotate,location"

# 5. Set system properties that control Settings UI
setprop ro.debuggable 1

# 6. Show rotation status
echo ""
echo "Current settings:"
echo "  Rotation tiles: $(settings get secure sysui_qs_tiles | grep rotation)"
echo "  Fixed rotation: $(dumpsys window | grep mFixedToUserRotation)"
echo "  Current rotation: $(settings get system user_rotation)"

echo ""
echo "✓ Check Quick Settings panel for rotation tile"
echo "✓ Check Settings → Display for rotation options"
echo "✓ If still missing, rotation works via:"
echo "    settings put system user_rotation 0  # 0°"
echo "    settings put system user_rotation 0  # 0°"
echo "    settings put system user_rotation 2  # 180°"
echo "    settings put system user_rotation 3  # 270°"