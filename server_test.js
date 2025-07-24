const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Load configuration
let config = {};
try {
  const configPath = path.join(__dirname, 'config.json');
  const configData = fs.readFileSync(configPath, 'utf8');
  config = JSON.parse(configData);
  console.log('Configuration loaded successfully');
} catch (error) {
  console.error('Error loading config.json:', error.message);
  console.log('Using empty configuration - no folder mappings available');
}

// Logging function
function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

// Route handler for opening folders
app.get('/open', (req, res) => {
  const { folder, path: folderPath } = req.query;
  
  if (!folder && !folderPath) {
    log('Request missing folder or path parameter');
    return res.status(400).json({ 
      error: 'Missing folder or path parameter',
      usage: 'GET /open?folder=<folder_key> OR /open?path=<folder_path>'
    });
  }

  let targetPath;
  
  // Mode 1: Use dynamic path directly
  if (folderPath) {
    // Validate path (security check)
    if (folderPath.includes('..') || folderPath.startsWith('/')) {
      log(`Invalid path rejected: ${folderPath}`);
      return res.status(400).json({ 
        error: 'Invalid path',
        details: 'Path cannot contain ".." or start with "/"'
      });
    }
    targetPath = folderPath;
    log(`Using dynamic path: ${targetPath}`);
  } 
  // Mode 2: Use config mapping (legacy)
  else if (config[folder]) {
    targetPath = config[folder];
    log(`Using config mapping: ${folder} -> ${targetPath}`);
  }
  // Mode 3: Error - neither valid
  else {
    log(`Invalid folder key: ${folder}`);
    return res.status(404).json({ 
      error: 'Folder key not found',
      requested: folder,
      available: Object.keys(config),
      hint: 'Use ?path=<folder_path> for dynamic paths'
    });
  }
  
  // Find Dropbox path (try common locations)
  const homeDir = process.env.HOME || require('os').homedir();
  const possibleDropboxPaths = [
    path.join(homeDir, 'Library/CloudStorage/Dropbox'),
    path.join(homeDir, 'Dropbox'),
    path.join(homeDir, 'Library/CloudStorage/Dropbox-Personal'),
    path.join(homeDir, 'Library/CloudStorage/Dropbox-Business')
  ];
  
  let dropboxBasePath = null;
  for (const testPath of possibleDropboxPaths) {
    if (fs.existsSync(testPath)) {
      dropboxBasePath = testPath;
      break;
    }
  }
  
  if (!dropboxBasePath) {
    log(`Dropbox folder not found in any common location`);
    return res.status(500).json({ 
      error: 'Dropbox folder not found',
      details: 'Could not locate Dropbox folder in standard locations'
    });
  }
  
  const dropboxPath = path.join(dropboxBasePath, targetPath);
  
  log(`Opening folder: ${folder || folderPath} -> ${dropboxPath}`);

  // Check if the target folder exists
  if (fs.existsSync(dropboxPath)) {
    // Folder exists, open it directly
    exec(`open "${dropboxPath}"`, (error, stdout, stderr) => {
      if (error) {
        log(`Error opening folder: ${error.message}`);
        return res.status(500).json({ 
          error: 'Failed to open folder',
          details: error.message
        });
      }

      if (stderr) {
        log(`Warning: ${stderr}`);
      }

      log(`Successfully opened folder: ${folder || folderPath}`);
      res.json({ 
        success: true,
        message: `Opened folder: ${folder || folderPath}`,
        path: dropboxPath
      });
    });
  } else {
    // Folder doesn't exist, try fallback options
    log(`Target folder not found: ${dropboxPath}`);
    
    // Build fallback options, starting with user-configured roots
    const fallbackOptions = [];
    
    // Add user-configured root directories first
    if (config.userRoots && config.userRoots.length > 0) {
      config.userRoots.forEach((userRoot, index) => {
        fallbackOptions.push({ 
          name: `User Root ${index + 1}`, 
          path: userRoot 
        });
      });
    }
    
    // Add common root directories as additional fallbacks
    fallbackOptions.push(
      { name: 'Dropbox Root', path: dropboxBasePath },
      { name: 'iCloud Drive', path: path.join(homeDir, 'Library/Mobile Documents/com~apple~CloudDocs') },
      { name: 'User Home', path: homeDir },
      { name: 'Desktop', path: path.join(homeDir, 'Desktop') },
      { name: 'Documents', path: path.join(homeDir, 'Documents') }
    );
    
    // Find the first available fallback
    let fallbackPath = null;
    let fallbackName = null;
    
    for (const option of fallbackOptions) {
      if (fs.existsSync(option.path)) {
        fallbackPath = option.path;
        fallbackName = option.name;
        break;
      }
    }
    
    if (fallbackPath) {
      log(`Opening fallback directory: ${fallbackName} -> ${fallbackPath}`);
      
      exec(`open "${fallbackPath}"`, (error, stdout, stderr) => {
        if (error) {
          log(`Error opening fallback directory: ${error.message}`);
          return res.status(500).json({ 
            error: 'Failed to open fallback directory',
            details: error.message
          });
        }

        if (stderr) {
          log(`Warning: ${stderr}`);
        }

        log(`Successfully opened fallback directory: ${fallbackName}`);
        res.json({ 
          success: true,
          message: `Folder not found. Opened ${fallbackName} instead.`,
          requested: folder || folderPath,
          requestedPath: dropboxPath,
          opened: fallbackName,
          openedPath: fallbackPath,
          fallback: true
        });
      });
    } else {
      // No fallback directories found
      log(`No fallback directories available`);
      return res.status(404).json({ 
        error: 'Folder not found and no fallback directories available',
        requested: folder || folderPath,
        requestedPath: dropboxPath,
        hint: 'Check if the folder path is correct and if Dropbox/iCloud is properly set up'
      });
    }
  }
});

// Browse for root directory endpoint
app.get('/browse-root', (req, res) => {
  log('Opening directory browser for root selection');
  
  // Use AppleScript to show a folder picker dialog
  const appleScript = `
    tell application "Finder"
      activate
      set chosenFolder to choose folder with prompt "Select your preferred root directory (Dropbox, iCloud, etc.)"
      return POSIX path of chosenFolder
    end tell
  `;
  
  exec(`osascript -e '${appleScript}'`, (error, stdout, stderr) => {
    if (error) {
      log(`Error with directory browser: ${error.message}`);
      return res.status(500).json({ 
        error: 'Failed to open directory browser',
        details: error.message
      });
    }
    
    const selectedPath = stdout.trim();
    log(`User selected root directory: ${selectedPath}`);
    
    // Update config with user's preferred root
    if (!config.userRoots) {
      config.userRoots = [];
    }
    
    // Add to user roots if not already present
    if (!config.userRoots.includes(selectedPath)) {
      config.userRoots.unshift(selectedPath); // Add to front
      
      // Save updated config
      fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
      log(`Saved new root directory to config: ${selectedPath}`);
    }
    
    res.json({ 
      success: true,
      message: 'Root directory selected and saved',
      selectedPath: selectedPath,
      userRoots: config.userRoots
    });
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'running',
    port: PORT,
    folders: Object.keys(config),
    userRoots: config.userRoots || []
  });
});

// Start server
app.listen(PORT, 'localhost', () => {
  log(`Open Folder Server running on http://localhost:${PORT}`);
  log(`Available folders: ${Object.keys(config).join(', ')}`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  log('Shutting down server...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  log('Shutting down server...');
  process.exit(0);
});