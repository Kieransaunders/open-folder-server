# 📦 Open Folder Server - Installer

This directory contains the installation tools for the Open Folder Server macOS background service.

## Installation Options

### Option 1: Professional .pkg Installer (Recommended)
**For end users who want the best experience:**

1. Build the professional installer:
   ```bash
   ./build-distribution.sh
   ```

2. Share the generated `OpenFolderServer-1.0.0-installer.pkg` file

3. Users get:
   - Welcome screen with installation overview
   - License agreement
   - Professional installer interface
   - Automatic service setup

### Option 2: Simple .pkg Installer
**For end users who want a basic installation:**

1. Build the basic installer:
   ```bash
   ./build-pkg.sh
   ```

2. Share the generated `OpenFolderServer-1.0.0.pkg` file

3. Users can double-click and follow the installation wizard

### Option 3: Manual Shell Script
**For developers or advanced users:**

1. Run the installation script:
   ```bash
   ./install.sh
   ```

2. The script will:
   - Check for Node.js
   - Install to `~/Applications/OpenFolderServer`
   - Set up the background service
   - Start the service automatically

## What Gets Installed

- **Application**: `~/Applications/OpenFolderServer/`
- **Launch Agent**: `~/Library/LaunchAgents/com.folderopener.plist`
- **Service**: Runs automatically on login
- **Port**: Listens on `localhost:3000`

## Uninstallation

### Option 1: .pkg Uninstaller (Recommended)
**Professional uninstallation experience:**

1. Build the uninstaller:
   ```bash
   ./build-uninstaller-pkg.sh
   ```

2. Share the generated `OpenFolderServer-Uninstaller-1.0.0.pkg` file

3. Users can double-click to uninstall with:
   - Pre-install validation (checks if actually installed)
   - Confirmation screen showing what will be removed
   - Complete cleanup of all files and services
   - Professional installer interface

### Option 2: Manual Shell Script
**For developers or direct control:**

```bash
./uninstall.sh
```

This will:
- Stop the background service
- Remove all application files
- Remove the launch agent
- Clean up completely

## Files

### Build Scripts
- `build-distribution.sh` - Creates professional installer with welcome screen
- `build-pkg.sh` - Creates basic macOS .pkg installer
- `build-uninstaller-pkg.sh` - Creates professional .pkg uninstaller

### Manual Scripts
- `install.sh` - Manual installation script
- `uninstall.sh` - Manual removal script

### Documentation
- `README.md` - This documentation
- `validate-installer.sh` - Installer validation tools

## Requirements

- macOS 10.14 or later
- Node.js 16 or later
- Dropbox installed and synced

## Testing

After installation, test the service:
```bash
# Check service status
curl http://localhost:3000/health

# Test dynamic folder opening
curl "http://localhost:3000/open?path=Documents"

# Test legacy config-based folder opening
curl "http://localhost:3000/open?folder=ProjectX"
```

## Distribution

### Complete Distribution Package
For end users, distribute these files:

**Installation:**
- `OpenFolderServer-1.0.0-installer.pkg` (professional installer - recommended)
- `OpenFolderServer-1.0.0.pkg` (basic installer - alternative)

**Uninstallation:**
- `OpenFolderServer-Uninstaller-1.0.0.pkg` (professional uninstaller)

### Features
- No additional dependencies needed (Node.js required)
- Works with macOS Gatekeeper
- Professional installation/uninstallation experience
- Automatic service setup and cleanup
- Pre-install validation and error handling