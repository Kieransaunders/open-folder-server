# 📁 Open Folder Server

A macOS background service that enables web applications to open local Dropbox folders in Finder through HTTP requests.

## 🚀 Features

- **Dynamic folder opening** - Open any Dropbox folder via HTTP API
- **Universal Dropbox detection** - Works with all Dropbox installations
- **Background service** - Runs silently and starts on login
- **Security built-in** - Path traversal protection
- **Professional installer** - Double-click `.pkg` installation
- **Web app integration** - Perfect for Airtable, web apps, etc.

## 📦 Installation

### For End Users (Recommended)
Choose your preferred installer:

**Professional Installer (with welcome screen):**
1. Download `OpenFolderServer-1.0.0-installer.pkg`
2. Double-click to install
3. Follow the installation wizard with welcome screen
4. Service starts automatically

**Simple Installer:**
1. Download `OpenFolderServer-1.0.0.pkg`
2. Double-click to install
3. Follow the basic installation wizard
4. Service starts automatically

### For Developers
```bash
# Manual installation
cd installer
./install.sh

# Build basic installer package
./build-pkg.sh

# Build professional installer with welcome screen
./build-distribution.sh

# Build uninstaller package
./build-uninstaller-pkg.sh
```

## 🔧 Usage

### API Endpoints

#### Open Folder (Dynamic Path)
```
GET http://localhost:3000/open?path=<folder_path>
```

**Examples:**
```bash
# Open specific folder
curl "http://localhost:3000/open?path=My%20Projects/Client%20Work"

# Open root Dropbox
curl "http://localhost:3000/open?path=."

# Open nested folder
curl "http://localhost:3000/open?path=Documents/Contracts/2024"
```

#### Health Check
```
GET http://localhost:3000/health
```

#### Configure Root Directory Browser
```
GET http://localhost:3000/browse-root
```

Opens a macOS folder picker to let users select their preferred root directory (Dropbox, iCloud, etc.) for fallback when folders are not found.

#### Legacy Config Mode
```
GET http://localhost:3000/open?folder=<folder_key>
```

### Smart Fallback System

When a requested folder doesn't exist, the server automatically:

1. **Checks if folder exists** - Only opens if the exact path is found
2. **Falls back to root directories** in this order:
   - User-configured root directories (via `/browse-root`)
   - Dropbox root directory
   - iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs`)
   - User home directory (`~`)
   - Desktop (`~/Desktop`)
   - Documents (`~/Documents`)
3. **Provides detailed feedback** - Returns JSON with both requested and opened paths

**Example fallback response:**
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

### Web App Integration

#### JavaScript
```javascript
function openFolder(folderPath) {
    const url = `http://localhost:3000/open?path=${encodeURIComponent(folderPath)}`;
    fetch(url);
}

// Usage
openFolder('My Projects/Client Work');
```

#### Airtable Formula
```
"http://localhost:3000/open?path=" & ENCODE_URL_COMPONENT({Folder Name})
```

## 🛠️ Development

### Prerequisites
- Node.js 16+
- macOS 10.14+
- Dropbox installed and synced

### Setup
```bash
npm install
node server.js
```

### Project Structure
```
├── server.js              # Main Express server
├── config.json           # Folder mappings (optional)
├── start.command         # Launch script
├── com.folderopener.plist # macOS service config
├── installer/            # Installation tools
│   ├── build-pkg.sh      # Build basic .pkg installer
│   ├── build-distribution.sh # Build professional installer
│   ├── build-uninstaller-pkg.sh # Build uninstaller
│   ├── install.sh        # Manual installer
│   └── uninstall.sh      # Manual uninstaller
├── plan.md              # Project planning
└── todo.md              # Task tracking
```

## 🔒 Security

- **Path validation** - Prevents `../` traversal attacks
- **Dropbox-only access** - All paths relative to Dropbox
- **Localhost binding** - Only accessible from local machine
- **Input sanitization** - Validates all path parameters

## 🌟 Use Cases

- **Airtable integrations** - Open deal folders directly from records
- **Web applications** - File management interfaces
- **Productivity tools** - Quick folder access from any web app
- **Team workflows** - Shared folder access systems

## 📋 Configuration

Optional folder mappings in `config.json`:
```json
{
  "ProjectX": "Clients/ProjectX",
  "Finance2025": "Finance/Invoices2025"
}
```

## 🔧 Troubleshooting

### Installer Issues (Fixed in v1.0.0)

#### macOS Gatekeeper Security Block
**Problem**: `"rejected source=no usable signature"` or installer blocked by macOS security
**Solution**: Installer packages are now properly code-signed with Developer ID Installer certificate

**For unsigned packages (development)**:
```bash
# Method 1: Right-click installer and select "Open"
# Method 2: Bypass Gatekeeper temporarily
sudo spctl --add --label "OpenFolderServer" path/to/package.pkg
```

#### Hardcoded Username Installation
**Problem**: Package only installed for specific user who built it
**Solution**: Installer now uses temporary directory approach with dynamic user paths

#### Node.js Path Detection Issues
**Problem**: Installer couldn't find Node.js in various installation locations
**Solution**: Scripts now check multiple common Node.js locations:
- `/usr/local/bin/node` (Homebrew Intel)
- `/opt/homebrew/bin/node` (Homebrew Apple Silicon)
- `/usr/bin/node` (System installation)

#### npm PATH Environment Issues
**Problem**: npm couldn't find Node.js during package installation
**Solution**: Installer now sets proper PATH environment including Node.js directory

### Service Not Starting
```bash
# Check service status
launchctl list | grep folderopener

# View logs
cat ~/Applications/OpenFolderServer/logs/server.log
```

### Folder Not Opening
1. Verify folder exists in Dropbox
2. Check path spelling and encoding
3. Review server logs for errors

## 🗑️ Uninstallation

### Option 1: PKG Uninstaller (Recommended)
1. Download `OpenFolderServer-Uninstaller-1.0.0.pkg`
2. Double-click to run
3. Follow the uninstaller wizard
4. Service completely removed

### Option 2: Manual Uninstall
```bash
cd installer
./uninstall.sh
```

### Option 3: Quick Manual Uninstall
```bash
launchctl unload ~/Library/LaunchAgents/com.folderopener.plist 2>/dev/null || true && rm -f ~/Library/LaunchAgents/com.folderopener.plist && rm -rf ~/Applications/OpenFolderServer && echo "✅ Uninstalled!"
```

## 🏗️ Build Process

### Create Installers
```bash
cd installer

# Build basic installer
./build-pkg.sh

# Build professional installer with welcome screen
./build-distribution.sh

# Build uninstaller
./build-uninstaller-pkg.sh
```

### Manual Install/Uninstall
```bash
cd installer

# Install
./install.sh

# Uninstall
./uninstall.sh
```

## ⚠️ Disclaimer

**USE AT YOUR OWN RISK**: This software is provided "as is" without warranty of any kind, express or implied. The authors and contributors shall not be liable for any damages arising from the use of this software.

**Security Notice**: This application creates a local HTTP server that can open folders on your system. While it includes security measures (localhost-only binding, path validation), users should understand the security implications before installation.

**System Access**: The application requires permissions to:
- Run background processes via macOS launchd
- Access and open folders in your file system
- Create network connections on localhost port 3000

By installing and using this software, you acknowledge these risks and agree to use it responsibly.

## 📄 License

MIT License - Feel free to use and modify

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📧 Support

For issues or questions:
1. Check the troubleshooting section
2. Review log files
3. Create an issue in the repository