#!/bin/bash

# Build macOS distribution package for Open Folder Server
# This creates a complete installer with welcome/license screens

set -e  # Exit on any error

echo "📦 Building macOS distribution package..."

# Configuration
PROJECT_NAME="OpenFolderServer"
VERSION="1.0.0"
IDENTIFIER="com.folderopener.installer"
DISTRIBUTION_IDENTIFIER="com.folderopener.distribution"
BUILD_DIR="./build"
RESOURCES_DIR="$BUILD_DIR/resources"
PKG_FILE="$PROJECT_NAME-$VERSION.pkg"
DISTRIBUTION_FILE="$PROJECT_NAME-$VERSION-installer.pkg"

# Clean up previous build
rm -rf "$BUILD_DIR"
rm -f "$PKG_FILE" "$DISTRIBUTION_FILE"

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$RESOURCES_DIR"

echo "✅ Created build directories"

# Build the component package first (or use existing one)
if [ ! -f "$PKG_FILE" ]; then
    ./build-pkg.sh
fi

# Ensure build directory exists and copy the component package
mkdir -p "$BUILD_DIR"
mkdir -p "$RESOURCES_DIR"
if [ -f "$PKG_FILE" ]; then
    cp "$PKG_FILE" "$BUILD_DIR/"
else
    echo "❌ Component package not found: $PKG_FILE"
    exit 1
fi

echo "✅ Component package ready"

# Create distribution.xml for productbuild
cat > "$BUILD_DIR/distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>Open Folder Server</title>
    <organization>com.folderopener</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="false" rootVolumeOnly="true" />
    
    <welcome file="welcome.html" mime-type="text/html" />
    <license file="license.txt" mime-type="text/plain" />
    
    <pkg-ref id="$IDENTIFIER"/>
    <options customize="never" require-scripts="false"/>
    
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">$PKG_FILE</pkg-ref>
</installer-gui-script>
EOF

echo "✅ Created distribution.xml"

# Create welcome screen
cat > "$RESOURCES_DIR/welcome.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            font-size: 13px;
            line-height: 1.4;
            color: #333333;
            background-color: #ffffff;
            margin: 0;
            padding: 20px;
        }
        h1 {
            color: #007AFF;
            font-size: 24px;
            margin-bottom: 15px;
        }
        h2 {
            color: #333333;
            font-size: 16px;
            margin-top: 20px;
            margin-bottom: 10px;
        }
        .highlight {
            background-color: #f0f8ff;
            color: #333333;
            padding: 10px;
            border-radius: 6px;
            margin: 10px 0;
        }
        .warning {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #333333;
            padding: 10px;
            border-radius: 6px;
            margin: 10px 0;
        }
        ul {
            margin: 10px 0;
            padding-left: 20px;
            color: #333333;
        }
        li {
            margin: 5px 0;
            color: #333333;
        }
        p {
            color: #333333;
        }
        strong {
            color: #333333;
        }
    </style>
</head>
<body>
    <h1>🚀 Welcome to Open Folder Server</h1>
    
    <p>This installer will set up Open Folder Server on your Mac, enabling you to open local Dropbox folders directly in Finder by clicking web links.</p>
    
    <h2>📋 What will be installed:</h2>
    <ul>
        <li>Open Folder Server application in ~/Applications/OpenFolderServer/</li>
        <li>Background service that starts automatically on login</li>
        <li>Configuration file for folder mappings</li>
        <li>Launch agent for automatic startup</li>
    </ul>
    
    <div class="highlight">
        <strong>💡 How it works:</strong><br>
        After installation, the server will run silently in the background on port 3000. 
        You can open folders by visiting URLs like: <code>http://localhost:3000/open?folder=ProjectX</code>
    </div>
    
    <div class="warning">
        <strong>⚠️ IMPORTANT - Install Node.js First:</strong><br>
        <strong>This installer requires Node.js to be installed BEFORE running.</strong><br>
        <br>
        1. Download Node.js from <a href="https://nodejs.org/">nodejs.org</a> (LTS version recommended)<br>
        2. Install Node.js and restart your Terminal/computer<br>
        3. Then run this installer<br>
        <br>
        Other requirements:<br>
        • macOS 10.12 or later<br>
        • Dropbox folder at ~/Dropbox/
    </div>
    
    <h2>🔧 After Installation:</h2>
    <ul>
        <li>Edit ~/Applications/OpenFolderServer/config.json to configure your folder mappings</li>
        <li>Test the service at: <a href="http://localhost:3000/health">http://localhost:3000/health</a></li>
        <li>Check logs at: ~/Applications/OpenFolderServer/logs/</li>
    </ul>
    
    <p>Click <strong>Continue</strong> to proceed with the installation.</p>
</body>
</html>
EOF

echo "✅ Created welcome screen"

# Create license file
cat > "$RESOURCES_DIR/license.txt" << 'EOF'
Open Folder Server - License Agreement

Copyright (c) 2024 Open Folder Server

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

This installer will:
1. Install Open Folder Server to ~/Applications/OpenFolderServer/
2. Install npm dependencies
3. Configure a background service that starts automatically
4. Set up folder opening capabilities for Dropbox folders

The service runs locally on port 3000 and only accepts connections from localhost.
No external network access is required or used.
EOF

echo "✅ Created license file"

# Build the distribution package
echo "📦 Building distribution package..."

productbuild \
    --distribution "$BUILD_DIR/distribution.xml" \
    --resources "$RESOURCES_DIR" \
    --package-path "$BUILD_DIR" \
    "$DISTRIBUTION_FILE"

echo "✅ Distribution package built successfully: $DISTRIBUTION_FILE"

# Optional: Code signing and notarization
if [ -n "$DEVELOPER_ID_INSTALLER" ]; then
    echo "🔐 Code signing distribution package..."
    productsign --sign "$DEVELOPER_ID_INSTALLER" "$DISTRIBUTION_FILE" "${DISTRIBUTION_FILE%.pkg}-signed.pkg"
    if [ $? -eq 0 ]; then
        mv "${DISTRIBUTION_FILE%.pkg}-signed.pkg" "$DISTRIBUTION_FILE"
        echo "✅ Distribution package signed successfully"
        
        # Optional: Notarization
        if [ -n "$APPLE_ID" ] && [ -n "$APP_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
            echo "📋 Submitting distribution package for notarization..."
            xcrun notarytool submit "$DISTRIBUTION_FILE" \
                --apple-id "$APPLE_ID" \
                --password "$APP_PASSWORD" \
                --team-id "$TEAM_ID" \
                --wait
            
            if [ $? -eq 0 ]; then
                echo "✅ Distribution package notarized successfully"
                xcrun stapler staple "$DISTRIBUTION_FILE"
                echo "✅ Notarization ticket stapled to distribution package"
            else
                echo "⚠️  Distribution package notarization failed or timed out"
            fi
        else
            echo "⚠️  Skipping notarization (set APPLE_ID, APP_PASSWORD, TEAM_ID to enable)"
        fi
    else
        echo "⚠️  Distribution package code signing failed"
    fi
else
    echo "⚠️  Skipping code signing (set DEVELOPER_ID_INSTALLER to enable)"
fi

# Clean up intermediate files
rm -rf "$BUILD_DIR"

echo ""
echo "🎉 Professional installer package created: $DISTRIBUTION_FILE"
echo ""
echo "Features:"
echo "  ✅ Welcome screen with installation overview"
echo "  ✅ License agreement"
echo "  ✅ Professional installer interface"
echo "  ✅ Automatic background service setup"
echo "  ✅ Comprehensive error handling and logging"
echo ""
echo "To install:"
echo "  1. Double-click the $DISTRIBUTION_FILE file"
echo "  2. Follow the installation wizard"
echo "  3. The service will start automatically"
echo ""
echo "To distribute:"
echo "  - Share the $DISTRIBUTION_FILE file with users"
echo "  - No additional setup required"
echo "  - Users need Node.js installed first"