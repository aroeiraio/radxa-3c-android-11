#!/system/bin/sh
# Touch rotation fix script for USB touchscreens
# This script forces input devices to reconfigure after rotation changes

# Wait for system to be fully ready
sleep 5

log -t touch_rotation "Starting touch rotation fix"

# Ensure accelerometer rotation is disabled (don't force user rotation)
settings put system accelerometer_rotation 0

# Force configuration change to refresh input devices
am broadcast -a android.intent.action.CONFIGURATION_CHANGED

# Small delay then refresh again
sleep 2
am broadcast -a android.intent.action.SCREEN_ON

log -t touch_rotation "Touch rotation fix applied"