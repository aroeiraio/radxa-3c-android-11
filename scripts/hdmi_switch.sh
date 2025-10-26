#!/system/bin/sh
# HDMI display switching script

# Wait for system to stabilize
sleep 3

# Force HDMI as primary display
setprop vendor.hwc.device.primary HDMI-A
setprop vendor.hwc.device.extend DSI

# Restart SurfaceFlinger to apply changes
stop surfaceflinger
sleep 1
start surfaceflinger

# Log the action
log -t hdmi_switch "HDMI set as primary display"