# 📋 Open Folder Server - Development Todo List

## 🎯 Phase 1: Core Server Implementation

### 1. Create server.js
- [ ] Set up Express server listening on localhost:3000
- [ ] Create `/open` route handler that accepts `folder` query parameter
- [ ] Implement folder mapping logic (read from config.json)
- [ ] Add child_process.exec integration to call macOS `open` command
- [ ] Add error handling for invalid folder keys
- [ ] Add basic logging for debugging
- [ ] Test server manually with curl/browser

### 2. Create config.json
- [ ] Define JSON structure for folder mappings
- [ ] Add sample folder mappings (ProjectX, Finance2025, etc.)
- [ ] Include relative paths from Dropbox root
- [ ] Add validation for config file format

### 3. Create start.command
- [ ] Write shell script header (#!/bin/bash)
- [ ] Add directory change to project folder
- [ ] Add Node.js server startup command
- [ ] Add logging redirection to output file
- [ ] Make script executable (chmod +x)
- [ ] Test script manually

## 🎯 Phase 2: macOS Integration

### 4. Create launchd plist file
- [ ] Create com.yourname.folderopener.plist
- [ ] Set correct Label and Program paths
- [ ] Configure RunAtLoad and KeepAlive
- [ ] Set working directory
- [ ] Add environment variables if needed
- [ ] Test plist syntax with plutil

### 5. Installation Process
- [ ] Test manual installation steps
- [ ] Verify launchctl load works correctly
- [ ] Test service starts on login
- [ ] Verify service restarts if crashed

## 🎯 Phase 3: Documentation & Testing

### 6. Create README_installation.md
- [ ] Write clear installation instructions
- [ ] Include prerequisites (Node.js, Dropbox setup)
- [ ] Add troubleshooting section
- [ ] Include uninstallation steps
- [ ] Add testing instructions

### 7. Testing & Validation
- [ ] Test with various folder keys
- [ ] Test invalid folder handling
- [ ] Test server restart scenarios
- [ ] Test login startup behavior
- [ ] Verify macOS security permissions
- [ ] Test with different Dropbox folder structures

## 🎯 Phase 4: Enhancement & Polish

### 8. Error Handling & Security
- [ ] Add input validation for folder parameter
- [ ] Implement rate limiting
- [ ] Add request logging
- [ ] Handle Dropbox path edge cases
- [ ] Add graceful shutdown handling

### 9. Optional Features (Future)
- [ ] Token authentication system
- [ ] Link expiry mechanism
- [ ] Enhanced logging with timestamps
- [ ] Configuration reload without restart
- [ ] Multiple Dropbox account support

## 🎯 Phase 5: Deployment

### 10. Package & Distribute
- [ ] Create deployment package structure
- [ ] Test on clean macOS system
- [ ] Create .pkg installer (optional)
- [ ] Add version management
- [ ] Create update mechanism

---

## 🚀 Current Status: Planning Phase

**Next Action**: Begin Phase 1 - Core Server Implementation

**Estimated Total Time**: 2-3 hours for core functionality

**Dependencies**: 
- Node.js installed
- Dropbox folder structure known
- macOS system for testing