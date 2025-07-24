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

# Create payload structure - files will be placed in /tmp during install then moved by postinstall
INSTALL_ROOT="$PAYLOAD_DIR/tmp/OpenFolderServer-Install"
mkdir -p "$INSTALL_ROOT"

# Copy application files to payload
cp ../server.js "$INSTALL_ROOT/"
cp ../config.json "$INSTALL_ROOT/"
cp ../start.command "$INSTALL_ROOT/"
cp ../package.json "$INSTALL_ROOT/"
cp ../package-lock.json "$INSTALL_ROOT/"
cp ../com.folderopener.plist "$INSTALL_ROOT/"
cp ../README_installation.md "$INSTALL_ROOT/" 2>/dev/null || echo "README_installation.md not found, skipping"
cp ../CLAUDE.md "$INSTALL_ROOT/" 2>/dev/null || echo "CLAUDE.md not found, skipping"

# Make start.command executable
chmod +x "$INSTALL_ROOT/start.command"

echo "✅ Created payload structure"

# Create postinstall script
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash

# Post-installation script for Open Folder Server
# This script runs after the package payload is installed

set -e  # Exit on any error

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    if [ -d "$INSTALL_DIR/logs" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_DIR/logs/install.log"
    fi
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    if [ -d "$INSTALL_DIR/logs" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$INSTALL_DIR/logs/install.log"
    fi
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
    if [ -d "$INSTALL_DIR/logs" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$INSTALL_DIR/logs/install.log"
    fi
}

# Configuration
USER_HOME="$HOME"
INSTALL_DIR="$USER_HOME/Applications/OpenFolderServer"
LAUNCH_AGENT_DIR="$USER_HOME/Library/LaunchAgents"
PLIST_FILE="com.folderopener.plist"
SERVICE_NAME="com.folderopener"
TEMP_DIR="/tmp/OpenFolderServer-Install"

log "🚀 Starting Open Folder Server post-installation setup..."

# Create installation directory
log "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/logs"

# Move files from temporary location to final installation directory
log "Moving files to installation directory..."
if [ -d "$TEMP_DIR" ]; then
    cp -r "$TEMP_DIR"/* "$INSTALL_DIR/"
    rm -rf "$TEMP_DIR"
    log_success "Files moved to $INSTALL_DIR"
else
    log_error "Temporary installation files not found at $TEMP_DIR"
    exit 1
fi

# Verify critical files exist
log "Verifying installation files..."
if [ ! -f "$INSTALL_DIR/server.js" ]; then
    log_error "server.js is missing from $INSTALL_DIR"
    exit 1
fi

if [ ! -f "$INSTALL_DIR/package.json" ]; then
    log_error "package.json is missing from $INSTALL_DIR"
    exit 1
fi

if [ ! -f "$INSTALL_DIR/config.json" ]; then
    log_error "config.json is missing from $INSTALL_DIR"
    exit 1
fi

if [ ! -f "$INSTALL_DIR/start.command" ]; then
    log_error "start.command is missing from $INSTALL_DIR"
    exit 1
fi

log_success "All required files are present"

# Check if Node.js is installed (check common locations)
log "Checking for Node.js..."
NODE_PATH=""
for path in /usr/local/bin/node /opt/homebrew/bin/node /usr/bin/node $(which node 2>/dev/null); do
    if [ -x "$path" ]; then
        NODE_PATH="$path"
        break
    fi
done

if [ -z "$NODE_PATH" ]; then
    log_error "Node.js is not installed!"
    log_error "Please install Node.js from https://nodejs.org/ and run the installer again"
    exit 1
fi

NODE_VERSION=$($NODE_PATH --version)
log_success "Node.js found: $NODE_VERSION at $NODE_PATH"

# Install npm dependencies
log "Installing npm dependencies..."
cd "$INSTALL_DIR"
NPM_PATH=""
NODE_DIR=$(dirname "$NODE_PATH")
for path in "$NODE_DIR/npm" /usr/local/bin/npm /opt/homebrew/bin/npm /usr/bin/npm; do
    if [ -x "$path" ]; then
        NPM_PATH="$path"
        break
    fi
done

if [ -z "$NPM_PATH" ]; then
    log_error "npm not found!"
    exit 1
fi

# Set PATH to include Node.js directory for npm
export PATH="$(dirname "$NODE_PATH"):$PATH"
if ! "$NPM_PATH" install --omit=dev --silent; then
    log_error "Failed to install npm dependencies"
    exit 1
fi
log_success "npm dependencies installed successfully"

# Make start.command executable
log "Setting file permissions..."
chmod +x "$INSTALL_DIR/start.command"
log_success "File permissions set"

# Create launch agents directory if it doesn't exist
log "Creating launch agents directory..."
mkdir -p "$LAUNCH_AGENT_DIR"
log_success "Launch agents directory ready"

# Update plist file with correct user home path and node path
log "Configuring launch agent..."
NODE_DIR=$(dirname "$NODE_PATH")
sed -e "s|USER_HOME|$USER_HOME|g" \
    -e "s|/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin|$NODE_DIR:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin|g" \
    "$INSTALL_DIR/$PLIST_FILE" > "$LAUNCH_AGENT_DIR/$PLIST_FILE"
log_success "Launch agent configured with node path: $NODE_PATH"

# Stop existing service if running
log "Stopping any existing service..."
if launchctl list | grep -q "$SERVICE_NAME"; then
    launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
    log_success "Stopped existing service"
else
    log "No existing service found"
fi

# Load the service
log "Starting service..."
if launchctl load "$LAUNCH_AGENT_DIR/$PLIST_FILE"; then
    log_success "Service loaded successfully"
else
    log_error "Failed to load service"
    exit 1
fi

# Wait for service to start
log "Waiting for service to start..."
sleep 3

# Test the service
log "Testing service..."
if curl -s -f "http://localhost:3000/health" > /dev/null; then
    log_success "Service is running and responding"
    
    # Prompt user for root directory selection
    log "Prompting user for root directory selection..."
    
    # Use AppleScript to show a user-friendly dialog asking if they want to set up root directory
    SETUP_ROOT=$(osascript << 'APPLESCRIPT'
tell application "System Events"
    activate
    set response to display dialog "Open Folder Server has been installed successfully!" & return & return & "Would you like to select your preferred root directory (e.g., Dropbox, iCloud Drive, etc.) for folder opening?" & return & return & "This is optional - you can skip this and configure it later." buttons {"Skip", "Select Root Directory"} default button "Select Root Directory" with icon note
    if button returned of response is "Select Root Directory" then
        return "yes"
    else
        return "no"
    end if
end tell
APPLESCRIPT
)
    
    if [ "$SETUP_ROOT" = "yes" ]; then
        log "User chose to select root directory"
        
        # Show folder picker dialog
        ROOT_PATH=$(osascript << 'APPLESCRIPT'
tell application "Finder"
    activate
    try
        set chosenFolder to choose folder with prompt "Select your preferred root directory:" & return & return & "This could be:" & return & "• Your Dropbox folder" & return & "• iCloud Drive" & return & "• A custom folder" & return & return & "Folders will be opened relative to this location."
        return POSIX path of chosenFolder
    on error
        return ""
    end try
end tell
APPLESCRIPT
)
        
        if [ -n "$ROOT_PATH" ] && [ "$ROOT_PATH" != "" ]; then
            ROOT_PATH=$(echo "$ROOT_PATH" | tr -d '\n' | tr -d '\r')
            log_success "User selected root directory: $ROOT_PATH"
            
            # Update the config file to include the user's root directory
            cd "$INSTALL_DIR"
            
            # Read current config, add userRoots, and save back
            node -e "
                const fs = require('fs');
                const path = require('path');
                
                try {
                    let config = {};
                    if (fs.existsSync('config.json')) {
                        config = JSON.parse(fs.readFileSync('config.json', 'utf8'));
                    }
                    
                    if (!config.userRoots) {
                        config.userRoots = [];
                    }
                    
                    const rootPath = '$ROOT_PATH';
                    if (!config.userRoots.includes(rootPath)) {
                        config.userRoots.unshift(rootPath);
                    }
                    
                    fs.writeFileSync('config.json', JSON.stringify(config, null, 2));
                    console.log('Root directory saved to configuration');
                    process.exit(0);
                } catch (error) {
                    console.error('Error updating config:', error.message);
                    process.exit(1);
                }
            "
            
            if [ $? -eq 0 ]; then
                log_success "Root directory saved to configuration: $ROOT_PATH"
                
                # Restart the service to reload the updated configuration
                log "Restarting service to reload configuration..."
                launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
                sleep 1
                launchctl load "$LAUNCH_AGENT_DIR/$PLIST_FILE"
                sleep 2
                log_success "Service restarted with updated configuration"
                
                # Show confirmation dialog with test URL
                DEMO_RESPONSE=$(osascript << APPLESCRIPT
tell application "System Events"
    activate
    set response to display dialog "Setup Complete!" & return & return & "✅ Open Folder Server is running" & return & "✅ Root directory configured: $ROOT_PATH" & return & return & "Test it now by clicking 'Open Test Page' to see how it works!" & return & return & "The browser will open showing your root directory, demonstrating how folders will be opened from web links." buttons {"Maybe Later", "Open Test Page"} default button "Open Test Page" with icon note
    if button returned of response is "Open Test Page" then
        return "yes"
    else
        return "no"
    end if
end tell
APPLESCRIPT
)
                
                if [ "$DEMO_RESPONSE" = "yes" ]; then
                    log "User chose to open test page - opening root directory and example folder..."
                    # Open the root directory to demonstrate functionality
                    log "Opening root directory: $ROOT_PATH"
                    open "$ROOT_PATH" 2>>logs/install.log
                    sleep 1
                    # Also open a simple test URL that shows the service is working
                    log "Opening example URL: http://localhost:3000/open?path=MyFolder"
                    open "http://localhost:3000/open?path=MyFolder" 2>>logs/install.log
                    
                    # Show explanation dialog after opening browser
                    osascript << 'APPLESCRIPT'
tell application "System Events"
    activate
    display dialog "Demo Complete!" & return & return & "✅ Your root directory opened in Finder" & return & "✅ Example folder URL was tested" & return & return & "This demonstrates how the system works:" & return & "• Web links can now open folders in your configured root directory" & return & "• The service opened a folder or showed fallback behavior" & return & return & "Example usage:" & return & "http://localhost:3000/open?path=MyFolder" buttons {"Got it!"} default button "Got it!" with icon note
end tell
APPLESCRIPT
                else
                    log "User chose not to open test page"
                fi
            else
                log_error "Failed to save root directory to configuration"
            fi
        else
            log "User cancelled folder selection"
        fi
    else
        log "User skipped root directory setup"
    fi
    
    log_success "Open Folder Server installation completed successfully!"
    log "The service is now running and will start automatically on login."
    log "Configuration: $INSTALL_DIR/config.json"
    log "Logs: $INSTALL_DIR/logs/"
    log "Test URL: http://localhost:3000/open?path=MyFolder"
    
    # Show final success dialog if no root setup was done
    if [ "$SETUP_ROOT" != "yes" ]; then
        TEST_RESPONSE=$(osascript << 'APPLESCRIPT'
set response to display dialog "Open Folder Server installed successfully!" & return & return & "The service is now running and will start automatically on login." & return & return & "Want to see it in action? Click 'Test Service' to open the status page!" buttons {"Maybe Later", "Test Service"} default button "Test Service" with icon note
if button returned of response is "Test Service" then
    return "yes"
else
    return "no"
end if
APPLESCRIPT
)
        
        if [ "$TEST_RESPONSE" = "yes" ]; then
            log "User chose to test service - opening example folder..."
            log "Opening example URL: http://localhost:3000/open?path=MyFolder"
            open "http://localhost:3000/open?path=MyFolder" 2>>logs/install.log
            
            # Show explanation dialog
            osascript << 'APPLESCRIPT'
display dialog "Service Test Complete!" & return & return & "✅ The service opened a folder (or showed fallback if MyFolder doesn't exist)" & return & return & "To use the service:" & return & "• Use URLs like: http://localhost:3000/open?path=YourFolder" & return & "• Optionally configure a root directory at: http://localhost:3000/browse-root" & return & return & "The service will open folders relative to your Dropbox or configured root directory." buttons {"Got it!"} default button "Got it!" with icon note
APPLESCRIPT
        else
            log "User chose not to test service"
        fi
    fi
else
    log_error "Service failed to start or is not responding"
    log_error "Check logs at $INSTALL_DIR/logs/ for more details"
    exit 1
fi

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

# Check if Node.js is installed (check common locations)
NODE_PATH=""
for path in /usr/local/bin/node /opt/homebrew/bin/node /usr/bin/node $(which node 2>/dev/null); do
    if [ -x "$path" ]; then
        NODE_PATH="$path"
        break
    fi
done

if [ -z "$NODE_PATH" ]; then
    echo ""
    echo "❌ ERROR: Node.js is not installed!"
    echo ""
    echo "Please install Node.js before running this installer:"
    echo "1. Visit https://nodejs.org/"
    echo "2. Download and install the LTS version"
    echo "3. Restart your Terminal or computer"
    echo "4. Run this installer again"
    echo ""
    exit 1
fi

echo "✅ Node.js found: $($NODE_PATH --version) at $NODE_PATH"

# Check if npm is available (usually in same directory as node)
NPM_PATH=""
NODE_DIR=$(dirname "$NODE_PATH")
for path in "$NODE_DIR/npm" /usr/local/bin/npm /opt/homebrew/bin/npm /usr/bin/npm $(which npm 2>/dev/null); do
    if [ -x "$path" ]; then
        NPM_PATH="$path"
        break
    fi
done

if [ -z "$NPM_PATH" ]; then
    echo "❌ ERROR: npm is not available!"
    echo "Please reinstall Node.js from https://nodejs.org/"
    exit 1
fi

echo "✅ npm found: $($NPM_PATH --version) at $NPM_PATH"

# Stop existing service if running
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo "Stopping existing service..."
    launchctl unload "$LAUNCH_AGENT_DIR/$PLIST_FILE" 2>/dev/null || true
fi

# Remove existing plist file
if [ -f "$LAUNCH_AGENT_DIR/$PLIST_FILE" ]; then
    rm "$LAUNCH_AGENT_DIR/$PLIST_FILE"
fi

echo "✅ Ready for installation"

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

# Optional: Code signing and notarization
if [ -n "$DEVELOPER_ID_INSTALLER" ]; then
    echo "🔐 Code signing package..."
    productsign --sign "$DEVELOPER_ID_INSTALLER" "$PKG_FILE" "${PKG_FILE%.pkg}-signed.pkg"
    if [ $? -eq 0 ]; then
        mv "${PKG_FILE%.pkg}-signed.pkg" "$PKG_FILE"
        echo "✅ Package signed successfully"
        
        # Optional: Notarization
        if [ -n "$APPLE_ID" ] && [ -n "$APP_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
            echo "📋 Submitting for notarization..."
            xcrun notarytool submit "$PKG_FILE" \
                --apple-id "$APPLE_ID" \
                --password "$APP_PASSWORD" \
                --team-id "$TEAM_ID" \
                --wait
            
            if [ $? -eq 0 ]; then
                echo "✅ Package notarized successfully"
                xcrun stapler staple "$PKG_FILE"
                echo "✅ Notarization ticket stapled"
            else
                echo "⚠️  Notarization failed or timed out"
            fi
        else
            echo "⚠️  Skipping notarization (set APPLE_ID, APP_PASSWORD, TEAM_ID to enable)"
        fi
    else
        echo "⚠️  Code signing failed"
    fi
else
    echo "⚠️  Skipping code signing (set DEVELOPER_ID_INSTALLER to enable)"
fi

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