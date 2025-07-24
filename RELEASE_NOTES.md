# 🚀 Open Folder Server v1.0.0

**A macOS background service that enables web applications to open local Dropbox folders in Finder through HTTP requests.**

## 📦 Installation

### Quick Install (Recommended)
1. Download `OpenFolderServer-1.0.0.pkg`
2. Double-click to install
3. Follow the installation wizard
4. Service starts automatically

### What Gets Installed
- Background service runs on `localhost:3000`
- Starts automatically on login
- Installs to `~/Applications/OpenFolderServer`

## ✨ Features

### 🔗 **Dynamic Folder Opening**
- Open any Dropbox folder via HTTP API
- No need to pre-configure folder mappings
- Perfect for web applications and Airtable

### 🔒 **Security Built-in**
- Path traversal protection (blocks `../` attacks)
- Localhost-only access
- Input validation and sanitization

### 🌍 **Universal Compatibility**
- Works with all Dropbox installations
- Supports both legacy and modern Dropbox paths
- Compatible with personal and business accounts

### 🛠️ **Web App Integration**
Perfect for:
- Airtable deal folders
- CRM systems
- Project management tools
- Any web application needing file access

## 🔧 Usage

### API Endpoints

#### Open Folder
```
GET http://localhost:3000/open?path=<folder_path>
```

**Examples:**
```bash
# Open specific folder
curl "http://localhost:3000/open?path=My%20Projects/Client%20Work"

# Open root Dropbox
curl "http://localhost:3000/open?path=."
```

#### Health Check
```
GET http://localhost:3000/health
```

### Airtable Integration
Update your Airtable formula to:
```
"http://localhost:3000/open?path=" & ENCODE_URL_COMPONENT({Folder Name})
```

### JavaScript Integration
```javascript
function openFolder(folderPath) {
    fetch(`http://localhost:3000/open?path=${encodeURIComponent(folderPath)}`);
}
```

## 📋 Requirements

- **macOS 10.14** or later
- **Node.js 16+** (installer will check)
- **Dropbox** installed and synced

## 🔧 Troubleshooting

### Service Not Starting
```bash
# Check service status
launchctl list | grep folderopener

# View logs
cat ~/Applications/OpenFolderServer/logs/server.log
```

### Uninstall
```bash
# Download and run uninstaller
curl -O https://raw.githubusercontent.com/Kieransaunders/open-folder-server/main/installer/uninstall.sh
chmod +x uninstall.sh
./uninstall.sh
```

## 🆕 What's New in v1.0.0

- **Initial release** with full functionality
- Dynamic folder path support
- Universal Dropbox detection
- Professional macOS installer
- Background service integration
- Comprehensive security features
- Web application ready

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/Kieransaunders/open-folder-server/issues)
- **Documentation**: [README](https://github.com/Kieransaunders/open-folder-server#readme)
- **Source Code**: [GitHub Repository](https://github.com/Kieransaunders/open-folder-server)

---

**Ready to streamline your folder access workflow!** 🎯