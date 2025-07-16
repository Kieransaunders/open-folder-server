# 📁 Open Folder Server – Background Service Setup Plan

## ✅ Purpose

This project enables users to click a web link like:

http://localhost:3000/open?folder=ProjectX

...and automatically open the corresponding **local Dropbox folder** in **macOS Finder**. It runs silently in the background on the user's machine and starts automatically on login.

---

## 📦 Components

### 1. `server.js`
A lightweight Express server that:
- Listens on `localhost:3000`
- Accepts GET requests at `/open?folder=XYZ`
- Maps folder keys (like `ProjectX`) to local Dropbox paths
- Uses `child_process.exec` to open Finder via the `open` command

---

### 2. `start.command`
A shell script that launches the server:
- Changes to the working directory
- Starts the server using Node.js
- Logs output to a text file for debugging

---

### 3. `com.yourname.folderopener.plist`
A `launchd` agent file that:
- Starts the `start.command` script at user login
- Keeps the service running in the background
- Lives in `~/Library/LaunchAgents/`

---

### 4. `config.json` (Optional)
A JSON file storing folder key mappings, e.g.:

```json
{
  "ProjectX": "Clients/ProjectX",
  "Finance2025": "Finance/Invoices2025"
}
```

---

### 5. `README_installation.md`

Instructions for manual installation:
- Copy the .plist to `~/Library/LaunchAgents`
- Load it using `launchctl`
- Confirm the server starts successfully

---

## 🗂 Folder Structure

```
open-folder-helper/
├── server.js
├── start.command
├── config.json
├── com.yourname.folderopener.plist
├── README_installation.md
└── plan.md
```

---

## 🔄 Installation Flow (Manual)

1. Place the entire folder at:
   `/Users/[username]/OpenFolderHelper`

2. Copy Launch Agent file:
   ```bash
   cp com.yourname.folderopener.plist ~/Library/LaunchAgents/
   ```

3. Load it with launchctl:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.yourname.folderopener.plist
   ```

4. Open a browser and test:
   ```
   http://localhost:3000/open?folder=ProjectX
   ```

---

## ✨ Enhancements (Optional)

| Feature | Benefit |
|---------|---------|
| Token authentication | Prevents unauthorized use of the server |
| Expiry logic for stale links | Avoids opening long-dead folders |
| Logging | Track which folders were opened, and when |
| Auto-installer .pkg | Simplified deployment for non-technical users |

---

## 🧪 Testing Checklist

- [ ] Confirm server opens folder in Finder
- [ ] Confirm service starts automatically after reboot
- [ ] Confirm valid folders open and invalid ones fail gracefully
- [ ] Confirm no security warnings or access errors on macOS

---

## ⏱ Estimated Build Time

| Task | Time |
|------|------|
| Write and test server.js | 20–30 min |
| Write start.command | 10 min |
| Create launch agent plist | 30 min |
| Prepare config.json and folder map | 10 min |
| Bundle with README and test locally | 30 min |

---

## Next Steps:
- [ ] Write server.js and start.command
- [ ] Generate .plist with correct paths
- [ ] Test everything locally
- [ ] Deliver as .zip or build .pkg if needed

Let me know if you'd like me to pre-fill this with your actual username and folder paths, or generate the corresponding files directly!