# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Node.js background service called "open-folder-server" that enables users to open local Dropbox folders in macOS Finder by clicking web links. The server runs silently in the background and starts automatically on login using macOS launchd.

## Development Commands
- **Start server**: `node server.js` or `./start.command`
- **Install dependencies**: `npm install`
- **Test health**: `curl http://localhost:3000/health`
- **Test folder opening**: `curl "http://localhost:3000/open?folder=ProjectX"`
- **Test dynamic path**: `curl "http://localhost:3000/open?path=My%20Projects/Client%20Work"`
- **Build installer**: `cd installer && ./build-pkg.sh`
- **Manual install**: `cd installer && ./install.sh`
- **Uninstall**: `cd installer && ./uninstall.sh`
- **Check service status**: `launchctl list | grep folderopener`
- **View logs**: `cat ~/Applications/OpenFolderServer/logs/server.log`

## Project Structure
- **server.js**: Main Express server handling folder opening requests (port 3000)
- **config.json**: Maps folder keys to Dropbox paths (optional for dynamic mode)
- **start.command**: Shell script to launch server with logging
- **com.folderopener.plist**: macOS launchd configuration for background service
- **logs/**: Directory for server logs and PID files (created automatically)
- **installer/**: Complete installation system with .pkg builder and scripts
  - **build-pkg.sh**: Creates professional macOS installer package
  - **install.sh**: Manual installation script with validation
  - **uninstall.sh**: Complete removal script

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
1. Build installer: `cd installer && ./build-pkg.sh`
2. Share `OpenFolderServer-1.0.0.pkg` with users
3. Users double-click installer and follow wizard
4. Service starts automatically on installation

### Development Install
1. Manual install: `cd installer && ./install.sh`
2. Service installed to `~/Applications/OpenFolderServer/`
3. Launch agent configured for auto-start
4. Test with `curl http://localhost:3000/health`

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

## Architecture Notes
- **Dropbox detection**: Searches multiple common Dropbox locations automatically
- **Path resolution**: All paths are relative to detected Dropbox root
- **Error handling**: Returns JSON error responses with helpful debugging info
- **Logging**: Timestamps all requests and operations for troubleshooting

## Security Notes
- Server only listens on localhost (127.0.0.1:3000)
- Path traversal protection (blocks `../` and absolute paths)
- All paths restricted to Dropbox directory tree
- Uses macOS `open` command to launch Finder safely
- No authentication required for local access