#!/system/bin/sh
# Dynamic HDMI resolution detection script
# Detects the optimal resolution based on EDID and sets appropriate display settings

# Wait for HDMI to be ready
sleep 2

# Check if HDMI is connected
if [ ! -f /sys/class/drm/card0-HDMI-A-1/status ]; then
    log -t hdmi_detect "HDMI device not found"
    exit 1
fi

hdmi_status=$(cat /sys/class/drm/card0-HDMI-A-1/status 2>/dev/null)
if [ "$hdmi_status" != "connected" ]; then
    log -t hdmi_detect "HDMI not connected, status: $hdmi_status"
    exit 1
fi

# Read available modes
if [ ! -f /sys/class/drm/card0-HDMI-A-1/modes ]; then
    log -t hdmi_detect "HDMI modes file not found"
    exit 1
fi

# Get the first (preferred) mode from EDID
preferred_mode=$(head -n 1 /sys/class/drm/card0-HDMI-A-1/modes 2>/dev/null)
log -t hdmi_detect "Preferred HDMI mode: $preferred_mode"

# Parse resolution from mode string (e.g., "1920x1080" from "1920x1080p60")
resolution=$(echo "$preferred_mode" | sed 's/[^0-9x].*$//')

# Set density based on resolution
case "$resolution" in
    "3840x2160"|"4096x2160")
        # 4K UHD
        density=320
        log -t hdmi_detect "Setting 4K resolution: $resolution"
        ;;
    "2560x1440"|"2560x1600")
        # 1440p/WQHD
        density=240
        log -t hdmi_detect "Setting 1440p resolution: $resolution"
        ;;
    "1920x1080"|"1920x1200")
        # Full HD
        density=160
        log -t hdmi_detect "Setting 1080p resolution: $resolution"
        ;;
    "1680x1050")
        # WSXGA+
        density=150
        log -t hdmi_detect "Setting WSXGA+ resolution: $resolution"
        ;;
    "1600x900"|"1600x1200")
        # HD+/UXGA
        density=140
        log -t hdmi_detect "Setting HD+ resolution: $resolution"
        ;;
    "1366x768")
        # HD
        density=120
        log -t hdmi_detect "Setting HD resolution: $resolution"
        ;;
    "1280x720"|"1280x800"|"1280x1024")
        # HD/WXGA/SXGA
        density=120
        log -t hdmi_detect "Setting HD/WXGA resolution: $resolution"
        ;;
    "1024x768")
        # XGA
        density=100
        log -t hdmi_detect "Setting XGA resolution: $resolution"
        ;;
    "800x600")
        # SVGA
        density=90
        log -t hdmi_detect "Setting SVGA resolution: $resolution"
        ;;
    *)
        # Unknown resolution, use auto-detection fallback
        log -t hdmi_detect "Unknown resolution: $resolution, using auto-detection"
        # Don't force resolution, let system auto-detect
        exit 0
        ;;
esac

# Apply the resolution and density
if [ -n "$resolution" ] && [ -n "$density" ]; then
    wm size "$resolution"
    wm density "$density"
    log -t hdmi_detect "Applied resolution: $resolution, density: $density"
else
    log -t hdmi_detect "Failed to determine resolution/density"
fi