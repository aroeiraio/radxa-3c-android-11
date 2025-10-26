#!/system/bin/sh
# Restore previous rotation setting on boot using persistent property
# This script preserves user's manual rotation across reboots

log -t restore_rotation "Starting rotation restore from persistent property"

# Wait for system to be fully ready
sleep 10

# Restore from persistent property
saved_rotation=$(getprop persist.vendor.rotation.user_rotation)

log -t restore_rotation "Found saved rotation property: '$saved_rotation'"

if [ -n "$saved_rotation" ] && [ "$saved_rotation" != "null" ] && [ "$saved_rotation" != "0" ]; then
    # Validate saved rotation is in range 0-3
    case "$saved_rotation" in
        "1"|"2"|"3")
            log -t restore_rotation "Restoring saved rotation: $saved_rotation ($(($saved_rotation * 90))°)"

             # Apply initial rotation settings (ONCE before monitoring)
            settings put system user_rotation "$saved_rotation"
            settings put system accelerometer_rotation 0
            wm set-fix-to-user-rotation enabled
            log -t restore_rotation "Initial rotation applied: $saved_rotation"
            
            # Monitor for 60 seconds to fight Launcher3 resets (but not user changes!)
            # IMPORTANT: Only re-apply if rotation actually changes to avoid display reconfigs
            for i in $(seq 1 30); do
                current=$(settings get system user_rotation)
                
                # If current rotation is 0, that's likely a system reset - fight it
                if [ "$current" = "0" ] && [ "$saved_rotation" != "0" ]; then
                    log -t restore_rotation "Rotation was reset to 0, re-applying saved rotation $saved_rotation"
                    settings put system user_rotation "$saved_rotation"
                    # Only set these when we actually need to change something
                    settings put system accelerometer_rotation 0
                
                # If user changed to a different valid rotation (1,2,3), that's intentional - allow it!
                elif [ "$current" != "$saved_rotation" ] && [ "$current" != "0" ]; then
                    log -t restore_rotation "User changed rotation to $current, allowing change and updating saved value"
                    setprop persist.vendor.rotation.user_rotation "$current"
                    saved_rotation="$current"
                    # Stop defending after user makes intentional change
                    break
                fi
                # If rotation is correct, don't do anything (no display reconfig!)
                sleep 2
            done

            log -t restore_rotation "Rotation protection complete - final rotation: $(settings get system user_rotation)"
            ;;
    esac
else
    log -t restore_rotation "No saved rotation or rotation is 0, skipping restore"
fi

log -t restore_rotation "Rotation restore complete"