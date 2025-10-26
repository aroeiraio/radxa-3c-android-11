#!/system/bin/sh
# Power actions script for Rock 3C
# Provides shutdown and reboot functionality

case "$1" in
    "shutdown")
        log -t power_actions "Initiating shutdown"
        # Sync filesystem before shutdown
        sync
        # Shutdown the system
        setprop sys.powerctl shutdown
        ;;
    "reboot")
        log -t power_actions "Initiating reboot"
        # Sync filesystem before reboot
        sync
        # Reboot the system
        setprop sys.powerctl reboot
        ;;
    *)
        echo "Usage: $0 {shutdown|reboot}"
        echo "Note: Advanced reboot options disabled for security"
        exit 1
        ;;
esac

exit 0