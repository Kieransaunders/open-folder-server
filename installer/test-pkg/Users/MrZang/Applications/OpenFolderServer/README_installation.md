# 📁 Open Folder Server - Installation Guide

## Prerequisites

- **Node.js** (v16 or later) - [Download here](https://nodejs.org/)
- **Dropbox** installed and synced on your Mac
- **macOS** (tested on macOS 10.14+)

## Installation Steps

### 1. Install Dependencies
```bash
cd "/Users/MrZang/Development/Finder app/Open drobbox/open-folder-server"
npm install
```

### 2. Configure Folder Mappings
Edit `config.json` to map your folder keys to actual Dropbox paths:

```json
{
  "ProjectX": "Clients/ProjectX",
  "Finance2025": "Finance/Invoices2025",
  "Documents": "Documents",
  "Photos": "Photos"
}
```

**Note**: Paths are relative to your `~/Dropbox/` folder.

### 3. Test the Server Manually
```bash
# Start the server
./start.command

# Test in another terminal
curl "http://localhost:3000/health"
curl "http://localhost:3000/open?folder=ProjectX"
```

### 4. Install as Background Service

Copy the launch agent file to the system directory:
```bash
cp com.folderopener.plist ~/Library/LaunchAgents/
```

Load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.folderopener.plist
```

### 5. Verify Installation
```bash
# Check if service is running
launchctl list | grep folderopener

# Test the service
open "http://localhost:3000/health"
```

## Usage

Once installed, you can open folders by visiting URLs like:
- `http://localhost:3000/open?folder=ProjectX`
- `http://localhost:3000/open?folder=Finance2025`

The server will automatically start when you log in and keep running in the background.

## Troubleshooting

### Service Won't Start
```bash
# Check for errors
cat logs/launchd.err

# Manually restart
launchctl unload ~/Library/LaunchAgents/com.folderopener.plist
launchctl load ~/Library/LaunchAgents/com.folderopener.plist
```

### Folder Not Opening
1. Verify the folder exists in Dropbox
2. Check the path mapping in `config.json`
3. Look at server logs: `tail -f logs/server.log`

### Permission Issues
macOS may ask for permission to access folders. Click "Allow" when prompted.

## Uninstallation

To remove the service:
```bash
# Stop and remove the service
launchctl unload ~/Library/LaunchAgents/com.folderopener.plist
rm ~/Library/LaunchAgents/com.folderopener.plist

# Remove the project folder
rm -rf "/Users/MrZang/Development/Finder app/Open drobbox/open-folder-server"
```

## Log Files

- **Server logs**: `logs/server.log`
- **Launch daemon logs**: `logs/launchd.out` and `logs/launchd.err`
- **Process ID**: `logs/server.pid`

## Security Notes

- The server only listens on `localhost` (127.0.0.1)
- Only pre-configured folder keys are accepted
- No authentication is required for local access
- Consider adding authentication for enhanced security

## Support

For issues or questions, check the log files first. Common problems and solutions are documented in the troubleshooting section above.