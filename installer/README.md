# 📦 Open Folder Server - Installer

This directory contains the installation tools for the Open Folder Server macOS background service.

## Installation Options

### Option 1: .pkg Installer (Recommended)
**For end users who want a simple installation:**

1. Run the build script to create the installer:
   ```bash
   ./build-pkg.sh
   ```

2. Share the generated `OpenFolderServer-1.0.0.pkg` file

3. Users can double-click the .pkg file and follow the installation wizard

4. The service will start automatically after installation

### Option 2: Manual Shell Script
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

To remove the service:
```bash
./uninstall.sh
```

This will:
- Stop the background service
- Remove all application files
- Remove the launch agent
- Clean up completely

## Files

- `build-pkg.sh` - Creates macOS .pkg installer
- `install.sh` - Manual installation script
- `uninstall.sh` - Removal script
- `README.md` - This documentation

## Requirements

- macOS 10.14 or later
- Node.js 16 or later
- Dropbox installed and synced

## Testing

After installation, test the service:
```bash
# Check service status
curl http://localhost:3000/health

# Test folder opening (configure folders in config.json first)
curl "http://localhost:3000/open?folder=ProjectX"
```

## Distribution

The `.pkg` installer is ready for distribution:
- No additional dependencies needed
- Works with macOS Gatekeeper
- Standard installation experience
- Automatic service setup