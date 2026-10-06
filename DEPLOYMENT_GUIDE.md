# Laptop Guardian — Complete Deployment & Operation Guide

This guide details how to:
1. Test the Android app locally over your Wi-Fi network with your current XAMPP database.
2. Deploy the backend and database to Railway (or Render) for free cloud hosting with HTTPS.
3. Migrate your database data safely to the cloud.
4. Run the laptop agent and Android app across completely different networks (e.g. phone on mobile data, laptop on office/home Wi-Fi).
5. Build and install the Flutter Android APK.

---

## Architecture Overview

```
[ Android Mobile App ]          [ Laptop Agent (Background) ]
 (4G / 5G / Any Wi-Fi)              (Home / Office / Hotel Wi-Fi)
          │                                      │
          │ HTTPS (REST API + Bearer Token)      │ HTTPS (Outbound Polling & Heartbeat)
          ▼                                      ▼
    ┌──────────────────────────────────────────────────┐
    │           Cloud Backend (Railway / Render)       │
    │           Flask + Gunicorn + PyMySQL             │
    │  - Auth & JWT Session Tokens                     │
    │  - Command Queue & Dispatch                      │
    │  - Heartbeat & Offline Watchdog (20s)            │
    │  - Geolocation & Activity Logging                │
    └─────────────────────────┬────────────────────────┘
                              │ Private Internal Network
                              ▼
    ┌──────────────────────────────────────────────────┐
    │             Cloud MySQL Database                 │
    │  - users, devices, activity_logs, commands       │
    │  - locations, heartbeats, pairing_codes          │
    └──────────────────────────────────────────────────┘
```

---

## Phase 1: Local Testing on Your Home Wi-Fi

Before deploying to the cloud, you can test the Android app against your existing XAMPP MySQL and local Flask server.

### Step 1: Find Your Laptop's LAN IP Address
Open PowerShell and run:
```powershell
ipconfig
```
Look for **IPv4 Address** under your active Wi-Fi adapter (e.g., `192.168.1.105` or `10.89.154.74`).

### Step 2: Open Windows Firewall for Port 5000
Right-click and run:
```bat
scripts\allow_firewall_port_5000.bat
```
*(Or in PowerShell as Administrator: `netsh advfirewall firewall add rule name="Laptop Guardian" dir=in action=allow protocol=TCP localport=5000`)*

### Step 3: Start the Flask Backend
Make sure XAMPP MySQL is running, then in PowerShell:
```powershell
python -m backend.app
```
Confirm the output shows:
```
[INFO] Watchdog thread started: monitoring online devices...
* Running on all addresses (0.0.0.0)
* Running on http://127.0.0.1:5000
```

### Step 4: Run the Flutter Android App
Connect your Android phone via USB (with USB Debugging enabled) or use an emulator:
```powershell
cd mobile_app
flutter pub get
flutter run --dart-define=BASE_URL=http://<YOUR_LAPTOP_IP>:5000
```
*(Replace `<YOUR_LAPTOP_IP>` with your actual IPv4 address, e.g. `http://192.168.1.105:5000`)*

> **Tip:** You can also change the Server Base URL at any time directly in the app:
> Open the app -> Tap **Settings** -> Enter `http://<YOUR_LAPTOP_IP>:5000` -> Tap **Test Ping** -> Tap **Save URL**.

---

## Phase 2: Cloud Deployment (Railway)

Deploying to Railway gives you:
- Free cloud MySQL database.
- Auto-provisioned HTTPS URL (e.g., `https://laptop-guardian-production.up.railway.app`).
- Zero router configuration or port forwarding required.

### Step 1: Export Your Existing XAMPP Database
Run the export script we prepared:
```powershell
python scripts/export_database.py
```
This generates `laptop_guardian_backup.sql` containing all your existing users, devices, activity logs, and table structures.

### Step 2: Create Railway Account & Project
1. Go to [railway.app](https://railway.app) and sign up (GitHub login recommended).
2. Click **+ New Project** -> **Provision MySQL**.
3. Railway will provision a managed MySQL database.

### Step 3: Import Your Database to Railway MySQL
1. Click on the MySQL database service in your Railway dashboard.
2. Go to the **Connect** tab and find your connection command or credentials:
   - Host (`MYSQLHOST`)
   - Port (`MYSQLPORT`)
   - User (`MYSQLUSER`)
   - Password (`MYSQLPASSWORD`)
   - Database (`MYSQLDATABASE`)
3. Open PowerShell and import your backup:
   ```powershell
   mysql -h <MYSQLHOST> -P <MYSQLPORT> -u <MYSQLUSER> -p<MYSQLPASSWORD> <MYSQLDATABASE> < laptop_guardian_backup.sql
   ```
   *(Or connect via MySQL Workbench / phpMyAdmin / DBeaver and run `laptop_guardian_backup.sql`)*

### Step 4: Deploy the Flask Backend to Railway
1. In the same Railway project, click **+ New** -> **GitHub Repo** (or deploy via Railway CLI: `railway up`).
2. Set the following **Variables** in Railway under the Flask service:
   | Variable | Value | Notes |
   |---|---|---|
   | `DB_HOST` | `${{MySQL.MYSQLHOST}}` | Railway variable reference |
   | `DB_PORT` | `${{MySQL.MYSQLPORT}}` | Usually 3306 |
   | `DB_USER` | `${{MySQL.MYSQLUSER}}` | MySQL user |
   | `DB_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` | MySQL password |
   | `DB_NAME` | `${{MySQL.MYSQLDATABASE}}` | Database name |
   | `SECRET_KEY` | *(Generate a 32-char secret)* | Run `python -c "import secrets; print(secrets.token_hex(32))"` |
   | `ENVIRONMENT` | `production` | Production flag |
   | `BACKEND_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Your Railway public domain |

3. Under the **Settings** tab:
   - Click **Generate Domain** under Networking to get your public HTTPS URL (e.g., `https://laptop-guardian-production.up.railway.app`).
   - The included `Procfile` will automatically start the server with Gunicorn:
     `web: gunicorn "backend.app:create_app()" --workers 2 --bind 0.0.0.0:$PORT --timeout 120`

4. Verify health by opening in your browser:
   `https://<YOUR_RAILWAY_URL>/api/health`
   You should see:
   ```json
   {"db": "connected", "service": "Laptop Guardian API", "status": "ok", "version": "2.0"}
   ```

---

## Phase 3: Switch Laptop Agent to Cloud HTTPS

On your laptop:

1. Open `.env` and update the `BACKEND_URL`:
   ```ini
   BACKEND_URL=https://<YOUR_RAILWAY_URL>
   ```

2. Start the laptop agent:
   ```powershell
   python laptop_agent/agent.py
   ```
   The agent will immediately send heartbeats to the cloud HTTPS server.

3. *(Optional)* Install agent to start automatically on Windows boot:
   ```bat
   scripts\install_windows_startup.bat
   ```

---

## Phase 4: Build & Install the Flutter Android APK

### Building the Release APK
In your terminal:
```powershell
cd mobile_app
flutter pub get
flutter build apk --release --dart-define=BASE_URL=https://<YOUR_RAILWAY_URL>
```
The compiled APK will be located at:
```
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

### Installing onto Your Phone
1. Connect your phone via USB and run:
   ```powershell
   flutter install
   ```
   **OR** transfer `app-release.apk` to your phone via Google Drive, WhatsApp, or USB cable, tap on it, and select **Install**.

---

## Phase 5: Testing the Cross-Network Scenario

This tests the ultimate goal: **Phone on 4G/5G mobile data and Laptop on home/office Wi-Fi.**

1. **Disconnect phone from Wi-Fi** -> Enable **Mobile Data (4G/5G)**.
2. Open the **Laptop Guardian** app on your phone.
3. Sign in with your master account.
4. Verify your laptop shows **ONLINE** with active specs and battery level.
5. Tap **Lock Device** -> Confirm -> Verify your laptop immediately locks within seconds!
6. Tap **Play Alarm** -> Confirm -> Verify audible alert sounds on laptop.
7. Tap **Webcam Photo** -> Confirm -> Captures photo.
8. Tap **Location & Map** -> View geolocation and open in Google Maps.
9. Disconnect laptop from Wi-Fi -> Verify after ~20-30 seconds the watchdog flags the device as **OFFLINE**.
