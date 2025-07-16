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
1. Download `OpenFolderServer-1.0.0.pkg`
2. Double-click to install
3. Follow the installation wizard
4. Service starts automatically

### For Developers
```bash
# Manual installation
cd installer
./install.sh

# Build installer package
./build-pkg.sh
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

#### Legacy Config Mode
```
GET http://localhost:3000/open?folder=<folder_key>
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
│   ├── build-pkg.sh      # Build .pkg installer
│   ├── install.sh        # Manual installer
│   └── uninstall.sh      # Uninstaller
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

### Uninstall
```bash
./installer/uninstall.sh
```

## 🏗️ Build Process

### Create Installer
```bash
cd installer
./build-pkg.sh
```

### Manual Install
```bash
cd installer
./install.sh
```

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