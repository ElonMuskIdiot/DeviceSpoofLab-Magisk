# Description: Post-boot tasks - CLI symlink, permissions, ANDROID_ID application
# This script runs after boot is complete (late_start service)

MODDIR=${0%/*}

LOG_FILE="/data/local/tmp/devicespooflab.log"
PERSONAS_DIR="${MODDIR}/personas"
CURRENT_PERSONA="${PERSONAS_DIR}/current.conf"
CLI_SCRIPT="${MODDIR}/common/devicespooflabs.sh"
CLI_SYMLINK="/system/bin/devicespooflabs"

log() {
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${TIMESTAMP}] [service] $1" >> "$LOG_FILE"
}

log "DeviceSpoofLabs service script starting..."

# Fix Script Permissions
log "Setting script permissions..."

chmod 755 "$MODDIR/post-fs-data.sh" 2>/dev/null
chmod 755 "$MODDIR/service.sh" 2>/dev/null
chmod 755 "$MODDIR/common/devicespooflabs.sh" 2>/dev/null
chmod 755 "$MODDIR/common/persona_manager.sh" 2>/dev/null
chmod 755 "$MODDIR/common/app_cleaner.sh" 2>/dev/null
chmod 755 "$MODDIR/common/utils.sh" 2>/dev/null

log "Script permissions set"

# Make CLI: 'devicespooflabs' command
log "Creating CLI symlink..."

if [ -f "$CLI_SCRIPT" ]; then
    # Remove old symlink if exists
    [ -L "$CLI_SYMLINK" ] && rm -f "$CLI_SYMLINK"

    mkdir -p "${MODDIR}/system/bin" 2>/dev/null

    cat > "${MODDIR}/system/bin/devicespooflabs" << 'WRAPPER_EOF'
#!/system/bin/sh
exec /data/adb/modules/devicespooflab/common/devicespooflabs.sh "$@"
WRAPPER_EOF

    chmod 755 "${MODDIR}/system/bin/devicespooflabs"
    log "CLI wrapper created at ${MODDIR}/system/bin/devicespooflabs"
else
    log "WARNING: CLI script not found: $CLI_SCRIPT"
fi

# Check if Persona is Configured
if [ ! -f "$CURRENT_PERSONA" ]; then
    log "No persona configured yet. Run 'devicespooflabs' to set up."
    log "Skipping ANDROID_ID and screen settings."
    exit 0
fi

# Apply ANDROID_ID
log "Checking ANDROID_ID..."

if [ -f "$CURRENT_PERSONA" ]; then
    . "$CURRENT_PERSONA"

    if [ -n "$ANDROID_ID" ]; then
        # Wait for settings service to be ready
        COUNTER=0
        while [ $COUNTER -lt 60 ]; do
            CURRENT_ID=$(settings get secure android_id 2>/dev/null)
            if [ -n "$CURRENT_ID" ] && [ "$CURRENT_ID" != "null" ]; then
                break
            fi
            sleep 1
            COUNTER=$((COUNTER + 1))
        done

        if [ "$CURRENT_ID" != "$ANDROID_ID" ]; then
            log "Applying ANDROID_ID: $ANDROID_ID"
            settings put secure android_id "$ANDROID_ID" 2>/dev/null

            # Verify
            NEW_ID=$(settings get secure android_id 2>/dev/null)
            if [ "$NEW_ID" = "$ANDROID_ID" ]; then
                log "ANDROID_ID applied successfully"
            else
                log "WARNING: ANDROID_ID may not have been applied correctly"
            fi
        else
            log "ANDROID_ID already matches persona"
        fi
    fi
fi

# Apply Screen Size/Density
log "Checking screen settings..."

if [ -f "$CURRENT_PERSONA" ]; then
    . "$CURRENT_PERSONA"

    # Wait for window manager
    sleep 5

    if [ -n "$SCREEN_WIDTH" ] && [ -n "$SCREEN_HEIGHT" ]; then
        CURRENT_SIZE=$(wm size 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | tail -1)
        TARGET_SIZE="${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

        if [ "$CURRENT_SIZE" != "$TARGET_SIZE" ]; then
            log "Applying screen size: $TARGET_SIZE"
            wm size "$TARGET_SIZE" 2>/dev/null
        fi
    fi

    if [ -n "$SCREEN_DENSITY" ]; then
        CURRENT_DENSITY=$(wm density 2>/dev/null | grep -oE '[0-9]+' | tail -1)

        if [ "$CURRENT_DENSITY" != "$SCREEN_DENSITY" ]; then
            log "Applying screen density: $SCREEN_DENSITY"
            wm density "$SCREEN_DENSITY" 2>/dev/null
        fi
    fi
fi

log "DeviceSpoofLabs service script complete"
log "Run 'devicespooflabs' command to manage personas"
