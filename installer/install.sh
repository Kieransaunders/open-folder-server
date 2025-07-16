#!/bin/bash

# Open Folder Server Installer
# This script installs the folder opening service on macOS

set -e  # Exit on any error

echo "🚀 Installing Open Folder Server..."

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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed!"
    print_warning "Please install Node.js from https://nodejs.org/ and run this installer again."
    exit 1
fi

print_status "Node.js found: $(node --version)"

# Stop existing service if running
if launchctl list | grep -q "$SERVICE_NAME"; then
    print_status "Stopping existing service..."
    launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
fi

# Create installation directory
print_status "Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy application files
print_status "Copying application files..."
cp -r ../server.js "$INSTALL_DIR/"
cp -r ../config.json "$INSTALL_DIR/"
cp -r ../start.command "$INSTALL_DIR/"
cp -r ../package.json "$INSTALL_DIR/"
cp -r ../package-lock.json "$INSTALL_DIR/"

# Make start.command executable
chmod +x "$INSTALL_DIR/start.command"

# Install npm dependencies
print_status "Installing dependencies..."
cd "$INSTALL_DIR"
npm install --production

# Update plist file with correct paths
print_status "Configuring launch agent..."
cat > "$INSTALL_DIR/$PLIST_FILE" << EOF
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
EOF

# Create launch agents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENT_DIR"

# Copy plist file to launch agents
print_status "Installing launch agent..."
cp "$INSTALL_DIR/$PLIST_FILE" "$LAUNCH_AGENT_DIR/"

# Load the service
print_status "Starting service..."
launchctl load "$LAUNCH_AGENT_DIR/$PLIST_FILE"

# Wait a moment for service to start
sleep 3

# Test the service
print_status "Testing service..."
if curl -s "http://localhost:3000/health" > /dev/null; then
    print_status "Service is running successfully!"
    echo ""
    echo "🎉 Installation complete!"
    echo ""
    echo "The Open Folder Server is now running in the background."
    echo "It will start automatically when you log in."
    echo ""
    echo "📂 Configuration file: $INSTALL_DIR/config.json"
    echo "📄 Logs: $INSTALL_DIR/logs/"
    echo "🌐 Test URL: http://localhost:3000/health"
    echo ""
    echo "To customize folder mappings, edit the config.json file and restart the service:"
    echo "  launchctl unload $LAUNCH_AGENT_DIR/$PLIST_FILE"
    echo "  launchctl load $LAUNCH_AGENT_DIR/$PLIST_FILE"
else
    print_error "Service failed to start. Check logs at $INSTALL_DIR/logs/"
    exit 1
fi