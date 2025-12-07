# Description: Common functions used across all module scripts


MODDIR="/data/adb/modules/devicespooflab"
PERSONAS_DIR="${MODDIR}/personas"
LOG_FILE="/data/local/tmp/devicespooflab.log"
CURRENT_PERSONA="${PERSONAS_DIR}/current.conf"
BACKUP_PERSONA="${PERSONAS_DIR}/backup.conf"
DEFAULT_TEMPLATE="${PERSONAS_DIR}/pixel7pro_android15.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_color() {
    echo -e "${1}${2}${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}[OK] ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARN] ${1}${NC}"
}

print_info() {
    echo -e "${CYAN}[INFO] ${1}${NC}"
}

print_step() {
    echo -e "${BLUE}=> ${1}${NC}"
}

print_header() {
    echo ""
    print_color "$MAGENTA" "==========================================="
    print_color "$MAGENTA" "  $1"
    print_color "$MAGENTA" "==========================================="
    echo ""
}

print_separator() {
    echo "-------------------------------------------"
}

log() {
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${TIMESTAMP}] $1" >> "$LOG_FILE"
}

log_error() {
    log "[ERROR] $1"
    print_error "$1"
}

log_success() {
    log "[OK] $1"
}

log_info() {
    log "[INFO] $1"
}

# System Checks
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root!"
        print_info "Run: su -c 'devicespooflabs' or use 'su' first"
        exit 1
    fi
}

check_magisk() {
    if [ ! -x "$(command -v resetprop)" ]; then
        print_error "Magisk resetprop not found!"
        print_info "This module requires Magisk to function"
        exit 1
    fi
}

check_module_installed() {
    if [ ! -d "$MODDIR" ]; then
        print_error "Module directory not found: $MODDIR"
        print_info "Please ensure DeviceSpoofLabs is properly installed"
        exit 1
    fi
}

ensure_directories() {
    [ ! -d "$PERSONAS_DIR" ] && mkdir -p "$PERSONAS_DIR" && chmod 755 "$PERSONAS_DIR"
    [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE" && chmod 644 "$LOG_FILE"
}

# Random Generation Functions

# random hex and string given length, func to avoid redundancy
generate_hex() {
    local LENGTH=${1:-16}
    od -An -N$((LENGTH / 2)) -tx1 /dev/urandom | tr -d ' \n' | cut -c1-${LENGTH}
}
generate_alphanumeric() {
    local LENGTH=${1:-16}
    cat /dev/urandom | tr -dc 'A-Z0-9' | head -c ${LENGTH}
}

generate_android_id() {
    generate_hex 16
}

generate_serial() {
    generate_alphanumeric 12
}

generate_bootloader_version() {
    local RANDOM_NUM=$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')
    echo "$((RANDOM_NUM % 90000000 + 10000000))"
}

get_prop() {
    local PROP_NAME="$1"
    getprop "$PROP_NAME" 2>/dev/null
}

set_prop() {
    local PROP_NAME="$1"
    local PROP_VALUE="$2"

    if [ -n "$PROP_VALUE" ]; then
        resetprop "$PROP_NAME" "$PROP_VALUE" 2>/dev/null
        return $?
    fi
    return 1
}

delete_prop() {
    local PROP_NAME="$1"
    resetprop --delete "$PROP_NAME" 2>/dev/null
}

verify_prop() {
    local PROP_NAME="$1"
    local EXPECTED="$2"
    local ACTUAL=$(get_prop "$PROP_NAME")

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        return 0
    else
        return 1
    fi
}


get_secure_setting() {
    local SETTING_NAME="$1"
    settings get secure "$SETTING_NAME" 2>/dev/null
}

set_secure_setting() {
    local SETTING_NAME="$1"
    local SETTING_VALUE="$2"
    settings put secure "$SETTING_NAME" "$SETTING_VALUE" 2>/dev/null
    return $?
}

get_screen_size() {
    wm size 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | tail -1
}

get_screen_density() {
    wm density 2>/dev/null | grep -oE '[0-9]+' | tail -1
}

set_screen_size() {
    local WIDTH="$1"
    local HEIGHT="$2"
    wm size "${WIDTH}x${HEIGHT}" 2>/dev/null
    return $?
}

set_screen_density() {
    local DENSITY="$1"
    wm density "$DENSITY" 2>/dev/null
    return $?
}

reset_screen() {
    wm size reset 2>/dev/null
    wm density reset 2>/dev/null
}


# Ask for yes/no confirmation
confirm() {
    local PROMPT="${1:-Are you sure?}"
    echo -n "${PROMPT} (yes/no): "
    read -r RESPONSE
    case "$RESPONSE" in
        yes|YES|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

press_enter() {
    echo ""
    echo -n "Press Enter to continue..."
    read -r
}

# Validate hex string
is_valid_hex() {
    local STR="$1"
    local LENGTH="$2"

    if [ -z "$STR" ]; then
        return 1
    fi

    if [ -n "$LENGTH" ] && [ ${#STR} -ne "$LENGTH" ]; then
        return 1
    fi

    echo "$STR" | grep -qE '^[0-9a-fA-F]+$'
    return $?
}

# Validate fingerprint format
is_valid_fingerprint() {
    local FP="$1"
    # Format: brand/product/device:version/build_id/incremental:type/tags
    echo "$FP" | grep -qE '^[a-z]+/[a-z0-9]+/[a-z0-9]+:[0-9]+/[A-Z0-9.]+/[0-9]+:(user|userdebug|eng)/(release-keys|dev-keys|test-keys)$'
    return $?
}

load_config() {
    local CONFIG_FILE="$1"
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
        return 0
    fi
    return 1
}

write_config_value() {
    local CONFIG_FILE="$1"
    local KEY="$2"
    local VALUE="$3"

    if grep -q "^${KEY}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${KEY}=.*|${KEY}=\"${VALUE}\"|" "$CONFIG_FILE"
    else
        echo "${KEY}=\"${VALUE}\"" >> "$CONFIG_FILE"
    fi
}

get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_date_compact() {
    date '+%Y%m%d_%H%M%S'
}
