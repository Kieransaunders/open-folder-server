#!/bin/bash

# Validate Open Folder Server installer package
# This script tests the installer in a controlled environment

set -e

echo "🔍 Validating Open Folder Server installer..."

# Configuration
PROJECT_NAME="OpenFolderServer"
VERSION="1.0.0"
DISTRIBUTION_FILE="$PROJECT_NAME-$VERSION-installer.pkg"
TEST_DIR="./test-install"
INSTALL_DIR="$HOME/Applications/OpenFolderServer"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if installer exists
if [ ! -f "$DISTRIBUTION_FILE" ]; then
    print_error "Installer package not found: $DISTRIBUTION_FILE"
    echo "Run ./build-distribution.sh first to create the installer"
    exit 1
fi

print_success "Installer package found: $DISTRIBUTION_FILE"

# Check package contents
echo ""
echo "📋 Package Contents:"
echo "===================="
pkgutil --payload-files "$DISTRIBUTION_FILE" | head -20
echo ""

# Test package installation (dry run)
echo "🧪 Testing package installation..."
echo "=================================="

# Create test directory
mkdir -p "$TEST_DIR"

# Check if Node.js is available
if command -v node &> /dev/null; then
    print_success "Node.js is available: $(node --version)"
else
    print_warning "Node.js not found - installation will fail"
fi

# Check if npm is available
if command -v npm &> /dev/null; then
    print_success "npm is available: $(npm --version)"
else
    print_warning "npm not found - installation will fail"
fi

# Check if Dropbox folder exists
if [ -d "$HOME/Dropbox" ]; then
    print_success "Dropbox folder found at ~/Dropbox"
else
    print_warning "Dropbox folder not found - app will work but folders may not open"
fi

# Check if port 3000 is available
if lsof -i :3000 &> /dev/null; then
    print_warning "Port 3000 is already in use"
else
    print_success "Port 3000 is available"
fi

# Validate package signature (if signed)
echo ""
echo "🔐 Package Signature:"
echo "===================="
if pkgutil --check-signature "$DISTRIBUTION_FILE" 2>/dev/null; then
    print_success "Package signature is valid"
else
    print_warning "Package is not signed (normal for development)"
fi

# Check package metadata
echo ""
echo "📊 Package Metadata:"
echo "===================="
pkgutil --pkg-info-plist "$DISTRIBUTION_FILE" | grep -E "(identifier|version|install-location)"

# Test postinstall script syntax
echo ""
echo "🔧 Script Validation:"
echo "===================="

# Extract and check postinstall script
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Extract the package
pkgutil --expand "$OLDPWD/$DISTRIBUTION_FILE" extracted_pkg

# Find the postinstall script
POSTINSTALL_SCRIPT=$(find extracted_pkg -name "postinstall" -type f)

if [ -f "$POSTINSTALL_SCRIPT" ]; then
    print_success "Postinstall script found"
    
    # Check script syntax
    if bash -n "$POSTINSTALL_SCRIPT"; then
        print_success "Postinstall script syntax is valid"
    else
        print_error "Postinstall script has syntax errors"
        exit 1
    fi
    
    # Show script size and permissions
    echo "Script size: $(wc -l < "$POSTINSTALL_SCRIPT") lines"
    echo "Script permissions: $(ls -l "$POSTINSTALL_SCRIPT" | awk '{print $1}')"
else
    print_error "Postinstall script not found in package"
    exit 1
fi

# Clean up
cd "$OLDPWD"
rm -rf "$TEMP_DIR"

# Check for existing installation
echo ""
echo "🔍 Existing Installation Check:"
echo "==============================="

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Previous installation found at $INSTALL_DIR"
    echo "  Files: $(ls -la "$INSTALL_DIR" | wc -l) items"
    if [ -f "$INSTALL_DIR/server.js" ]; then
        print_warning "  server.js exists"
    fi
    if [ -f "$INSTALL_DIR/package.json" ]; then
        print_warning "  package.json exists"
    fi
else
    print_success "No previous installation found"
fi

if [ -f "$LAUNCH_AGENT_DIR/$PLIST_FILE" ]; then
    print_warning "Launch agent plist already exists"
    if launchctl list | grep -q "com.folderopener"; then
        print_warning "  Service is currently running"
    fi
else
    print_success "No existing launch agent found"
fi

echo ""
echo "📝 Installation Readiness Summary:"
echo "=================================="

if command -v node &> /dev/null && command -v npm &> /dev/null; then
    print_success "System requirements met"
else
    print_error "System requirements not met - Node.js and npm required"
fi

if [ -f "$DISTRIBUTION_FILE" ]; then
    print_success "Installer package is ready"
else
    print_error "Installer package is missing"
fi

echo ""
echo "🚀 To install:"
echo "  sudo installer -pkg '$DISTRIBUTION_FILE' -target /"
echo ""
echo "🧹 To uninstall (if needed):"
echo "  ./uninstall.sh"
echo ""
echo "✅ Validation complete!"