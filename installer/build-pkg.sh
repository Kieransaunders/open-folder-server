#!/bin/bash

# Build macOS .pkg installer for Open Folder Server
# This script creates a proper macOS installer package

set -e  # Exit on any error

echo "📦 Building macOS installer package..."

# Configuration
PROJECT_NAME="OpenFolderServer"
VERSION="1.0.0"
IDENTIFIER="com.folderopener.installer"
BUILD_DIR="./build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
PKG_FILE="$PROJECT_NAME-$VERSION.pkg"

# Clean up previous build
rm -rf "$BUILD_DIR"
rm -f "$PKG_FILE"

# Create build directories
mkdir -p "$PAYLOAD_DIR"
mkdir -p "$SCRIPTS_DIR"

echo "✅ Created build directories"

# Create payload structure
INSTALL_ROOT="$PAYLOAD_DIR/Applications/OpenFolderServer"
mkdir -p "$INSTALL_ROOT"

# Copy application files to payload
cp ../server.js "$INSTALL_ROOT/"
cp ../config.json "$INSTALL_ROOT/"
cp ../start.command "$INSTALL_ROOT/"
cp ../package.json "$INSTALL_ROOT/"
cp ../package-lock.json "$INSTALL_ROOT/"
cp ../README_installation.md "$INSTALL_ROOT/"
cp ../plan.md "$INSTALL_ROOT/"

# Make start.command executable
chmod +x "$INSTALL_ROOT/start.command"

echo "✅ Created payload structure"

# Create postinstall script
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash

# Post-installation script for Open Folder Server

USER_HOME="$HOME"
INSTALL_DIR="$USER_HOME/Applications/OpenFolderServer"
LAUNCH_AGENT_DIR="$USER_HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"
SERVICE_NAME="com.folderopener"

echo "🚀 Setting up Open Folder Server..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Install npm dependencies
cd "$INSTALL_DIR"
npm install --production

# Create plist file with correct paths
cat > "$INSTALL_DIR/$PLIST_FILE" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/start.command</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/logs/launchd.out</string>
    
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/logs/launchd.err</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
PLIST_EOF

# Create launch agents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENT_DIR"

# Copy plist file to launch agents
cp "$INSTALL_DIR/$PLIST_FILE" "$LAUNCH_AGENT_DIR/"

# Stop existing service if running
launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true

# Load the service
launchctl load "$LAUNCH_AGENT_DIR/$PLIST_FILE"

echo "✅ Open Folder Server installed successfully!"
echo "The service is now running and will start automatically on login."
echo "Test URL: http://localhost:3000/health"

exit 0
EOF

# Make postinstall script executable
chmod +x "$SCRIPTS_DIR/postinstall"

echo "✅ Created post-install script"

# Create preinstall script
cat > "$SCRIPTS_DIR/preinstall" << 'EOF'
#!/bin/bash

# Pre-installation script for Open Folder Server

USER_HOME="$HOME"
LAUNCH_AGENT_DIR="$USER_HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"
SERVICE_NAME="com.folderopener"

echo "🔧 Preparing for installation..."

# Stop existing service if running
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo "Stopping existing service..."
    launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
fi

# Remove existing plist file
if [ -f "$LAUNCH_AGENT_DIR/$PLIST_FILE" ]; then
    rm "$LAUNCH_AGENT_DIR/$PLIST_FILE"
fi

exit 0
EOF

# Make preinstall script executable
chmod +x "$SCRIPTS_DIR/preinstall"

echo "✅ Created pre-install script"

# Build the package
echo "📦 Building installer package..."

pkgbuild \
    --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    "$PKG_FILE"

echo "✅ Package built successfully: $PKG_FILE"

# Clean up build directory
rm -rf "$BUILD_DIR"

echo ""
echo "🎉 Installer package created: $PKG_FILE"
echo ""
echo "To install:"
echo "  1. Double-click the .pkg file"
echo "  2. Follow the installation wizard"
echo "  3. The service will start automatically"
echo ""
echo "To distribute:"
echo "  - Share the .pkg file with users"
echo "  - No additional setup required"