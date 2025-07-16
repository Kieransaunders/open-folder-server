#!/bin/bash

# Open Folder Server Uninstaller
# This script removes the folder opening service from macOS

set -e  # Exit on any error

echo "🗑️  Uninstalling Open Folder Server..."

# Configuration
INSTALL_DIR="$HOME/Applications/OpenFolderServer"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"
SERVICE_NAME="com.folderopener"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Confirmation prompt
echo "This will completely remove Open Folder Server from your system."
echo "Installation directory: $INSTALL_DIR"
echo "Launch agent: $LAUNCH_AGENT_DIR/$PLIST_FILE"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Stop and unload the service
if launchctl list | grep -q "$SERVICE_NAME"; then
    print_status "Stopping service..."
    launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
    print_status "Service stopped"
else
    print_warning "Service was not running"
fi

# Remove launch agent plist file
if [ -f "$LAUNCH_AGENT_DIR/$PLIST_FILE" ]; then
    print_status "Removing launch agent..."
    rm "$LAUNCH_AGENT_DIR/$PLIST_FILE"
    print_status "Launch agent removed"
else
    print_warning "Launch agent plist file not found"
fi

# Remove application directory
if [ -d "$INSTALL_DIR" ]; then
    print_status "Removing application files..."
    rm -rf "$INSTALL_DIR"
    print_status "Application files removed"
else
    print_warning "Installation directory not found"
fi

# Check if port 3000 is still in use
if lsof -i :3000 >/dev/null 2>&1; then
    print_warning "Port 3000 is still in use by another process"
    print_warning "You may need to manually stop any remaining processes"
fi

echo ""
echo "🎉 Uninstallation complete!"
echo ""
echo "Open Folder Server has been completely removed from your system."
echo "The service will no longer start automatically on login."
echo ""
echo "If you had any custom folder mappings, they have been removed."
echo "You can reinstall the service at any time using the installer."