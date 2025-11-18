#!/system/bin/sh
# DeviceSpoofLabs - ANDROID_ID Changer (Manual Script)
# Author: @yubunus
# Description: Manually change ANDROID_ID with backup functionality
#
# ⚠️  WARNING: Changing ANDROID_ID can cause:
# - Apps to log you out (re-authentication required)
# - Google Play Services to reset (may need to re-add Google account)
# - DRM licenses to be invalidated
# - In-app purchases to be lost
# - Banking/financial apps to flag as suspicious activity
# - Device registrations to fail
#
# USE THIS SCRIPT AT YOUR OWN RISK!
# This is for TESTING and DEVELOPMENT purposes only.
#

# Module directory for backup storage
MODULE_DIR="/data/adb/modules/devicespooflab"
BACKUP_FILE="${MODULE_DIR}/android_id.backup"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with color
print_color() {
    echo -e "${1}${2}${NC}"
}

print_header() {
    echo ""
    print_color "$BLUE" "========================================="
    print_color "$BLUE" "  DeviceSpoofLabs - ANDROID_ID Changer"
    print_color "$BLUE" "========================================="
    echo ""
}

print_warning() {
    print_color "$RED" "⚠️  WARNING: $1"
}

print_info() {
    print_color "$GREEN" "ℹ️  $1"
}

print_step() {
    print_color "$YELLOW" "→ $1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_warning "This script must be run as root!"
        print_info "Run: su -c 'sh $0' or use 'su' first"
        exit 1
    fi
}

# Create module directory if it doesn't exist
ensure_module_dir() {
    if [ ! -d "$MODULE_DIR" ]; then
        print_step "Creating module directory: $MODULE_DIR"
        mkdir -p "$MODULE_DIR"
        chmod 755 "$MODULE_DIR"
    fi
}

# Read current ANDROID_ID
get_current_android_id() {
    CURRENT_ID=$(settings get secure android_id)
    if [ -z "$CURRENT_ID" ] || [ "$CURRENT_ID" = "null" ]; then
        print_warning "Could not read current ANDROID_ID!"
        exit 1
    fi
    echo "$CURRENT_ID"
}

# Generate random 16-character hexadecimal string
generate_random_android_id() {
    # Use /dev/urandom for cryptographically secure random data
    # Read 8 bytes (64 bits) and convert to 16 hex characters
    NEW_ID=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n' | cut -c1-16)
    echo "$NEW_ID"
}

# Backup current ANDROID_ID
backup_android_id() {
    local CURRENT_ID=$1
    local TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

    print_step "Backing up current ANDROID_ID..."

    # Save to backup file with timestamp
    echo "# ANDROID_ID Backup - Created: $(date '+%Y-%m-%d %H:%M:%S')" > "$BACKUP_FILE"
    echo "# Original ANDROID_ID: $CURRENT_ID" >> "$BACKUP_FILE"
    echo "$CURRENT_ID" >> "$BACKUP_FILE"

    chmod 600 "$BACKUP_FILE"

    print_info "Backup saved to: $BACKUP_FILE"
}

# Change ANDROID_ID
change_android_id() {
    local NEW_ID=$1

    print_step "Applying new ANDROID_ID: $NEW_ID"

    # Set new ANDROID_ID using settings command
    settings put secure android_id "$NEW_ID"

    # Verify the change
    sleep 1
    VERIFY_ID=$(settings get secure android_id)

    if [ "$VERIFY_ID" = "$NEW_ID" ]; then
        print_info "ANDROID_ID successfully changed!"
        return 0
    else
        print_warning "Failed to change ANDROID_ID!"
        print_warning "Expected: $NEW_ID"
        print_warning "Got: $VERIFY_ID"
        return 1
    fi
}

# Restore ANDROID_ID from backup
restore_android_id() {
    if [ ! -f "$BACKUP_FILE" ]; then
        print_warning "No backup file found at: $BACKUP_FILE"
        exit 1
    fi

    print_step "Reading backup file..."

    # Read the last line (the actual ID, skip comments)
    BACKUP_ID=$(grep -v '^#' "$BACKUP_FILE" | tail -n1 | tr -d '[:space:]')

    if [ -z "$BACKUP_ID" ]; then
        print_warning "Backup file is empty or invalid!"
        exit 1
    fi

    print_info "Backup ANDROID_ID found: $BACKUP_ID"

    print_step "Restoring ANDROID_ID from backup..."
    settings put secure android_id "$BACKUP_ID"

    # Verify restoration
    sleep 1
    VERIFY_ID=$(settings get secure android_id)

    if [ "$VERIFY_ID" = "$BACKUP_ID" ]; then
        print_info "ANDROID_ID successfully restored!"
        print_info "Backup file preserved at: $BACKUP_FILE"
    else
        print_warning "Failed to restore ANDROID_ID!"
    fi
}

# Main menu
show_menu() {
    print_header

    CURRENT_ID=$(get_current_android_id)
    print_info "Current ANDROID_ID: $CURRENT_ID"
    echo ""

    echo "Select an option:"
    echo "  1) Change ANDROID_ID to new random value"
    echo "  2) Restore ANDROID_ID from backup"
    echo "  3) View current ANDROID_ID and backup"
    echo "  4) Exit"
    echo ""
    echo -n "Enter choice [1-4]: "
    read -r CHOICE
}

# View info
show_info() {
    print_header

    CURRENT_ID=$(get_current_android_id)
    print_info "Current ANDROID_ID: $CURRENT_ID"

    if [ -f "$BACKUP_FILE" ]; then
        echo ""
        print_info "Backup file exists: $BACKUP_FILE"
        print_step "Backup contents:"
        cat "$BACKUP_FILE"
    else
        echo ""
        print_warning "No backup file found"
    fi
}

# Interactive mode
interactive_mode() {
    while true; do
        show_menu

        case $CHOICE in
            1)
                print_header
                print_warning "You are about to change your ANDROID_ID!"
                echo ""
                print_warning "This may cause:"
                echo "  • App logouts and re-authentication"
                echo "  • Google Play Services reset"
                echo "  • DRM licenses invalidation"
                echo "  • Banking apps security alerts"
                echo ""
                echo -n "Continue? (yes/no): "
                read -r CONFIRM

                if [ "$CONFIRM" = "yes" ]; then
                    CURRENT_ID=$(get_current_android_id)
                    NEW_ID=$(generate_random_android_id)

                    backup_android_id "$CURRENT_ID"

                    if change_android_id "$NEW_ID"; then
                        echo ""
                        print_info "Old ANDROID_ID: $CURRENT_ID"
                        print_info "New ANDROID_ID: $NEW_ID"
                        echo ""
                        print_warning "REBOOT YOUR DEVICE for changes to take full effect!"
                        print_info "To revert, run this script again and choose option 2"
                    fi
                else
                    print_info "Operation cancelled"
                fi

                echo ""
                echo -n "Press Enter to continue..."
                read -r
                ;;

            2)
                print_header
                restore_android_id
                echo ""
                print_warning "REBOOT YOUR DEVICE for changes to take full effect!"
                echo ""
                echo -n "Press Enter to continue..."
                read -r
                ;;

            3)
                show_info
                echo ""
                echo -n "Press Enter to continue..."
                read -r
                ;;

            4)
                print_info "Exiting..."
                exit 0
                ;;

            *)
                print_warning "Invalid choice!"
                sleep 2
                ;;
        esac
    done
}

# Main execution
main() {
    check_root
    ensure_module_dir

    # If no arguments, run interactive mode
    if [ $# -eq 0 ]; then
        interactive_mode
    else
        # Command-line mode
        case "$1" in
            change)
                CURRENT_ID=$(get_current_android_id)
                NEW_ID=$(generate_random_android_id)
                backup_android_id "$CURRENT_ID"
                change_android_id "$NEW_ID"
                print_warning "REBOOT YOUR DEVICE!"
                ;;
            restore)
                restore_android_id
                print_warning "REBOOT YOUR DEVICE!"
                ;;
            view)
                show_info
                ;;
            *)
                echo "Usage: $0 [change|restore|view]"
                echo "  change  - Change ANDROID_ID to new random value"
                echo "  restore - Restore ANDROID_ID from backup"
                echo "  view    - View current ANDROID_ID and backup"
                echo "  (no args) - Interactive menu mode"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
