#!/bin/bash
# DeviceSpoofLabs - Release Build Script
# Author: @yubunus
# Description: Creates a release-ready ZIP file for Magisk module installation

set -e  # Exit on error

# Color codes
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
    print_color "$BLUE" "  DeviceSpoofLabs - Release Builder"
    print_color "$BLUE" "========================================="
    echo ""
}

print_info() {
    print_color "$GREEN" "✓ $1"
}

print_warning() {
    print_color "$YELLOW" "⚠ $1"
}

print_error() {
    print_color "$RED" "✗ $1"
}

print_step() {
    print_color "$BLUE" "→ $1"
}

# Get script directory (works even if called from elsewhere)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

print_header

# Check if module.prop exists
if [ ! -f "module.prop" ]; then
    print_error "module.prop not found!"
    print_warning "Make sure you're running this script from the module root directory."
    exit 1
fi

# Read version from module.prop
VERSION=$(grep '^version=' module.prop | cut -d'=' -f2)
MODULE_ID=$(grep '^id=' module.prop | cut -d'=' -f2)

if [ -z "$VERSION" ] || [ -z "$MODULE_ID" ]; then
    print_error "Could not read version or module ID from module.prop!"
    exit 1
fi

print_info "Module ID: $MODULE_ID"
print_info "Version: $VERSION"
echo ""

# Output filename
OUTPUT_FILE="${MODULE_ID}-v${VERSION}.zip"

print_step "Preparing to create release: $OUTPUT_FILE"
echo ""

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    print_warning "File $OUTPUT_FILE already exists!"
    echo -n "Overwrite? (y/n): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_info "Build cancelled."
        exit 0
    fi
    rm -f "$OUTPUT_FILE"
fi

# Pre-flight checks
print_step "Running pre-flight checks..."

CHECKS_PASSED=true

# Check required files
REQUIRED_FILES=("module.prop" "post-fs-data.sh" "common/change_android_id.sh" "README.md")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_info "Found: $file"
    else
        print_error "Missing required file: $file"
        CHECKS_PASSED=false
    fi
done

# Check shell script permissions
if [ -x "post-fs-data.sh" ]; then
    print_info "post-fs-data.sh is executable"
else
    print_warning "post-fs-data.sh is not executable (will be fixed)"
    chmod +x post-fs-data.sh
fi

if [ -x "common/change_android_id.sh" ]; then
    print_info "common/change_android_id.sh is executable"
else
    print_warning "common/change_android_id.sh is not executable (will be fixed)"
    chmod +x common/change_android_id.sh
fi

# Check for shell script syntax errors (basic check)
print_step "Checking shell script syntax..."
if bash -n post-fs-data.sh 2>/dev/null; then
    print_info "post-fs-data.sh syntax OK"
else
    print_error "post-fs-data.sh has syntax errors!"
    CHECKS_PASSED=false
fi

if bash -n common/change_android_id.sh 2>/dev/null; then
    print_info "common/change_android_id.sh syntax OK"
else
    print_error "common/change_android_id.sh has syntax errors!"
    CHECKS_PASSED=false
fi

echo ""

if [ "$CHECKS_PASSED" = false ]; then
    print_error "Pre-flight checks failed! Please fix the errors above."
    exit 1
fi

# Create ZIP file
print_step "Creating ZIP file: $OUTPUT_FILE"
echo ""

# Files and directories to include
INCLUDE_ITEMS=(
    "module.prop"
    "post-fs-data.sh"
    "service.sh"
    "common"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
)

# Create temp directory for staging
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

print_step "Staging files in temporary directory..."

# Copy files to temp directory
for item in "${INCLUDE_ITEMS[@]}"; do
    if [ -e "$item" ]; then
        cp -r "$item" "$TEMP_DIR/"
        print_info "Staged: $item"
    else
        print_warning "Skipped (not found): $item"
    fi
done

# Create ZIP from temp directory
cd "$TEMP_DIR"
zip -r "$SCRIPT_DIR/$OUTPUT_FILE" . -x '*.git*' '*.DS_Store' '*.backup' '*.zip' 2>/dev/null

cd "$SCRIPT_DIR"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    print_info "Release ZIP created successfully!"
    print_info "File: $OUTPUT_FILE"
    print_info "Size: $FILE_SIZE"
    echo ""
else
    print_error "Failed to create ZIP file!"
    exit 1
fi

# Verify ZIP contents
print_step "Verifying ZIP contents..."
echo ""
unzip -l "$OUTPUT_FILE"
echo ""

# Calculate checksums
print_step "Calculating checksums..."
if command -v md5sum >/dev/null 2>&1; then
    MD5=$(md5sum "$OUTPUT_FILE" | cut -d' ' -f1)
    print_info "MD5: $MD5"
elif command -v md5 >/dev/null 2>&1; then
    MD5=$(md5 -q "$OUTPUT_FILE")
    print_info "MD5: $MD5"
fi

if command -v sha256sum >/dev/null 2>&1; then
    SHA256=$(sha256sum "$OUTPUT_FILE" | cut -d' ' -f1)
    print_info "SHA256: $SHA256"
elif command -v shasum >/dev/null 2>&1; then
    SHA256=$(shasum -a 256 "$OUTPUT_FILE" | cut -d' ' -f1)
    print_info "SHA256: $SHA256"
fi

echo ""

# Final instructions
print_header
print_color "$GREEN" "✓ Build Complete!"
echo ""
print_step "Next steps for releasing:"
echo ""
echo "1. Test the module:"
echo "   adb push $OUTPUT_FILE /sdcard/"
echo "   Install via Magisk Manager and test thoroughly"
echo ""
echo "2. Commit and tag the release (if using Git):"
echo "   git add ."
echo "   git commit -m \"Release v$VERSION\""
echo "   git tag v$VERSION"
echo "   git push origin main"
echo "   git push origin v$VERSION"
echo ""
echo "3. Create GitHub Release:"
echo "   - Go to: https://github.com/yubunus/DeviceSpoofLab-Magisk/releases/new"
echo "   - Tag: v$VERSION"
echo "   - Title: DeviceSpoofLabs v$VERSION"
echo "   - Attach: $OUTPUT_FILE"
echo "   - Description: Copy from CHANGELOG.md"
echo ""
echo "4. Update version for next release:"
echo "   - Edit module.prop (increment version and versionCode)"
echo "   - Update CHANGELOG.md"
echo ""
print_color "$YELLOW" "Remember to test the module before releasing!"
echo ""
