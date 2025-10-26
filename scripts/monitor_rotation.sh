#!/system/bin/sh
# Smart rotation monitor for Settings UI changes
# This service monitors user_rotation changes AFTER boot stabilizes
# and automatically saves them to persist.vendor.rotation.user_rotation

log -t monitor_rotation "Starting smart rotation monitor"

# CRITICAL: Wait for boot to fully complete AND for restore script to finish
# This prevents saving system resets during boot (70 seconds = 10s boot + 60s restore window)
log -t monitor_rotation "Waiting 70 seconds for boot and restore to complete..."
sleep 70

log -t monitor_rotation "Boot window complete, now monitoring user rotation changes"

# Get initial rotation state after boot stabilizes
prev_rotation=$(settings get system user_rotation)
log -t monitor_rotation "Initial rotation after boot: $prev_rotation"

# Monitor rotation changes indefinitely
while true; do
    current_rotation=$(settings get system user_rotation)
    
    # If rotation changed and it's a valid value
    if [ "$current_rotation" != "$prev_rotation" ] && [ -n "$current_rotation" ] && [ "$current_rotation" != "null" ]; then
        
        # Validate it's a valid rotation value (0-3)
        case "$current_rotation" in
            "0"|"1"|"2"|"3")
                log -t monitor_rotation "Settings UI rotation changed: $prev_rotation -> $current_rotation"
                log -t monitor_rotation "Auto-saving to persistent property"
                
                # Save to persistent property
                setprop persist.vendor.rotation.user_rotation "$current_rotation"
                
                log -t monitor_rotation "Rotation $current_rotation saved successfully"
                prev_rotation="$current_rotation"
                ;;
            *)
                log -t monitor_rotation "WARNING: Invalid rotation value: $current_rotation, ignoring"
                ;;
        esac
    fi
    
    # Check every 2 seconds (responsive but not resource-heavy)
    sleep 2
done

log -t monitor_rotation "Monitor stopped (should never reach here)"

