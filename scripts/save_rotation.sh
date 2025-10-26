#!/system/bin/sh
# Manual rotation save script - saves ONLY user-initiated changes
# Call this explicitly when user changes rotation via Settings or manual command
# Usage: save_rotation.sh [rotation_value]
#   If rotation_value is provided, saves that value
#   If no argument, saves current user_rotation setting

ROTATION_VALUE="$1"

if [ -z "$ROTATION_VALUE" ]; then
    # No argument provided, read current setting
    ROTATION_VALUE=$(settings get system user_rotation)
    log -t save_rotation "Reading current rotation: $ROTATION_VALUE"
else
    log -t save_rotation "Explicit rotation value provided: $ROTATION_VALUE"
fi

# Validate rotation value
if [ -z "$ROTATION_VALUE" ] || [ "$ROTATION_VALUE" = "null" ]; then
    log -t save_rotation "ERROR: Invalid rotation value: '$ROTATION_VALUE'"
    exit 1
fi

# Validate rotation is in range 0-3
case "$ROTATION_VALUE" in
    "0"|"1"|"2"|"3")
        log -t save_rotation "Saving rotation: $ROTATION_VALUE ($(($ROTATION_VALUE * 90))°) to persistent property"
        setprop persist.vendor.rotation.user_rotation "$ROTATION_VALUE"
        log -t save_rotation "Successfully saved rotation $ROTATION_VALUE to persist.vendor.rotation.user_rotation"
        ;;
    *)
        log -t save_rotation "ERROR: Invalid rotation value: $ROTATION_VALUE (must be 0-3)"
        exit 1
        ;;
esac
