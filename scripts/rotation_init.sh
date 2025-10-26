#!/system/bin/sh
# Rotation initialization script for Rock 3C
# This script ensures rotation is properly configured on boot

echo "=== Rock 3C Rotation Initialization ==="

# Wait for system to be ready
sleep 5

# Enable fixed-to-user-rotation (CRITICAL for manual rotation)
echo "Enabling fixed-to-user-rotation..."
wm set-fix-to-user-rotation enabled

# Ensure accelerometer rotation is disabled
settings put system accelerometer_rotation 0

# Log the current state
echo "Rotation configuration:"
echo "  user_rotation: $(settings get system user_rotation)"
echo "  accelerometer_rotation: $(settings get system accelerometer_rotation)"
echo "  fixed_to_user_rotation: $(dumpsys window | grep mFixedToUserRotation | cut -d'=' -f2)"

echo "✓ Rotation initialization complete"
