# Description: Manages device personas - create, load, apply, backup, restore

SCRIPT_DIR="${0%/*}"
. "${SCRIPT_DIR}/utils.sh"

# Backup Original Device Identity
backup_original_device() {
    if [ -f "$BACKUP_PERSONA" ]; then
        log_info "Original device backup already exists"
        return 0
    fi

    print_step "Creating backup of original device identity..."
    log_info "Creating original device backup"

    ensure_directories

    cat > "$BACKUP_PERSONA" << 'BACKUP_EOF'
# ===========================================
# DeviceSpoofLabs - Original Device Backup
# ===========================================
# This file contains your original device identity.
# It was created on first module boot.
# Use this to restore your device to its original state.
# ===========================================

BACKUP_EOF

    echo "PERSONA_NAME=\"Original Device Backup\"" >> "$BACKUP_PERSONA"
    echo "PERSONA_CREATED=\"$(get_timestamp)\"" >> "$BACKUP_PERSONA"
    echo "PERSONA_UPDATED=\"$(get_timestamp)\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# Device Identity" >> "$BACKUP_PERSONA"
    echo "DEVICE_BRAND=\"$(get_prop ro.product.brand)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_MANUFACTURER=\"$(get_prop ro.product.manufacturer)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_MODEL=\"$(get_prop ro.product.model)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_NAME=\"$(get_prop ro.product.name)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_DEVICE=\"$(get_prop ro.product.device)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_PRODUCT=\"$(get_prop ro.product.name)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_BOARD=\"$(get_prop ro.product.board)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_HARDWARE=\"$(get_prop ro.hardware)\"" >> "$BACKUP_PERSONA"
    echo "DEVICE_PLATFORM=\"$(get_prop ro.board.platform)\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# Build Information" >> "$BACKUP_PERSONA"
    echo "BUILD_ID=\"$(get_prop ro.build.id)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_DISPLAY_ID=\"$(get_prop ro.build.display.id)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_INCREMENTAL=\"$(get_prop ro.build.version.incremental)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_TYPE=\"$(get_prop ro.build.type)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_TAGS=\"$(get_prop ro.build.tags)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_FINGERPRINT=\"$(get_prop ro.build.fingerprint)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_DESCRIPTION=\"$(get_prop ro.build.description)\"" >> "$BACKUP_PERSONA"
    echo "BUILD_CHARACTERISTICS=\"$(get_prop ro.build.characteristics)\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# Android Version" >> "$BACKUP_PERSONA"
    echo "VERSION_RELEASE=\"$(get_prop ro.build.version.release)\"" >> "$BACKUP_PERSONA"
    echo "VERSION_SDK=\"$(get_prop ro.build.version.sdk)\"" >> "$BACKUP_PERSONA"
    echo "VERSION_CODENAME=\"$(get_prop ro.build.version.codename)\"" >> "$BACKUP_PERSONA"
    echo "VERSION_SECURITY_PATCH=\"$(get_prop ro.build.version.security_patch)\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# Serial Numbers" >> "$BACKUP_PERSONA"
    echo "SERIAL_NUMBER=\"$(get_prop ro.serialno)\"" >> "$BACKUP_PERSONA"
    echo "BOOT_SERIALNO=\"$(get_prop ro.boot.serialno)\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# Bootloader" >> "$BACKUP_PERSONA"
    echo "BOOTLOADER_VERSION=\"$(get_prop ro.bootloader)\"" >> "$BACKUP_PERSONA"
    echo "BOOT_HARDWARE=\"$(get_prop ro.boot.hardware)\"" >> "$BACKUP_PERSONA"
    echo "BOOT_MODE=\"$(get_prop ro.boot.mode)\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# Display" >> "$BACKUP_PERSONA"
    local SCREEN_SIZE=$(get_screen_size)
    local DENSITY=$(get_screen_density)
    echo "SCREEN_WIDTH=\"${SCREEN_SIZE%x*}\"" >> "$BACKUP_PERSONA"
    echo "SCREEN_HEIGHT=\"${SCREEN_SIZE#*x}\"" >> "$BACKUP_PERSONA"
    echo "SCREEN_DENSITY=\"${DENSITY}\"" >> "$BACKUP_PERSONA"
    echo "" >> "$BACKUP_PERSONA"

    echo "# ANDROID_ID" >> "$BACKUP_PERSONA"
    echo "ANDROID_ID=\"$(get_secure_setting android_id)\"" >> "$BACKUP_PERSONA"

    chmod 600 "$BACKUP_PERSONA"
    print_success "Original device backup created: $BACKUP_PERSONA"
    log_success "Original device backup created"
}

# Generate New Persona
generate_new_persona() {
    print_step "Generating new device persona..."
    log_info "Generating new persona"

    ensure_directories

    if [ -f "$DEFAULT_TEMPLATE" ]; then
        cp "$DEFAULT_TEMPLATE" "$CURRENT_PERSONA"
    else
        print_error "Default template not found: $DEFAULT_TEMPLATE"
        return 1
    fi

    local NEW_ANDROID_ID=$(generate_android_id)
    local NEW_SERIAL=$(generate_serial)
    local NEW_BOOTLOADER_VER=$(generate_bootloader_version)
    local TIMESTAMP=$(get_timestamp)

    sed -i "s|^PERSONA_CREATED=.*|PERSONA_CREATED=\"${TIMESTAMP}\"|" "$CURRENT_PERSONA"
    sed -i "s|^PERSONA_UPDATED=.*|PERSONA_UPDATED=\"${TIMESTAMP}\"|" "$CURRENT_PERSONA"
    sed -i "s|^SERIAL_NUMBER=.*|SERIAL_NUMBER=\"${NEW_SERIAL}\"|" "$CURRENT_PERSONA"
    sed -i "s|^BOOT_SERIALNO=.*|BOOT_SERIALNO=\"${NEW_SERIAL}\"|" "$CURRENT_PERSONA"
    sed -i "s|^BOOTLOADER_VERSION=.*|BOOTLOADER_VERSION=\"cheetah-1.2-${NEW_BOOTLOADER_VER}\"|" "$CURRENT_PERSONA"
    sed -i "s|^ANDROID_ID=.*|ANDROID_ID=\"${NEW_ANDROID_ID}\"|" "$CURRENT_PERSONA"

    # Make world-readable so Xposed module can read it
    chmod 0644 "$CURRENT_PERSONA"

    print_success "New persona generated!"
    print_info "Serial: $NEW_SERIAL"
    print_info "ANDROID_ID: $NEW_ANDROID_ID"
    log_success "New persona generated with serial=$NEW_SERIAL android_id=$NEW_ANDROID_ID"

    return 0
}

# Apply Persona (Set All Props)
apply_persona() {
    local PERSONA_FILE="${1:-$CURRENT_PERSONA}"

    if [ ! -f "$PERSONA_FILE" ]; then
        print_error "Persona file not found: $PERSONA_FILE"
        return 1
    fi

    print_step "Applying persona from: $PERSONA_FILE"
    log_info "Applying persona from $PERSONA_FILE"

    . "$PERSONA_FILE"
    local ERRORS=0

    print_step "Setting device identity..."
    set_prop "ro.product.brand" "$DEVICE_BRAND" || ERRORS=$((ERRORS + 1))
    set_prop "ro.product.manufacturer" "$DEVICE_MANUFACTURER" || ERRORS=$((ERRORS + 1))
    set_prop "ro.product.model" "$DEVICE_MODEL" || ERRORS=$((ERRORS + 1))
    set_prop "ro.product.name" "$DEVICE_NAME" || ERRORS=$((ERRORS + 1))
    set_prop "ro.product.device" "$DEVICE_DEVICE" || ERRORS=$((ERRORS + 1))
    set_prop "ro.product.board" "$DEVICE_BOARD" || ERRORS=$((ERRORS + 1))
    set_prop "ro.hardware" "$DEVICE_HARDWARE" || ERRORS=$((ERRORS + 1))
    set_prop "ro.board.platform" "$DEVICE_PLATFORM" || ERRORS=$((ERRORS + 1))

    print_step "Setting system partition props..."
    set_prop "ro.product.system.brand" "$DEVICE_BRAND"
    set_prop "ro.product.system.manufacturer" "$DEVICE_MANUFACTURER"
    set_prop "ro.product.system.model" "$DEVICE_MODEL"
    set_prop "ro.product.system.name" "$DEVICE_NAME"
    set_prop "ro.product.system.device" "$DEVICE_DEVICE"
    set_prop "ro.system.build.fingerprint" "$BUILD_FINGERPRINT"
    set_prop "ro.system.build.product" "$DEVICE_NAME"
    set_prop "ro.system.build.device" "$DEVICE_DEVICE"

    print_step "Setting vendor partition props..."
    set_prop "ro.product.vendor.brand" "$DEVICE_BRAND"
    set_prop "ro.product.vendor.manufacturer" "$DEVICE_MANUFACTURER"
    set_prop "ro.product.vendor.model" "$DEVICE_MODEL"
    set_prop "ro.product.vendor.name" "$DEVICE_NAME"
    set_prop "ro.product.vendor.device" "$DEVICE_DEVICE"
    set_prop "ro.vendor.build.fingerprint" "$BUILD_FINGERPRINT"
    set_prop "ro.vendor.product.device" "$DEVICE_DEVICE"
    set_prop "ro.vendor.product.model" "$DEVICE_MODEL"

    print_step "Setting ODM partition props..."
    set_prop "ro.product.odm.brand" "$DEVICE_BRAND"
    set_prop "ro.product.odm.manufacturer" "$DEVICE_MANUFACTURER"
    set_prop "ro.product.odm.model" "$DEVICE_MODEL"
    set_prop "ro.product.odm.name" "$DEVICE_NAME"
    set_prop "ro.product.odm.device" "$DEVICE_DEVICE"

    print_step "Setting build information..."
    set_prop "ro.build.id" "$BUILD_ID" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.display.id" "$BUILD_DISPLAY_ID" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.version.incremental" "$BUILD_INCREMENTAL" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.type" "$BUILD_TYPE" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.tags" "$BUILD_TAGS" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.fingerprint" "$BUILD_FINGERPRINT" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.description" "$BUILD_DESCRIPTION"
    set_prop "ro.build.product" "$DEVICE_NAME"
    set_prop "ro.build.device" "$DEVICE_DEVICE"
    set_prop "ro.build.characteristics" "$BUILD_CHARACTERISTICS"

    # Bootimage fingerprint
    set_prop "ro.bootimage.build.fingerprint" "$BUILD_FINGERPRINT"

    print_step "Setting Android version..."
    set_prop "ro.build.version.release" "$VERSION_RELEASE" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.version.sdk" "$VERSION_SDK" || ERRORS=$((ERRORS + 1))
    set_prop "ro.build.version.codename" "$VERSION_CODENAME"
    set_prop "ro.build.version.security_patch" "$VERSION_SECURITY_PATCH" || ERRORS=$((ERRORS + 1))

    print_step "Setting serial numbers..."
    if [ -n "$SERIAL_NUMBER" ]; then
        set_prop "ro.serialno" "$SERIAL_NUMBER"
        set_prop "ro.boot.serialno" "$SERIAL_NUMBER"
    fi

    print_step "Setting bootloader props..."
    if [ -n "$BOOTLOADER_VERSION" ]; then
        set_prop "ro.bootloader" "$BOOTLOADER_VERSION"
    fi
    set_prop "ro.boot.hardware" "$BOOT_HARDWARE"
    set_prop "ro.boot.mode" "$BOOT_MODE"

    print_step "Setting security props..."
    set_prop "ro.debuggable" "$DEBUGGABLE"
    set_prop "ro.secure" "$SECURE"
    set_prop "ro.adb.secure" "$ADB_SECURE"
    set_prop "ro.build.selinux" "$BUILD_SELINUX"
    set_prop "ro.boot.verifiedbootstate" "$VERIFIED_BOOT_STATE"
    set_prop "ro.boot.flash.locked" "$FLASH_LOCKED"
    set_prop "ro.boot.vbmeta.device_state" "$VBMETA_DEVICE_STATE"
    set_prop "ro.boot.warranty_bit" "$WARRANTY_BIT"
    set_prop "sys.oem_unlock_allowed" "$OEM_UNLOCK_ALLOWED"
    set_prop "ro.boot.veritymode" "$VERITY_MODE"
    set_prop "ro.crypto.state" "$CRYPTO_STATE"


    print_step "Setting anti-emulator props..."
    set_prop "ro.kernel.qemu" "$KERNEL_QEMU"
    if [ -n "$HARDWARE_GOLDFISH" ]; then
        set_prop "ro.hardware.goldfish" "$HARDWARE_GOLDFISH"
    else
        delete_prop "ro.hardware.goldfish"
    fi
    if [ -n "$HARDWARE_RANCHU" ]; then
        set_prop "ro.hardware.ranchu" "$HARDWARE_RANCHU"
    else
        delete_prop "ro.hardware.ranchu"
    fi
    set_prop "ro.boot.qemu" "$BOOT_QEMU"


    print_step "Setting CPU/architecture props..."
    set_prop "ro.product.cpu.abi" "$CPU_ABI"
    set_prop "ro.product.cpu.abilist" "$CPU_ABI"
    set_prop "ro.product.cpu.abilist64" "$CPU_ABI"
    set_prop "ro.system.product.cpu.abi" "$CPU_ABI"
    set_prop "ro.vendor.product.cpu.abi" "$CPU_ABI"
    if [ -n "$CPU_ABI2" ]; then
        set_prop "ro.product.cpu.abi2" "$CPU_ABI2"
    fi
    set_prop "ro.arch" "$ARCH"

    print_step "Setting display density..."
    set_prop "ro.sf.lcd_density" "$SCREEN_DENSITY"
    set_prop "ro.treble.enabled" "$TREBLE_ENABLED"

    print_step "Setting carrier props..."
    set_prop "gsm.operator.alpha" "$GSM_OPERATOR_ALPHA"
    set_prop "gsm.operator.numeric" "$GSM_OPERATOR_NUMERIC"
    set_prop "gsm.sim.operator.alpha" "$GSM_SIM_OPERATOR_ALPHA"
    set_prop "gsm.sim.operator.numeric" "$GSM_SIM_OPERATOR_NUMERIC"
    set_prop "gsm.sim.operator.iso-country" "$GSM_SIM_OPERATOR_COUNTRY"
    set_prop "persist.sys.timezone" "$TIMEZONE"

    set_prop "persist.sys.usb.config" "$USB_CONFIG"

    # Summary
    if [ $ERRORS -eq 0 ]; then
        print_success "All properties applied successfully!"
        log_success "Persona applied successfully"
    else
        print_warning "$ERRORS properties failed to apply"
        log_error "Persona applied with $ERRORS errors"
    fi

    return $ERRORS
}



# Apply ANDROID_ID (Requires running system)
apply_android_id() {
    local PERSONA_FILE="${1:-$CURRENT_PERSONA}"

    if [ ! -f "$PERSONA_FILE" ]; then
        return 1
    fi

    . "$PERSONA_FILE"

    if [ -n "$ANDROID_ID" ]; then
        print_step "Setting ANDROID_ID..."
        set_secure_setting "android_id" "$ANDROID_ID"
        if [ "$(get_secure_setting android_id)" = "$ANDROID_ID" ]; then
            print_success "ANDROID_ID set to: $ANDROID_ID"
            log_success "ANDROID_ID applied: $ANDROID_ID"
            return 0
        else
            print_error "Failed to set ANDROID_ID"
            log_error "Failed to apply ANDROID_ID"
            return 1
        fi
    fi
}

apply_screen_settings() {
    local PERSONA_FILE="${1:-$CURRENT_PERSONA}"

    if [ ! -f "$PERSONA_FILE" ]; then
        return 1
    fi

    . "$PERSONA_FILE"

    if [ -n "$SCREEN_WIDTH" ] && [ -n "$SCREEN_HEIGHT" ]; then
        print_step "Setting screen size: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
        set_screen_size "$SCREEN_WIDTH" "$SCREEN_HEIGHT"
    fi

    if [ -n "$SCREEN_DENSITY" ]; then
        print_step "Setting screen density: $SCREEN_DENSITY"
        set_screen_density "$SCREEN_DENSITY"
    fi
}

# View Current Persona
view_current_persona() {
    print_header "Current Persona Status"

    if [ ! -f "$CURRENT_PERSONA" ]; then
        print_warning "No persona is currently active"
        print_info "Run 'Generate NEW persona' to create one"
        return 1
    fi

    . "$CURRENT_PERSONA"

    print_color "$CYAN" "Persona Information:"
    print_separator
    echo "  Name:         ${PERSONA_NAME:-N/A}"
    echo "  Created:      ${PERSONA_CREATED:-N/A}"
    echo "  Updated:      ${PERSONA_UPDATED:-N/A}"
    echo ""

    print_color "$CYAN" "Device Identity:"
    print_separator
    echo "  Model:        $DEVICE_MODEL"
    echo "  Brand:        $DEVICE_BRAND"
    echo "  Device:       $DEVICE_DEVICE"
    echo "  Hardware:     $DEVICE_HARDWARE"
    echo "  Platform:     $DEVICE_PLATFORM"
    echo ""

    print_color "$CYAN" "Build Information:"
    print_separator
    echo "  Build ID:     $BUILD_ID"
    echo "  Fingerprint:  $BUILD_FINGERPRINT"
    echo "  Security:     $VERSION_SECURITY_PATCH"
    echo "  Android:      $VERSION_RELEASE (SDK $VERSION_SDK)"
    echo ""

    print_color "$CYAN" "Identifiers:"
    print_separator
    echo "  Serial:       ${SERIAL_NUMBER:-Not set}"
    echo "  ANDROID_ID:   ${ANDROID_ID:-Not set}"
    echo ""

    print_color "$CYAN" "Validation (Live System):"
    print_separator

    local LIVE_FP=$(get_prop ro.build.fingerprint)
    local LIVE_MODEL=$(get_prop ro.product.model)
    local LIVE_ANDROID_ID=$(get_secure_setting android_id)

    # Checks: fingerprint, model, android_id

    if [ "$LIVE_FP" = "$BUILD_FINGERPRINT" ]; then
        print_success "Fingerprint matches"
    else
        print_warning "Fingerprint mismatch!"
        echo "    Expected: $BUILD_FINGERPRINT"
        echo "    Actual:   $LIVE_FP"
    fi

    if [ "$LIVE_MODEL" = "$DEVICE_MODEL" ]; then
        print_success "Model matches"
    else
        print_warning "Model mismatch!"
        echo "    Expected: $DEVICE_MODEL"
        echo "    Actual:   $LIVE_MODEL"
    fi

    if [ "$LIVE_ANDROID_ID" = "$ANDROID_ID" ]; then
        print_success "ANDROID_ID matches"
    else
        print_warning "ANDROID_ID mismatch!"
        echo "    Expected: $ANDROID_ID"
        echo "    Actual:   $LIVE_ANDROID_ID"
    fi

    echo ""
    return 0
}

# Restore Original Backup
restore_original() {
    print_header "Restore Original Device"

    if [ ! -f "$BACKUP_PERSONA" ]; then
        print_error "No backup found!"
        print_info "Backup is created automatically on first boot"
        return 1
    fi

    print_warning "This will restore your original device identity!"
    echo ""
    print_info "Your original device properties will be restored."
    print_info "You will need to REBOOT for changes to take effect."
    echo ""

    if ! confirm "Continue with restore?"; then
        print_info "Restore cancelled"
        return 0
    fi

    cp "$BACKUP_PERSONA" "$CURRENT_PERSONA"
    # Make world-readable so Xposed module can read it
    chmod 0644 "$CURRENT_PERSONA"

    local TIMESTAMP=$(get_timestamp)
    sed -i "s|^PERSONA_UPDATED=.*|PERSONA_UPDATED=\"${TIMESTAMP}\"|" "$CURRENT_PERSONA"

    print_success "Original persona restored!"
    print_warning "REBOOT YOUR DEVICE to apply changes!"
    log_success "Original device backup restored"

    return 0
}

has_current_persona() {
    [ -f "$CURRENT_PERSONA" ]
}

has_backup() {
    [ -f "$BACKUP_PERSONA" ]
}
