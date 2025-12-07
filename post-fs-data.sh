# Description: Automatically loads and applies saved persona on boot
# This script runs during early boot (post-fs-data stage)

MODDIR=${0%/*}

PERSONAS_DIR="${MODDIR}/personas"
CURRENT_PERSONA="${PERSONAS_DIR}/current.conf"
BACKUP_PERSONA="${PERSONAS_DIR}/backup.conf"
DEFAULT_TEMPLATE="${PERSONAS_DIR}/pixel7pro_android15.conf"
LOG_FILE="/data/local/tmp/devicespooflab.log"

# Logging
log() {
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${TIMESTAMP}] [post-fs-data] $1" >> "$LOG_FILE"
}

log "DeviceSpoofLabs post-fs-data starting..."

# Wait for resetprop
COUNTER=0
until [ -x "$(command -v resetprop)" ] || [ $COUNTER -ge 30 ]; do
    sleep 1
    COUNTER=$((COUNTER + 1))
done

if [ ! -x "$(command -v resetprop)" ]; then
    log "ERROR: resetprop not available after 30 seconds"
    exit 1
fi

log "resetprop available"

# Ensure directories exist
[ ! -d "$PERSONAS_DIR" ] && mkdir -p "$PERSONAS_DIR" && chmod 755 "$PERSONAS_DIR"


# On first boot, create backup of original device
if [ ! -f "$BACKUP_PERSONA" ]; then
    log "First boot detected - creating original device backup"

    cat > "$BACKUP_PERSONA" << 'BACKUP_HEADER'
# DeviceSpoofLabs - Original Device Backup
# Created on first module boot
BACKUP_HEADER

    echo "PERSONA_NAME=\"Original Device Backup\"" >> "$BACKUP_PERSONA"
    echo "PERSONA_CREATED=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> "$BACKUP_PERSONA"

    # Backup current device props
    echo "DEVICE_BRAND=\"$(getprop ro.product.brand)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_MANUFACTURER=\"$(getprop ro.product.manufacturer)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_MODEL=\"$(getprop ro.product.model)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_NAME=\"$(getprop ro.product.name)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_DEVICE=\"$(getprop ro.product.device)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_BOARD=\"$(getprop ro.product.board)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_HARDWARE=\"$(getprop ro.hardware)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_PLATFORM=\"$(getprop ro.board.platform)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_ID=\"$(getprop ro.build.id)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_FINGERPRINT=\"$(getprop ro.build.fingerprint)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_INCREMENTAL=\"$(getprop ro.build.version.incremental)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_TYPE=\"$(getprop ro.build.type)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_TAGS=\"$(getprop ro.build.tags)\"" >> "$BACKUP_PERSONA"
    echo "VERSION_RELEASE=\"$(getprop ro.build.version.release)\"" >> "$BACKUP_PERSONA"
    echo "VERSION_SDK=\"$(getprop ro.build.version.sdk)\"" >> "$BACKUP_PERSONA"
    echo "VERSION_SECURITY_PATCH=\"$(getprop ro.build.version.security_patch)\"" >> "$BACKUP_PERSONA"
    echo "SERIAL_NUMBER=\"$(getprop ro.serialno)\"" >> "$BACKUP_PERSONA"
    echo "BOOTLOADER_VERSION=\"$(getprop ro.bootloader)\"" >> "$BACKUP_PERSONA"

    chmod 600 "$BACKUP_PERSONA"
    log "Original device backup created"
fi

# Check if persona exists
if [ ! -f "$CURRENT_PERSONA" ]; then
    log "No persona configured yet. Run 'devicespooflabs' to set up."
    log "Skipping prop spoofing until persona is configured."
    exit 0
fi

log "Loading persona from: $CURRENT_PERSONA"
. "$CURRENT_PERSONA"

# apply all the spoofed props
log "Applying device identity props..."

resetprop ro.product.brand "$DEVICE_BRAND"
resetprop ro.product.manufacturer "$DEVICE_MANUFACTURER"
resetprop ro.product.model "$DEVICE_MODEL"
resetprop ro.product.name "$DEVICE_NAME"
resetprop ro.product.device "$DEVICE_DEVICE"
resetprop ro.product.board "$DEVICE_BOARD"
resetprop ro.hardware "$DEVICE_HARDWARE"
resetprop ro.board.platform "$DEVICE_PLATFORM"

log "Applying system partition props..."

resetprop ro.product.system.brand "$DEVICE_BRAND"
resetprop ro.product.system.manufacturer "$DEVICE_MANUFACTURER"
resetprop ro.product.system.model "$DEVICE_MODEL"
resetprop ro.product.system.name "$DEVICE_NAME"
resetprop ro.product.system.device "$DEVICE_DEVICE"
resetprop ro.system.build.fingerprint "$BUILD_FINGERPRINT"
resetprop ro.system.build.product "$DEVICE_NAME"
resetprop ro.system.build.device "$DEVICE_DEVICE"

log "Applying vendor partition props..."

resetprop ro.product.vendor.brand "$DEVICE_BRAND"
resetprop ro.product.vendor.manufacturer "$DEVICE_MANUFACTURER"
resetprop ro.product.vendor.model "$DEVICE_MODEL"
resetprop ro.product.vendor.name "$DEVICE_NAME"
resetprop ro.product.vendor.device "$DEVICE_DEVICE"
resetprop ro.vendor.build.fingerprint "$BUILD_FINGERPRINT"
resetprop ro.vendor.product.device "$DEVICE_DEVICE"
resetprop ro.vendor.product.model "$DEVICE_MODEL"

log "Applying ODM partition props..."

resetprop ro.product.odm.brand "$DEVICE_BRAND"
resetprop ro.product.odm.manufacturer "$DEVICE_MANUFACTURER"
resetprop ro.product.odm.model "$DEVICE_MODEL"
resetprop ro.product.odm.name "$DEVICE_NAME"
resetprop ro.product.odm.device "$DEVICE_DEVICE"

log "Applying build information..."

resetprop ro.build.id "$BUILD_ID"
resetprop ro.build.display.id "$BUILD_DISPLAY_ID"
resetprop ro.build.version.incremental "$BUILD_INCREMENTAL"
resetprop ro.build.type "$BUILD_TYPE"
resetprop ro.build.tags "$BUILD_TAGS"
resetprop ro.build.fingerprint "$BUILD_FINGERPRINT"
resetprop ro.build.description "$BUILD_DESCRIPTION"
resetprop ro.build.product "$DEVICE_NAME"
resetprop ro.build.device "$DEVICE_DEVICE"
resetprop ro.build.characteristics "$BUILD_CHARACTERISTICS"
resetprop ro.bootimage.build.fingerprint "$BUILD_FINGERPRINT"

log "Applying Android version..."

resetprop ro.build.version.release "$VERSION_RELEASE"
resetprop ro.build.version.sdk "$VERSION_SDK"
resetprop ro.build.version.codename "$VERSION_CODENAME"
resetprop ro.build.version.security_patch "$VERSION_SECURITY_PATCH"

if [ -n "$SERIAL_NUMBER" ]; then
    log "Applying serial number: $SERIAL_NUMBER"
    resetprop ro.serialno "$SERIAL_NUMBER"
    resetprop ro.boot.serialno "$SERIAL_NUMBER"
fi

if [ -n "$BOOTLOADER_VERSION" ]; then
    log "Applying bootloader version..."
    resetprop ro.bootloader "$BOOTLOADER_VERSION"
fi
resetprop ro.boot.hardware "$BOOT_HARDWARE"
resetprop ro.boot.mode "$BOOT_MODE"

log "Applying security props..."

resetprop ro.debuggable "$DEBUGGABLE"
resetprop ro.secure "$SECURE"
resetprop ro.adb.secure "$ADB_SECURE"
resetprop ro.build.selinux "$BUILD_SELINUX"
resetprop ro.boot.verifiedbootstate "$VERIFIED_BOOT_STATE"
resetprop ro.boot.flash.locked "$FLASH_LOCKED"
resetprop ro.boot.vbmeta.device_state "$VBMETA_DEVICE_STATE"
resetprop ro.boot.warranty_bit "$WARRANTY_BIT"
resetprop sys.oem_unlock_allowed "$OEM_UNLOCK_ALLOWED"
resetprop ro.boot.veritymode "$VERITY_MODE"
resetprop ro.crypto.state "$CRYPTO_STATE"

log "Applying anti-emulator props..."

resetprop ro.kernel.qemu "$KERNEL_QEMU"
resetprop ro.boot.qemu "$BOOT_QEMU"

# Delete emulator specific props if they exist(to hide emu)
resetprop --delete ro.hardware.goldfish 2>/dev/null
resetprop --delete ro.hardware.ranchu 2>/dev/null

log "Applying CPU/architecture props..."

resetprop ro.product.cpu.abi "$CPU_ABI"
resetprop ro.product.cpu.abilist "$CPU_ABI"
resetprop ro.product.cpu.abilist64 "$CPU_ABI"
resetprop ro.system.product.cpu.abi "$CPU_ABI"
resetprop ro.vendor.product.cpu.abi "$CPU_ABI"
[ -n "$CPU_ABI2" ] && resetprop ro.product.cpu.abi2 "$CPU_ABI2"
resetprop ro.arch "$ARCH"

log "Applying display density..."
resetprop ro.sf.lcd_density "$SCREEN_DENSITY"

resetprop ro.treble.enabled "$TREBLE_ENABLED"

log "Applying carrier props..."

resetprop gsm.operator.alpha "$GSM_OPERATOR_ALPHA"
resetprop gsm.operator.numeric "$GSM_OPERATOR_NUMERIC"
resetprop gsm.sim.operator.alpha "$GSM_SIM_OPERATOR_ALPHA"
resetprop gsm.sim.operator.numeric "$GSM_SIM_OPERATOR_NUMERIC"
resetprop gsm.sim.operator.iso-country "$GSM_SIM_OPERATOR_COUNTRY"
resetprop persist.sys.timezone "$TIMEZONE"

resetprop persist.sys.usb.config "$USB_CONFIG"

# Summary
log "Persona applied successfully!"
log "Device: $DEVICE_MODEL"
log "Fingerprint: $BUILD_FINGERPRINT"
log "Security Patch: $VERSION_SECURITY_PATCH"
log "Serial: $SERIAL_NUMBER"
log "post-fs-data complete"
