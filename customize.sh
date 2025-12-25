# Magisk Module Installation Script
# Sets proper permissions during module installation

SKIPUNZIP=0

ui_print() {
    echo "$1"
}

set_permissions() {
    ui_print "- Setting permissions for DeviceSpoofLabs"
    set_perm_recursive "$MODPATH/common" 0 0 0755 0755
    set_perm "$MODPATH/system/bin/devicespooflabs" 0 2000 0755

    ui_print "- Permissions set successfully"
}

ui_print " "
ui_print "********************************"
ui_print "   DeviceSpoofLabs v2.1"
ui_print "********************************"
ui_print " "
ui_print "- Installing module files..."
