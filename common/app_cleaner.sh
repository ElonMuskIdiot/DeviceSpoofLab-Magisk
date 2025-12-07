# Description: Clear app data and cache for third-party apps

SCRIPT_DIR="${0%/*}"
. "${SCRIPT_DIR}/utils.sh"

# System Apps to Also Clear (Browser/WebView)
# if it breaks your apps or android services, remove these lines
SYSTEM_APPS_TO_CLEAR="
com.android.chrome
com.google.android.webview
com.android.webview
com.google.android.gms
com.google.android.gsf
"

list_third_party_apps() {
    pm list packages -3 2>/dev/null | sed 's/package://' | sort
}


count_third_party_apps() {
    list_third_party_apps | wc -l | tr -d ' '
}

clear_app_data() {
    local PACKAGE="$1"

    if [ -z "$PACKAGE" ]; then
        print_error "No package specified"
        return 1
    fi

    if ! pm list packages | grep -q "package:${PACKAGE}$"; then
        print_warning "Package not found: $PACKAGE"
        return 1
    fi

    print_step "Clearing: $PACKAGE"
    pm clear "$PACKAGE" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "Cleared app data: $PACKAGE"
        return 0
    else
        log_error "Failed to clear: $PACKAGE"
        return 1
    fi
}

clear_all_third_party_apps() {
    print_header "Clear All Third-Party Apps"

    local APPS=$(list_third_party_apps)
    local COUNT=$(echo "$APPS" | wc -l | tr -d ' ')

    if [ -z "$APPS" ] || [ "$COUNT" -eq 0 ]; then
        print_info "No third-party apps found"
        return 0
    fi

    print_info "Found $COUNT third-party apps"
    echo ""

    local SUCCESS=0
    local FAILED=0

    echo "$APPS" | while read -r PACKAGE; do
        if [ -n "$PACKAGE" ]; then
            if clear_app_data "$PACKAGE"; then
                SUCCESS=$((SUCCESS + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        fi
    done

    echo ""
    print_success "Cleared $SUCCESS apps"
    if [ $FAILED -gt 0 ]; then
        print_warning "Failed to clear $FAILED apps"
    fi

    return 0
}

clear_system_browser_apps() {
    print_header "Clear System Browser/WebView Apps"

    local CLEARED=0

    for PACKAGE in $SYSTEM_APPS_TO_CLEAR; do
        # Check if package exists
        if pm list packages | grep -q "package:${PACKAGE}$"; then
            print_step "Clearing: $PACKAGE"
            pm clear "$PACKAGE" 2>/dev/null
            if [ $? -eq 0 ]; then
                CLEARED=$((CLEARED + 1))
                print_success "Cleared: $PACKAGE"
            else
                print_warning "Could not clear: $PACKAGE (may require more permissions)"
            fi
        else
            print_info "Not installed: $PACKAGE"
        fi
    done

    echo ""
    print_info "Cleared $CLEARED system apps"
    return 0
}

clear_all_apps() {
    print_header "Clear ALL App Data"

    print_warning "This will clear data for:"
    echo "  - All third-party (user-installed) apps"
    echo "  - Chrome browser"
    echo "  - WebView"
    echo "  - Google Play Services"
    echo "  - Google Services Framework"
    echo ""
    print_warning "You will be logged out of ALL apps!"
    print_warning "App settings and saved data will be LOST!"
    echo ""

    if ! confirm "Are you absolutely sure?"; then
        print_info "Operation cancelled"
        return 0
    fi

    echo ""
    log_info "User confirmed clearing all app data"

    print_step "Clearing third-party apps..."
    local APPS=$(list_third_party_apps)

    echo "$APPS" | while read -r PACKAGE; do
        if [ -n "$PACKAGE" ]; then
            clear_app_data "$PACKAGE"
        fi
    done

    echo ""

    print_step "Clearing system apps..."
    clear_system_browser_apps

    echo ""
    print_success "All app data cleared!"
    log_success "All app data cleared"

    return 0
}

show_app_cleaner_menu() {
    while true; do
        print_header "App Data / Cache Tools"

        local APP_COUNT=$(count_third_party_apps)
        print_info "Third-party apps installed: $APP_COUNT"
        echo ""

        echo "  [1] Clear ALL third-party app data"
        echo "  [2] Clear Chrome/WebView/GMS only"
        echo "  [3] Clear EVERYTHING (third-party + system)"
        echo "  [4] List installed third-party apps"
        echo "  [0] Back"
        echo ""
        echo -n "Select an option: "
        read -r CHOICE

        case "$CHOICE" in
            1)
                echo ""
                print_warning "This will clear data for ALL $APP_COUNT third-party apps!"
                print_warning "You will be logged out of all apps!"
                echo ""
                if confirm "Continue?"; then
                    clear_all_third_party_apps
                else
                    print_info "Cancelled"
                fi
                press_enter
                ;;
            2)
                echo ""
                clear_system_browser_apps
                press_enter
                ;;
            3)
                echo ""
                clear_all_apps
                press_enter
                ;;
            4)
                echo ""
                print_header "Installed Third-Party Apps"
                list_third_party_apps | while read -r PKG; do
                    echo "  $PKG"
                done
                echo ""
                print_info "Total: $APP_COUNT apps"
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
