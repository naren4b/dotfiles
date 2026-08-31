# Cursor Windows-WSL Bridge System Setup Guide
**File Reference:** `cursor-system-setup.md`  
**Last Updated:** August 2026  

This document outlines the system configuration required to successfully bridge the **Cursor IDE** running natively on Windows with the **WSL (Windows Subsystem for Linux)** environment. Following this setup prevents the common issue where WSL falls into an endless 102MB background server download loop (`cursor-reh-linux-x64.tar.gz`) over local proxies.

---

## 1. Architectural Overview
* **UI Layer (Windows Host):** The visual interface, editor window, extensions, and menus must install and run entirely on the native Windows operating system.
* **Backend Engine (WSL/Linux Subsystem):** Your source code files, compilers, and development servers reside securely within Linux.
* **The Bridge:** When you execute `cursor .` from WSL, it must command Windows to spin up the native visual application while mounting the remote Linux directory. 

---

## 2. Windows Prerequisites

### Step A: Native Installation
1. Download the Windows `.exe` installer directly from the official [Cursor Download Page](https://cursor.com).
2. Run the installer. Ensure you check the option to **"Add to PATH"** during the wizard.

### Step B: Environment Path Verification
Ensure Windows registers the exact location of the binary. 
1. Open a native Windows **Command Prompt** (not WSL).
2. Execute the verification tool:
   ```cmd
   where cursor
   ```
3. **Expected Output Path:**
   ```text
   C:\Users\<Your-Windows-Username>\AppData\Local\Programs\cursor\resources\app\bin\cursor
   ```
*(If this fails, add the directory manually via `System Properties` -> `Environment Variables` -> `User Variables` -> `Path`).*

---

## 3. WSL Subsystem Cleanup & Configuration

Run these commands inside your **WSL terminal** to purge localized configurations and map execution safely to Windows.

### Step A: Purge Broken Server Cache
Wipe out any corrupted headless Linux server instances trying to bypass the native client:
```bash
rm -rf ~/.cursor-server
rm -rf ~/.cursor
```

### Step B: Create a Direct Windows Alias
Force the `cursor` command in Linux to explicitly map out to the Windows filesystem mountpoint. 

1. Open your bash configuration profile:
   ```bash
   nano ~/.bashrc
   ```
2. Scroll to the bottom and add the following explicit alias line (replace `YOUR_WINDOWS_USERNAME` with your exact folder name):
   ```bash
   alias cursor="/mnt/c/Users/YOUR_WINDOWS_USERNAME/AppData/Local/Programs/cursor/resources/app/bin/cursor"
   ```
3. Save and close the editor (`Ctrl+O`, `Enter`, `Ctrl+X`), then reload your shell environment:
   ```bash
   source ~/.bashrc
   ```

### Step C: Confirm Interoperability Path
Run the search locator in WSL to make sure it tracks through the `/mnt/c/` path:
```bash
which cursor
```
* **Correct Return Value:** `/mnt/c/Users/YOUR_WINDOWS_USERNAME/AppData/Local/Programs/cursor/resources/app/bin/cursor`

---

## 4. Operational Checklists & Troubleshooting

### The Golden Rule: Cold-Starting Workspace Sessions
If the Windows application is completely closed when you type `cursor .` inside WSL, the background connector sequence might panic and default back to downloading a standalone server loop. 

**Always use this sequence to spin up a workplace session:**
1. Minimize the terminal and launch **Cursor** directly from your **Windows Start Menu** first. 
2. Let the visual application load completely on your desktop.
3. Return to your WSL command line, navigate to your target project folder, and launch:
   ```bash
   cursor .
   ```

### Command Reference: Monitoring Status From WSL
You can track if Cursor's core client is actively alive on the Windows side right from your Linux terminal using Windows execution bridges.

* **Check running processes:**
  ```bash
  tasklist.exe /FI "IMAGENAME eq Cursor.exe"
  ```
* **Quick pipeline status check:**
  ```bash
  tasklist.exe | grep -i "Cursor.exe" && echo "Cursor is running on Windows!" || echo "Not running."
  ```

---
### Expected Behavior After Successful Bridging
* **First Launch:** Cursor takes 3–5 seconds to initialize a minimal, lightweight inter-op bridge pipeline.
* **Subsequent Launches:** Typing `cursor .` instantly pulls up your project files in your running Windows editor windows without terminal downloads, even when working behind corporate proxies.
