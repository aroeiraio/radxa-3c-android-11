#!/system/bin/sh
# Manual rotation fix script for Rock 3C
# This script applies rotation settings that actually work

ROTATION_VALUE="$1"

if [ -z "$ROTATION_VALUE" ]; then
    echo "Usage: $0 <rotation_value>"
    echo "  0 = 0°   (normal)"
    echo "  1 = 90°  (clockwise)"
    echo "  2 = 180° (upside down)"
    echo "  3 = 270° (counter-clockwise)"
    exit 1
fi

echo "Applying rotation value: $ROTATION_VALUE"

# Set the Android settings
settings put system user_rotation "$ROTATION_VALUE"
settings put system accelerometer_rotation 0

# Set Rockchip-specific properties
case "$ROTATION_VALUE" in
    "0")
        setprop persist.sys.rockchip.rotation 0
        setprop persist.sys.rotation 0
        setprop ro.sf.hwrotation 0
        ;;
    "1")
        setprop persist.sys.rockchip.rotation 90
        setprop persist.sys.rotation 1
        setprop ro.sf.hwrotation 90
        ;;
    "2")
        setprop persist.sys.rockchip.rotation 180
        setprop persist.sys.rotation 2
        setprop ro.sf.hwrotation 180
        ;;
    "3")
        setprop persist.sys.rockchip.rotation 270
        setprop persist.sys.rotation 3
        setprop ro.sf.hwrotation 270
        ;;
esac

# Force SurfaceFlinger to restart to pick up rotation changes
echo "Restarting SurfaceFlinger to apply rotation..."
stop surfaceflinger
start surfaceflinger

echo "Rotation applied. Settings:"
echo "  user_rotation: $(settings get system user_rotation)"
echo "  persist.sys.rotation: $(getprop persist.sys.rotation)"
echo "  ro.sf.hwrotation: $(getprop ro.sf.hwrotation)"

# Save rotation to persistent property for next boot
/system/bin/save_rotation.sh "$ROTATION_VALUE"
echo "✓ Rotation saved for next boot"