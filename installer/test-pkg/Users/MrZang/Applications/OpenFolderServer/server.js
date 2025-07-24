const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

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
  const possibleDropboxPaths = [
    path.join(process.env.HOME, 'Library/CloudStorage/Dropbox'),
    path.join(process.env.HOME, 'Dropbox'),
    path.join(process.env.HOME, 'Library/CloudStorage/Dropbox-Personal'),
    path.join(process.env.HOME, 'Library/CloudStorage/Dropbox-Business')
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

  // Execute macOS open command
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
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'running',
    port: PORT,
    folders: Object.keys(config)
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