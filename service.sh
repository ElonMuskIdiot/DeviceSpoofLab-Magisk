#!/system/bin/sh
# DeviceSpoofLabs - Service Script
# Runs after boot to ensure correct permissions

MODDIR=${0%/*}

# Fix permissions on every boot (in case they get reset)
chmod 755 "$MODDIR/post-fs-data.sh" 2>/dev/null
chmod 755 "$MODDIR/common/change_android_id.sh" 2>/dev/null

# Log for debugging
echo "[DeviceSpoofLabs] Permissions fixed on boot" >> /data/local/tmp/devicespooflab.log
