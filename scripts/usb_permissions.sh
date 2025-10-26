#!/system/bin/sh
# USB permissions configuration script for Rock 3C
# Automatically grants USB permissions to whitelisted apps

log -t usb_permissions "Configuring USB permissions"

# Set USB device permissions for common device classes
# This allows apps to access these USB device types without prompting

# USB Mass Storage
echo "8:6:80" > /sys/class/android_usb/android0/usb_device_auto_permission

# USB HID devices (keyboard, mouse)
echo "3:1:1" >> /sys/class/android_usb/android0/usb_device_auto_permission
echo "3:1:2" >> /sys/class/android_usb/android0/usb_device_auto_permission

# USB Serial devices
echo "2:2:1" >> /sys/class/android_usb/android0/usb_device_auto_permission

# USB Audio and Video devices
echo "1:*:*" >> /sys/class/android_usb/android0/usb_device_auto_permission
echo "14:*:*" >> /sys/class/android_usb/android0/usb_device_auto_permission

# Set lenient USB security policy for development
setprop persist.vendor.usb.config.extra mass_storage
setprop ro.adb.secure 0

log -t usb_permissions "USB permissions configured successfully"