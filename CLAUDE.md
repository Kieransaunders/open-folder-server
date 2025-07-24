# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Node.js background service called "open-folder-server" that enables users to open local Dropbox folders in macOS Finder by clicking web links. The server runs silently in the background and starts automatically on login using macOS launchd.

## Development Commands
- **Start server**: `node server.js` or `./start.command`
- **Install dependencies**: `npm install`
- **Lint/typecheck**: No linting configured (pure JavaScript project)
- **Test health**: `curl http://localhost:3000/health`
- **Test folder opening**: `curl "http://localhost:3000/open?folder=ProjectX"`
- **Test dynamic path**: `curl "http://localhost:3000/open?path=My%20Projects/Client%20Work"`

### Build Commands
- **Build basic installer**: `cd installer && ./build-pkg.sh`
- **Build professional installer**: `cd installer && ./build-distribution.sh`
- **Build uninstaller**: `cd installer && ./build-uninstaller-pkg.sh`
- **Validate installer**: `cd installer && ./validate-installer.sh`

### Installation Commands
- **Manual install**: `cd installer && ./install.sh`
- **Manual uninstall**: `cd installer && ./uninstall.sh`

### Service Management
- **Check service status**: `launchctl list | grep folderopener`
- **View logs**: `cat ~/Applications/OpenFolderServer/logs/server.log`
- **Stop service**: `launchctl unload ~/Library/LaunchAgents/com.folderopener.plist`
- **Start service**: `launchctl load ~/Library/LaunchAgents/com.folderopener.plist`

## Project Structure
- **server.js**: Main Express server handling folder opening requests (port 3000)
- **config.json**: Maps folder keys to Dropbox paths (optional for dynamic mode)
- **start.command**: Shell script to launch server with logging
- **com.folderopener.plist**: macOS launchd configuration for background service
- **logs/**: Directory for server logs and PID files (created automatically)
- **installer/**: Complete installation system with multiple .pkg builders and scripts
  - **build-pkg.sh**: Creates basic macOS installer package
  - **build-distribution.sh**: Creates professional installer with welcome screen
  - **build-uninstaller-pkg.sh**: Creates professional uninstaller package
  - **install.sh**: Manual installation script with validation
  - **uninstall.sh**: Manual removal script

## Key Features
- **HTTP endpoints**: `/open?folder=<key>`, `/open?path=<folder_path>`, and `/health`
- **Dual operation modes**: Config-based mapping (legacy) and dynamic path mode
- **Universal Dropbox detection**: Automatically finds Dropbox in common locations
- **Folder mapping**: Configurable via config.json (optional)
- **Background service**: Runs automatically on macOS login via launchd
- **Logging**: Comprehensive logging to logs/server.log
- **Error handling**: Graceful handling of invalid folders and paths
- **Path security**: Built-in protection against path traversal attacks

## Installation Process
### Production Install (Recommended)
**Professional Installer:**
1. Build installer: `cd installer && ./build-distribution.sh`
2. Share `OpenFolderServer-1.0.0-installer.pkg` with users
3. Users get welcome screen, license, and professional installation experience
4. Service starts automatically on installation

**Basic Installer:**
1. Build installer: `cd installer && ./build-pkg.sh`
2. Share `OpenFolderServer-1.0.0.pkg` with users
3. Users double-click installer and follow basic wizard
4. Service starts automatically on installation

### Development Install
1. Manual install: `cd installer && ./install.sh`
2. Service installed to `~/Applications/OpenFolderServer/`
3. Launch agent configured for auto-start
4. Test with `curl http://localhost:3000/health`

### Uninstallation
**Professional Uninstaller:**
1. Build uninstaller: `cd installer && ./build-uninstaller-pkg.sh`
2. Share `OpenFolderServer-Uninstaller-1.0.0.pkg` with users
3. Users get validation, confirmation, and complete cleanup

## API Usage
### Dynamic Path Mode (Recommended)
```bash
curl "http://localhost:3000/open?path=My%20Projects/Client%20Work"
curl "http://localhost:3000/open?path=Documents/Contracts/2024"
```

### Config Mode (Legacy)
Requires folder mappings in config.json:
```bash
curl "http://localhost:3000/open?folder=ProjectX"
```

### Health Check
```bash
curl "http://localhost:3000/health"
```

### Configure user root directories
```bash
curl "http://localhost:3000/browse-root"
```

## Smart Fallback System (v1.0.1+)

### Folder Not Found Behavior
When a requested folder doesn't exist, the server now:

1. **Checks folder existence** before attempting to open
2. **Falls back to available root directories** in priority order:
   - User-configured roots (from `/browse-root` endpoint)
   - Dropbox root directory
   - iCloud Drive
   - User home directory
   - Desktop
   - Documents
3. **Returns detailed JSON response** with both requested and actual opened paths

### Configuration
- **User roots**: Stored in `config.json` as `userRoots` array
- **Priority**: User-configured roots take precedence over defaults
- **Persistence**: Selected directories are saved automatically

### API Response Format
```json
{
  "success": true,
  "message": "Folder not found. Opened Dropbox Root instead.",
  "requested": "NonExistentFolder",
  "requestedPath": "/Users/user/Dropbox/NonExistentFolder", 
  "opened": "Dropbox Root",
  "openedPath": "/Users/user/Dropbox",
  "fallback": true
}
```

## Architecture Notes
- **Single-file Express server**: Main logic contained in `server.js` with no additional modules
- **Dropbox detection**: Automatically searches common Dropbox locations: `~/Library/CloudStorage/Dropbox`, `~/Dropbox`, and business variants
- **Dual operation modes**: Config-based folder mapping (legacy) vs. dynamic path resolution
- **Smart fallback system**: Falls back to user roots → Dropbox → iCloud → home directories when folder not found
- **macOS launchd integration**: Background service managed via `com.folderopener.plist` in `~/Library/LaunchAgents/`
- **Path resolution**: All paths relative to detected Dropbox root for security
- **Error handling**: Returns structured JSON responses with debugging info
- **Logging**: Timestamped console output and file logging to `~/Applications/OpenFolderServer/logs/`

## Security Notes
- Server only listens on localhost (127.0.0.1:3000)
- Path traversal protection (blocks `../` and absolute paths)
- All paths restricted to Dropbox directory tree
- Uses macOS `open` command to launch Finder safely
- No authentication required for local access

## Installer Issues & Fixes (v1.0.0)

### Issue 1: macOS Gatekeeper Security Block
**Problem**: Modern macOS (Catalina+) blocks unsigned packages with error:
```
"rejected source=no usable signature"
```

**Root Cause**: Gatekeeper requires Developer ID Installer certificates for packages

**Solution**: 
- Added proper code signing with Developer ID Installer certificate
- Added optional notarization support for zero warnings
- Created `setup-codesigning.sh` helper script for certificate configuration

**Code Changes**:
- Enhanced `build-pkg.sh` and `build-distribution.sh` with `productsign` integration
- Automatic detection of Developer ID Installer certificates
- Environment variable support for signing credentials

### Issue 2: Hardcoded Username Installation
**Problem**: Package created with hardcoded user path `/Users/MrZang/Applications/OpenFolderServer`

**Root Cause**: `pkgbuild` payload directory used `$(whoami)` during build

**Solution**: 
- Changed payload to use temporary directory `/tmp/OpenFolderServer-Install`
- Postinstall script moves files to `$HOME/Applications/OpenFolderServer`
- Works for any user installing the package

**Code Changes**:
```bash
# Before
INSTALL_ROOT="$PAYLOAD_DIR/Users/$(whoami)/Applications/OpenFolderServer"

# After  
INSTALL_ROOT="$PAYLOAD_DIR/tmp/OpenFolderServer-Install"
```

### Issue 3: Node.js Path Detection Issues
**Problem**: Installer scripts failed with `command -v node` not finding Node.js

**Root Cause**: Different Node.js installation locations (Homebrew Intel vs Apple Silicon)

**Solution**: Check multiple common Node.js locations in order:
- `/usr/local/bin/node` (Homebrew Intel)
- `/opt/homebrew/bin/node` (Homebrew Apple Silicon)  
- `/usr/bin/node` (System installation)
- `$(which node)` fallback

**Code Changes**:
```bash
# Robust Node.js detection
NODE_PATH=""
for path in /usr/local/bin/node /opt/homebrew/bin/node /usr/bin/node $(which node 2>/dev/null); do
    if [ -x "$path" ]; then
        NODE_PATH="$path"
        break
    fi
done
```

### Issue 4: npm PATH Environment Issues  
**Problem**: npm couldn't find `node` command during `npm install` in installer environment

**Root Cause**: macOS installer sandbox has limited PATH environment

**Solution**: Export PATH with Node.js directory before running npm
```bash
export PATH="$(dirname "$NODE_PATH"):$PATH"
```

### Development Notes
- Use `spctl --assess --verbose=4 --type install package.pkg` to test Gatekeeper compatibility
- Check `/var/log/install.log` for detailed installer script debugging
- Test installers on clean systems or different user accounts
- Consider notarization for production distribution (requires Apple ID + App-Specific Password)