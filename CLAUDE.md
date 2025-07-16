# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Node.js background service called "open-folder-server" that enables users to open local Dropbox folders in macOS Finder by clicking web links. The server runs silently in the background and starts automatically on login using macOS launchd.

## Development Commands
- **Start server**: `node server.js` or `./start.command`
- **Install dependencies**: `npm install`
- **Test health**: `curl http://localhost:3000/health`
- **Test folder opening**: `curl "http://localhost:3000/open?folder=ProjectX"`

## Project Structure
- **server.js**: Main Express server handling folder opening requests
- **config.json**: Maps folder keys to Dropbox paths (relative to ~/Dropbox/)
- **start.command**: Shell script to launch server with logging
- **com.folderopener.plist**: macOS launchd configuration for background service
- **logs/**: Directory for server logs (created automatically)

## Key Features
- **HTTP endpoints**: `/open?folder=<key>` and `/health`
- **Folder mapping**: Configurable via config.json
- **Background service**: Runs automatically on macOS login
- **Logging**: Comprehensive logging to logs/server.log
- **Error handling**: Graceful handling of invalid folders and paths

## Installation Process
1. Configure folder mappings in config.json
2. Copy plist file to ~/Library/LaunchAgents/
3. Load with: `launchctl load ~/Library/LaunchAgents/com.folderopener.plist`
4. Test with browser or curl

## Security Notes
- Server only listens on localhost (127.0.0.1:3000)
- Only pre-configured folder keys are accepted
- Uses macOS `open` command to launch Finder
- No authentication required for local access