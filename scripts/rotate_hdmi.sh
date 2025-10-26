#!/system/bin/sh
# HDMI rotation script for Rock 3C
# Due to Rockchip HWC limitations, rotation requires rebuilding the system

ROTATION_VALUE="$1"

if [ -z "$ROTATION_VALUE" ]; then
    echo "Usage: $0 <rotation_value>"
    echo "  0 = 0°   (normal)"
    echo "  1 = 90°  (clockwise)"
    echo "  2 = 180° (upside down)"
    echo "  3 = 270° (counter-clockwise)"
    echo ""
    echo "Current rotation setting:"
    echo "  user_rotation: $(settings get system user_rotation)"
    echo "  Hardware rotation: $(getprop ro.sf.hwrotation)"
    exit 1
fi

echo "Setting rotation to: $ROTATION_VALUE"

# Set Android rotation settings
settings put system user_rotation "$ROTATION_VALUE"
settings put system accelerometer_rotation 0

# Set Rockchip rotation properties for next boot
case "$ROTATION_VALUE" in
    "0")
        setprop persist.sys.rockchip.rotation 0
        setprop persist.sys.rotation 0
        echo "Set rotation to 0° (normal)"
        ;;
    "1")
        setprop persist.sys.rockchip.rotation 90
        setprop persist.sys.rotation 1
        echo "Set rotation to 90° (clockwise)"
        ;;
    "2")
        setprop persist.sys.rockchip.rotation 180
        setprop persist.sys.rotation 2
        echo "Set rotation to 180° (upside down)"
        ;;
    "3")
        setprop persist.sys.rockchip.rotation 270
        setprop persist.sys.rotation 3
        echo "Set rotation to 270° (counter-clockwise)"
        ;;
esac

echo ""
echo "⚠️  IMPORTANT: HDMI rotation changes require rebuilding the system image!"
echo "The ro.sf.hwrotation property must be set at build time in the device makefile."
echo ""
echo "To apply this rotation:"
echo "1. Update device makefile with: ro.sf.hwrotation=$(getprop persist.sys.rockchip.rotation)"
echo "2. Rebuild system image: m systemimage"
echo "3. Flash the updated system image"
echo ""
echo "Current settings saved for rebuild:"
echo "  persist.sys.rockchip.rotation: $(getprop persist.sys.rockchip.rotation)"
echo "  persist.sys.rotation: $(getprop persist.sys.rotation)"

# Save rotation to persistent property for next boot
/system/bin/save_rotation.sh "$ROTATION_VALUE"
echo "✓ Rotation saved to persist.vendor.rotation.user_rotation for next boot"