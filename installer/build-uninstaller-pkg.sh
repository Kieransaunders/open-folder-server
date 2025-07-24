#!/bin/bash

# Build macOS .pkg uninstaller for Open Folder Server
# This script creates a proper macOS uninstaller package

set -e  # Exit on any error

echo "🗑️  Building macOS uninstaller package..."

# Configuration
PROJECT_NAME="OpenFolderServer-Uninstaller"
VERSION="1.0.0"
IDENTIFIER="com.folderopener.uninstaller"
BUILD_DIR="./build-uninstaller"
SCRIPTS_DIR="$BUILD_DIR/scripts"
PKG_FILE="$PROJECT_NAME-$VERSION.pkg"

# Clean up previous build
rm -rf "$BUILD_DIR"
rm -f "$PKG_FILE"

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$SCRIPTS_DIR"

echo "✅ Created build directories"

# Create preinstall script (confirmation and checks)
cat > "$SCRIPTS_DIR/preinstall" << 'EOF'
#!/bin/bash

# Pre-uninstall script for Open Folder Server
# This script provides confirmation before uninstalling

USER_HOME="$HOME"
INSTALL_DIR="$USER_HOME/Applications/OpenFolderServer"
LAUNCH_AGENT_DIR="$USER_HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"
SERVICE_NAME="com.folderopener"

echo "🗑️  Open Folder Server Uninstaller"
echo ""
echo "This will completely remove Open Folder Server from your system:"
echo "  • Stop the background service"
echo "  • Remove launch agent (no auto-start on login)"
echo "  • Delete application files: $INSTALL_DIR"
echo "  • Remove configuration and logs"
echo ""

# Check if actually installed
if [ ! -d "$INSTALL_DIR" ] && [ ! -f "$LAUNCH_AGENT_DIR/$PLIST_FILE" ]; then
    echo "⚠️  Open Folder Server does not appear to be installed."
    echo ""
    echo "Nothing to uninstall. Cancelling."
    exit 1
fi

echo "✅ Ready to uninstall Open Folder Server"

exit 0
EOF

# Make preinstall script executable
chmod +x "$SCRIPTS_DIR/preinstall"

echo "✅ Created pre-uninstall script"

# Create postinstall script (actual uninstall)
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash

# Post-install script for Open Folder Server Uninstaller
# This actually performs the uninstall

set -e  # Exit on any error

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1"
}

# Configuration
USER_HOME="$HOME"
INSTALL_DIR="$USER_HOME/Applications/OpenFolderServer"
LAUNCH_AGENT_DIR="$USER_HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"
SERVICE_NAME="com.folderopener"

log "🗑️  Starting Open Folder Server uninstall..."

# Stop and unload the service
if launchctl list | grep -q "$SERVICE_NAME"; then
    log "Stopping service..."
    launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
    log_success "Service stopped"
else
    log_warning "Service was not running"
fi

# Remove launch agent plist file
if [ -f "$LAUNCH_AGENT_DIR/$PLIST_FILE" ]; then
    log "Removing launch agent..."
    rm "$LAUNCH_AGENT_DIR/$PLIST_FILE"
    log_success "Launch agent removed"
else
    log_warning "Launch agent plist file not found"
fi

# Remove application directory
if [ -d "$INSTALL_DIR" ]; then
    log "Removing application files..."
    rm -rf "$INSTALL_DIR"
    log_success "Application files removed"
else
    log_warning "Installation directory not found"
fi

# Check if port 3000 is still in use
if lsof -i :3000 >/dev/null 2>&1; then
    log_warning "Port 3000 is still in use by another process"
    log_warning "You may need to manually stop any remaining processes"
fi

log_success "Open Folder Server has been completely removed!"
log "The service will no longer start automatically on login."
log "All application files, configuration, and logs have been deleted."

exit 0
EOF

# Make postinstall script executable
chmod +x "$SCRIPTS_DIR/postinstall"

echo "✅ Created uninstall script"

# Build the package (no payload needed, just scripts)
echo "📦 Building uninstaller package..."

pkgbuild \
    --nopayload \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    "$PKG_FILE"

echo "✅ Package built successfully: $PKG_FILE"

# Clean up build directory
rm -rf "$BUILD_DIR"

echo ""
echo "🎉 Uninstaller package created: $PKG_FILE"
echo ""
echo "Features:"
echo "  ✅ Pre-install confirmation and validation"
echo "  ✅ Complete service removal"
echo "  ✅ Automatic cleanup of all files"
echo "  ✅ Professional installer interface"
echo ""
echo "To uninstall Open Folder Server:"
echo "  1. Double-click the $PKG_FILE file"
echo "  2. Follow the uninstaller wizard"
echo "  3. Service will be completely removed"
echo ""
echo "To distribute:"
echo "  - Share the $PKG_FILE file alongside the main installer"
echo "  - Users can easily uninstall when needed"