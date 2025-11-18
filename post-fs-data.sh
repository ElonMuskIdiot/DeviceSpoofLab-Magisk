#!/system/bin/sh
# DeviceSpoofLabs - Post-fs-data Script
# Author: @yubunus
# Description: Spoofs device identity to Google Pixel 7 Pro for testing purposes
# This script runs during early boot (post-fs-data stage)

MODDIR=${0%/*}

# Wait for Magisk resetprop to be ready
until [ -x "$(command -v resetprop)" ]; do
    sleep 1
done

# Log function
log_spoof() {
    echo "[DeviceSpoofLabs] $1"
}

log_spoof "Starting device prop spoofing..."

# ==========================================
# Google Pixel 7 Pro Device Properties
# ==========================================
# Device: Pixel 7 Pro (cheetah)
# Android: 14
# Build: UP1A.231005.007
# Security Patch: 2023-10-05
# ==========================================

# Basic device identification
resetprop ro.product.brand "google"
resetprop ro.product.name "cheetah"
resetprop ro.product.device "cheetah"
resetprop ro.product.model "Pixel 7 Pro"
resetprop ro.product.manufacturer "Google"

# Hardware information
resetprop ro.hardware "cheetah"
resetprop ro.product.board "cheetah"
resetprop ro.board.platform "gs201"
resetprop ro.hardware.chipset "Google Tensor G2"

# Build information with REAL Pixel 7 Pro fingerprint
resetprop ro.build.fingerprint "google/cheetah/cheetah:14/UP1A.231005.007/10754064:user/release-keys"
resetprop ro.build.description "cheetah-user 14 UP1A.231005.007 10754064 release-keys"
resetprop ro.build.product "cheetah"
resetprop ro.build.device "cheetah"
resetprop ro.build.version.release "14"
resetprop ro.build.version.sdk "34"
resetprop ro.build.version.incremental "10754064"
resetprop ro.build.tags "release-keys"
resetprop ro.build.type "user"

# Security patch - MUST match fingerprint!
resetprop ro.build.version.security_patch "2023-10-05"

# System props
resetprop ro.system.build.fingerprint "google/cheetah/cheetah:14/UP1A.231005.007/10754064:user/release-keys"
resetprop ro.system.build.product "cheetah"
resetprop ro.system.build.device "cheetah"

# Vendor props
resetprop ro.vendor.build.fingerprint "google/cheetah/cheetah:14/UP1A.231005.007/10754064:user/release-keys"
resetprop ro.vendor.product.device "cheetah"
resetprop ro.vendor.product.model "Pixel 7 Pro"

# Bootloader and baseband
resetprop ro.bootloader "cheetah-1.2-9643714"
resetprop ro.boot.hardware "cheetah"

# Anti-emulator/debug detection
resetprop ro.kernel.qemu "0"
resetprop ro.debuggable "0"
resetprop ro.secure "1"
resetprop ro.build.selinux "1"

# Additional product props for consistency
resetprop ro.product.system.brand "google"
resetprop ro.product.system.name "cheetah"
resetprop ro.product.system.device "cheetah"
resetprop ro.product.system.model "Pixel 7 Pro"
resetprop ro.product.system.manufacturer "Google"

resetprop ro.product.vendor.brand "google"
resetprop ro.product.vendor.name "cheetah"
resetprop ro.product.vendor.device "cheetah"
resetprop ro.product.vendor.model "Pixel 7 Pro"
resetprop ro.product.vendor.manufacturer "Google"

resetprop ro.product.odm.brand "google"
resetprop ro.product.odm.name "cheetah"
resetprop ro.product.odm.device "cheetah"
resetprop ro.product.odm.model "Pixel 7 Pro"
resetprop ro.product.odm.manufacturer "Google"

# Characteristics
resetprop ro.build.characteristics "nosdcard"

log_spoof "Device spoofed as Google Pixel 7 Pro"
log_spoof "Fingerprint: google/cheetah/cheetah:14/UP1A.231005.007/10754064:user/release-keys"
log_spoof "Security Patch: 2023-10-05"
log_spoof "Spoofing complete!"
