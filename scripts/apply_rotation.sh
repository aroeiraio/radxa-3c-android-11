#!/system/bin/sh
# Convenient script to apply AND save rotation
# This script both applies the rotation and saves it to persist across reboots
# Usage: apply_rotation.sh <rotation_value>
#   0 = 0°   (normal)
#   1 = 90°  (clockwise)
#   2 = 180° (upside down)
#   3 = 270° (counter-clockwise)

ROTATION_VALUE="$1"

if [ -z "$ROTATION_VALUE" ]; then
    echo "Usage: $0 <rotation_value>"
    echo "  0 = 0°   (normal)"
    echo "  1 = 90°  (clockwise)"
    echo "  2 = 180° (upside down)"
    echo "  3 = 270° (counter-clockwise)"
    echo ""
    echo "Current rotation settings:"
    echo "  user_rotation: $(settings get system user_rotation)"
    echo "  accelerometer_rotation: $(settings get system accelerometer_rotation)"
    echo "  persist.vendor.rotation.user_rotation: $(getprop persist.vendor.rotation.user_rotation)"
    exit 1
fi

# Validate rotation value
case "$ROTATION_VALUE" in
    "0"|"1"|"2"|"3")
        echo "Applying rotation: $ROTATION_VALUE ($(($ROTATION_VALUE * 90))°)"
        
        # Apply rotation settings
        settings put system user_rotation "$ROTATION_VALUE"
        settings put system accelerometer_rotation 0
        wm set-fix-to-user-rotation enabled
        
        # Save to persistent property
        /system/bin/save_rotation.sh "$ROTATION_VALUE"
        
        echo "✓ Rotation applied and saved!"
        echo ""
        echo "Current settings:"
        echo "  user_rotation: $(settings get system user_rotation)"
        echo "  accelerometer_rotation: $(settings get system accelerometer_rotation)"
        echo "  persist.vendor.rotation.user_rotation: $(getprop persist.vendor.rotation.user_rotation)"
        ;;
    *)
        echo "ERROR: Invalid rotation value: $ROTATION_VALUE (must be 0-3)"
        exit 1
        ;;
esac

