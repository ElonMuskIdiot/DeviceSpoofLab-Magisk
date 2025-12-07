# Description: Interactive CLI for managing device spoofing personas
# Usage: devicespooflabs (after module installation)

VERSION="2.0"

SCRIPT_DIR="${0%/*}"
if [ -L "$0" ]; then
    REAL_PATH=$(readlink -f "$0" 2>/dev/null || readlink "$0")
    SCRIPT_DIR="${REAL_PATH%/*}"
fi

if [ "$SCRIPT_DIR" = "/system/bin" ]; then
    SCRIPT_DIR="/data/adb/modules/devicespooflab/common"
fi

. "${SCRIPT_DIR}/utils.sh"
. "${SCRIPT_DIR}/persona_manager.sh"
. "${SCRIPT_DIR}/app_cleaner.sh"

# Main Menu
show_main_menu() {
    clear 2>/dev/null || true
    echo ""
    print_color "$MAGENTA" "  ____             _           ____                    __ _          _         "
    print_color "$MAGENTA" " |  _ \\  _____   _(_) ___ ___ / ___| _ __   ___   ___ / _| |    __ _| |__  ___ "
    print_color "$MAGENTA" " | | | |/ _ \\ \\ / / |/ __/ _ \\\\___ \\| '_ \\ / _ \\ / _ \\ |_| |   / _\` | '_ \\/ __|"
    print_color "$MAGENTA" " | |_| |  __/\\ V /| | (_|  __/ ___) | |_) | (_) | (_) |  _| |__| (_| | |_) \\__ \\"
    print_color "$MAGENTA" " |____/ \\___| \\_/ |_|\\___\\___|____/| .__/ \\___/ \\___/|_| |_____\\__,_|_.__/|___/"
    print_color "$MAGENTA" "                                   |_|                              v${VERSION}"
    print_color "$CYAN" "                                                                 by @yubunus"
    echo ""
    print_separator
    echo ""

    if has_current_persona; then
        . "$CURRENT_PERSONA"
        print_info "Active: ${PERSONA_NAME:-Pixel 7 Pro}"
        print_info "Model: $(get_prop ro.product.model)"
    else
        print_warning "No persona active"
    fi
    echo ""

    print_separator
    echo ""
    echo "  [1] Persona Management"
    echo "  [2] App Data / Cache Tools"
    echo "  [0] Exit"
    echo ""
    print_separator
    echo ""
    echo -n "Select an option: "
}

# Persona Management Menu
show_persona_menu() {
    while true; do
        print_header "Persona Management"

        echo "  [1] View current persona"
        echo "  [2] Generate NEW persona (reroll everything)"
        echo "  [3] Restore default persona (from backup)"
        echo "  [0] Back"
        echo ""
        echo -n "Select an option: "
        read -r CHOICE

        case "$CHOICE" in
            1)
                echo ""
                view_current_persona
                press_enter
                ;;
            2)
                echo ""
                show_generate_persona_menu
                ;;
            3)
                echo ""
                restore_original
                press_enter
                ;;
            0)
                return 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Generate Persona Sub-Menu
show_generate_persona_menu() {
    print_header "Generate NEW Persona"

    print_warning "This will:"
    echo "  - Create a completely new spoofed device identity"
    echo "  - Change device props (model/fingerprint/etc.)"
    echo "  - Change spoofed ANDROID_ID"
    echo "  - Requires REBOOT to fully apply"
    echo ""
    print_separator
    echo ""
    echo "  [1] Continue and generate new identifiers only"
    echo "  [2] Continue and generate new identifiers + reset ALL apps"
    echo "  [0] Cancel"
    echo ""
    echo -n "Select an option: "
    read -r CHOICE

    case "$CHOICE" in
        1)
            echo ""
            generate_and_apply_persona 0
            ;;
        2)
            echo ""
            generate_and_apply_persona 1
            ;;
        0)
            print_info "Cancelled"
            return 0
            ;;
        *)
            print_error "Invalid option"
            sleep 1
            ;;
    esac
}

# Generate and Apply Persona
generate_and_apply_persona() {
    local CLEAR_APPS="${1:-0}"

    print_header "Generating New Persona"

    if ! has_backup; then
        print_step "First run - backing up original device..."
        backup_original_device
        echo ""
    fi

    if ! generate_new_persona; then
        print_error "Failed to generate persona"
        press_enter
        return 1
    fi

    echo ""

    print_step "Applying ANDROID_ID..."
    apply_android_id

    echo ""

    print_step "Applying screen settings..."
    apply_screen_settings

    echo ""

    if [ "$CLEAR_APPS" -eq 1 ]; then
        echo ""
        print_step "Clearing all app data..."
        clear_all_apps
    fi

    echo ""
    print_separator
    echo ""
    print_success "New persona generated and partially applied!"
    echo ""
    print_warning "IMPORTANT: You MUST REBOOT for all changes to take effect!"
    print_info "Device props will be applied on next boot."
    echo ""
    print_separator

    press_enter
    return 0
}

# Startup Checks
startup_checks() {
    check_root
    check_magisk
    check_module_installed
    ensure_directories
    log_info "DeviceSpoofLabs CLI v${VERSION} started"
}



main() {
    startup_checks

    while true; do
        show_main_menu
        read -r CHOICE

        case "$CHOICE" in
            1)
                show_persona_menu
                ;;
            2)
                show_app_cleaner_menu
                ;;
            0)
                echo ""
                print_info "Exiting DeviceSpoofLabs..."
                log_info "DeviceSpoofLabs CLI exited"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

main "$@"
