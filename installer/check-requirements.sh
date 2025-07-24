#!/bin/bash

# Check requirements for Open Folder Server installer
# Run this script before installing to verify your system is ready

echo "🔍 Checking system requirements for Open Folder Server..."
echo ""

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

ALL_GOOD=true

# Check macOS version
echo "🍎 Checking macOS version..."
MACOS_VERSION=$(sw_vers -productVersion)
print_success "macOS version: $MACOS_VERSION"

# Check if Node.js is installed
echo ""
echo "🟢 Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js is installed: $NODE_VERSION"
else
    print_error "Node.js is not installed!"
    echo "  Please install Node.js from https://nodejs.org/"
    echo "  Download the LTS version for best compatibility"
    ALL_GOOD=false
fi

# Check if npm is available
echo ""
echo "📦 Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "npm is available: $NPM_VERSION"
else
    print_error "npm is not available!"
    echo "  This usually comes with Node.js installation"
    ALL_GOOD=false
fi

# Check if port 3000 is available
echo ""
echo "🌐 Checking port 3000..."
if lsof -i :3000 &> /dev/null; then
    print_warning "Port 3000 is already in use"
    echo "  The installer will try to stop any existing service"
else
    print_success "Port 3000 is available"
fi

# Check if Dropbox folder exists
echo ""
echo "📁 Checking Dropbox folder..."
if [ -d "$HOME/Dropbox" ]; then
    print_success "Dropbox folder found at ~/Dropbox"
else
    print_warning "Dropbox folder not found at ~/Dropbox"
    echo "  The app will still work, but may not find your Dropbox folders"
fi

# Check for existing installation
echo ""
echo "🔍 Checking for existing installation..."
if [ -d "$HOME/Applications/OpenFolderServer" ]; then
    print_warning "Previous installation found at ~/Applications/OpenFolderServer"
    echo "  The installer will update the existing installation"
else
    print_success "No previous installation found"
fi

# Summary
echo ""
echo "📋 Summary:"
echo "============"

if [ "$ALL_GOOD" = true ]; then
    print_success "System meets all requirements!"
    echo ""
    echo "🚀 You can now run the installer:"
    echo "  - Double-click OpenFolderServer-1.0.0-installer.pkg"
    echo "  - Follow the installation wizard"
    echo ""
else
    print_error "System requirements not met"
    echo ""
    echo "📋 To fix:"
    echo "1. Install Node.js from https://nodejs.org/"
    echo "2. Choose the LTS (Long Term Support) version"
    echo "3. Restart Terminal or your computer"
    echo "4. Run this check again: ./check-requirements.sh"
    echo "5. When all requirements are met, run the installer"
    echo ""
fi

echo "✅ Requirements check complete!"