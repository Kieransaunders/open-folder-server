#!/bin/bash

# Setup script for code signing and notarization
# This helps configure the environment for signing macOS packages

echo "🔐 macOS Code Signing Setup"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script only works on macOS"
    exit 1
fi

echo "Checking for Developer ID certificates..."

# List available Developer ID certificates
INSTALLER_CERTS=$(security find-identity -v -p basic | grep "Developer ID Installer" | cut -d '"' -f 2)

if [ -z "$INSTALLER_CERTS" ]; then
    echo ""
    echo "❌ No Developer ID Installer certificates found"
    echo ""
    echo "To get started with code signing, you need:"
    echo ""
    echo "1. 📱 Apple Developer Account ($99/year)"
    echo "   Sign up at: https://developer.apple.com/"
    echo ""
    echo "2. 🔑 Developer ID Installer Certificate"
    echo "   - Log into developer.apple.com"
    echo "   - Go to Certificates, Identifiers & Profiles"
    echo "   - Create a new 'Developer ID Installer' certificate"
    echo "   - Download and install it in Keychain Access"
    echo ""
    echo "3. 🔒 App-Specific Password for notarization"
    echo "   - Go to appleid.apple.com"
    echo "   - Sign In and Security > App-Specific Passwords"
    echo "   - Generate a password for 'notarization'"
    echo ""
    echo "After setup, run this script again!"
    exit 1
fi

echo ""
echo "✅ Found Developer ID Installer certificates:"
echo "$INSTALLER_CERTS"
echo ""

# Prompt user to select certificate
echo "Select a certificate to use:"
IFS=$'\n' read -rd '' -a cert_array <<<"$INSTALLER_CERTS"

if [ ${#cert_array[@]} -eq 1 ]; then
    SELECTED_CERT="${cert_array[0]}"
    echo "Using: $SELECTED_CERT"
else
    for i in "${!cert_array[@]}"; do
        echo "$((i+1)). ${cert_array[i]}"
    done
    
    read -p "Enter selection (1-${#cert_array[@]}): " selection
    SELECTED_CERT="${cert_array[$((selection-1))]}"
fi

echo ""
echo "📝 Environment Setup"
echo ""
echo "Add these to your shell profile (~/.zshrc or ~/.bash_profile):"
echo ""
echo "# macOS Code Signing"
echo "export DEVELOPER_ID_INSTALLER=\"$SELECTED_CERT\""
echo ""

# Prompt for Apple ID details
read -p "Enter your Apple ID email (for notarization): " apple_id
read -p "Enter your Team ID (10-character string from developer.apple.com): " team_id

echo "export APPLE_ID=\"$apple_id\""
echo "export TEAM_ID=\"$team_id\""
echo ""
echo "⚠️  For APP_PASSWORD, create an app-specific password at appleid.apple.com"
echo "Then add: export APP_PASSWORD=\"your-app-specific-password\""
echo ""

# Option to write to a file
read -p "Save these to a file? (y/n): " save_file
if [[ $save_file =~ ^[Yy]$ ]]; then
    cat > "./codesigning-env.sh" << EOF
#!/bin/bash
# Code signing environment variables
# Source this file: source ./codesigning-env.sh

export DEVELOPER_ID_INSTALLER="$SELECTED_CERT"
export APPLE_ID="$apple_id"
export TEAM_ID="$team_id"
# export APP_PASSWORD="your-app-specific-password"  # Add this manually

echo "✅ Code signing environment loaded"
EOF
    
    echo "✅ Saved to codesigning-env.sh"
    echo ""
    echo "Usage:"
    echo "  1. Edit codesigning-env.sh and add your APP_PASSWORD"
    echo "  2. Run: source ./codesigning-env.sh"
    echo "  3. Build with: ./build-distribution.sh"
fi

echo ""
echo "🎉 Setup complete! Your packages will now be signed and notarized."