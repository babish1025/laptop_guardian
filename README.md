# Laptop Guardian 💻🛡️ — Internet/WAN Architecture

**Laptop Guardian** is an enterprise-grade remote monitoring, telemetry, and control system for personal laptops. It allows you to monitor laptop status, battery levels, geolocation, and power states from an Android smartphone or web browser across the internet—**completely independent of being on the same Wi-Fi network**.

---

## 🏗️ Target WAN Architecture

```
                                  PUBLIC INTERNET
                                         │
                                         ▼
                      ┌─────────────────────────────────────┐
                      │            CLOUD BACKEND            │
                      │           Flask REST API            │
                      │          HTTPS (Port 443)           │
                      │          Gunicorn / WSGI            │
                      └──────────────┬────────┬─────────────┘
                                     │        │
                   ┌─────────────────┘        └──────────────────┐
                   ▼                                             ▼
        ┌───────────────────────┐                     ┌─────────────────────┐
        │   CLOUD MYSQL DB      │                     │  FIREBASE CLOUD     │
        │   Remote Connection   │                     │  MESSAGING (FCM)    │
        │   Encrypted Pool      │                     │  HTTP v1 Push API   │
        └───────────────────────┘                     └──────────┬──────────┘
                                                                 │
                                                                 │ Push Alerts
                                                                 ▼
        ┌───────────────────────┐                     ┌─────────────────────┐
        │     LAPTOP AGENT      │                     │     ANDROID APP     │
        │    Windows Service    │                     │     Flutter UI      │
        │ (Heartbeat, Commands) │                     │ (Oppo / Any Phone)  │
        └───────────────────────┘                     └─────────────────────┘
```

### Communication Flow:
1. **Laptop Agent ──[HTTPS]──► Cloud Flask API**: Sends heartbeats (every 30s), lifecycle events (STARTUP, SHUTDOWN, SLEEP, WAKE, LOCK), and location telemetry over public HTTPS.
2. **Cloud Flask API ◄──► Cloud MySQL**: Stores device states, activity logs, commands, and notification tokens.
3. **Cloud Flask API (Watchdog Service)**: Runs continuously in the cloud. If no heartbeat arrives within `OFFLINE_TIMEOUT` (default: 90s), marks the laptop `OFFLINE` and triggers a push alert.
4. **Cloud Flask API ──[Firebase Admin SDK]──► FCM ──► Android Flutter App**: Dispatches instant push notifications even when the mobile app is in the background or terminated.
5. **Android Flutter App ──[HTTPS]──► Cloud Flask API**: Fetches real-time status, maps location, and dispatches authenticated remote actions (Lock, Restart, Shutdown).

> [!IMPORTANT]
> The mobile app **NEVER** connects directly to the laptop's private LAN IP (`192.168.x.x` or `10.x.x.x`). All traffic traverses the secure public Cloud HTTPS endpoint.

---

## 📋 1. Backend Setup

### Prerequisites
- Python 3.10+ (tested on Python 3.12)
- Virtual environment or Python environment with pip

### Installation
```bash
# From project root
pip install -r requirements.txt
```

### Running Locally for Development
```bash
python backend/app.py
```
By default, the development server binds to `0.0.0.0:5000` or `$PORT`.

---

## 🗄️ 2. MySQL Setup

### Local Development (XAMPP / MySQL)
Ensure MySQL is running on port 3307 or 3306 and create the database:
```sql
CREATE DATABASE IF NOT EXISTS laptop_guardian CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Cloud MySQL (Railway / Aiven / PlanetScale / AWS RDS)
1. Provision a managed MySQL database on your cloud provider.
2. Note the host, port, user, password, and database name.
3. Configure these values in your cloud environment variables.

### Database Migration
Run the idempotent database migration script to verify/apply all tables and columns:
```bash
python migrate.py
```

---

## ☁️ 3. Cloud Deployment (Always-On Server)

Deploy the Flask backend to an always-on cloud provider so it remains accessible 24/7 even when your laptop is sleeping or turned off.

### Option A: Railway (Recommended)
1. Create a new project on [Railway.app](https://railway.app).
2. Provision a **MySQL** database.
3. Add a new service from your GitHub repository (or deploy via Railway CLI: `railway up`).
4. Railway automatically detects `Procfile`:
   ```procfile
   web: gunicorn "backend.app:create_app()" --workers 2 --bind 0.0.0.0:$PORT --timeout 120
   ```
5. Set environment variables in the Railway dashboard (see Section 4).
6. Under Settings > Networking, click **Generate Domain** to get your public HTTPS URL:
   `https://your-app-name.up.railway.app`

### Option B: Render
1. Create a **Web Service** on [Render.com](https://render.com).
2. Set Environment to `Python 3`.
3. Set Build Command: `pip install -r requirements.txt && python migrate.py`.
4. Set Start Command: `gunicorn "backend.app:create_app()" --workers 2 --bind 0.0.0.0:$PORT --timeout 120`.
5. Attach a Render MySQL instance and configure environment variables.

---

## 🔐 4. Environment Variables

Create `.env` based on `.env.example`:

| Variable | Description | Example (Cloud Production) | Example (Local Dev) |
|---|---|---|---|
| `DB_HOST` | MySQL hostname | `monorail.proxy.rlwy.net` | `127.0.0.1` |
| `DB_PORT` | MySQL port | `3306` | `3307` |
| `DB_USER` | Database user | `root` | `root` |
| `DB_PASSWORD` | Database password | `your_secret_password` | *(empty)* |
| `DB_NAME` | Database name | `railway` | `laptop_guardian` |
| `DB_POOL_SIZE` | MySQL pool size | `10` | `10` |
| `SECRET_KEY` | Flask session secret | *(Random 32-char hex)* | `change_me` |
| `FLASK_ENV` | Environment | `production` | `development` |
| `CORS_ORIGINS` | Allowed web origins | `https://your-domain.app` | `*` |
| `BACKEND_URL` | Public HTTPS backend URL | `https://your-app.up.railway.app` | `http://127.0.0.1:5000` |
| `HEARTBEAT_INTERVAL` | Agent heartbeat interval | `30` | `20` |
| `OFFLINE_TIMEOUT` | Timeout to declare offline | `90` | `60` |
| `FIREBASE_CREDENTIALS_PATH` | Path to service account key | `serviceAccountKey.json` | `serviceAccountKey.json` |

---

## 🔥 5. Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a project (e.g. `laptop-guardian`).
2. Add an **Android app** with Package Name:
   `com.laptopguardian.mobile_app`
3. Download the generated `google-services.json` file.
4. Copy `google-services.json` into:
   `mobile_app/android/app/google-services.json`

---

## 📲 6. FCM Configuration (Push Notifications)

### Backend Credentials
1. In Firebase Console, navigate to **Project Settings > Service accounts**.
2. Click **Generate new private key** and download the JSON file.
3. Save it as `serviceAccountKey.json` in the project root:
   `laptop_guardian/serviceAccountKey.json`
   *(Or on cloud hosts, set `FIREBASE_SERVICE_ACCOUNT_JSON` to the raw JSON string)*.

### Supported Notification Events:
- 🟢 **Laptop Online**: Laptop reconnected from sleep, restart, or network dropout.
- 🔴 **Laptop Offline**: Cloud watchdog detected heartbeat timeout.
- 🟢 **Laptop Started**: Laptop OS booted and agent initialized.
- 🔴 **Laptop Shutdown**: Laptop gracefully shut down.
- 😴 **Laptop Sleep**: Laptop entered sleep / standby mode.
- 🟢 **Laptop Wake**: Laptop woke from sleep.
- ⚠️ **Unexpected Offline**: Sudden power loss or Wi-Fi disconnection.

---

## 💻 7. Laptop Agent Setup

The agent runs on your Windows laptop and communicates with your Cloud Backend.

1. Ensure `.env` on your laptop contains your cloud backend URL:
   ```env
   BACKEND_URL=https://your-app.up.railway.app
   HEARTBEAT_INTERVAL=30
   ```
2. Pair your laptop once:
   ```bash
   python register_device.py
   ```
   - Generate a 6-digit pairing code from the web or mobile dashboard.
   - Enter the pairing code in the terminal.
   - Credentials will be securely saved to `.device_credentials.json`.
3. Test running the agent manually:
   ```bash
   python laptop_agent/agent.py
   ```

---

## ⚙️ 8. Windows Autostart Setup (Task Scheduler)

To ensure the agent starts automatically whenever Windows boots, without keeping open CMD windows, and restarts if it crashes:

### Install Auto-Start Task:
1. Open PowerShell or Command Prompt as **Administrator**.
2. Run:
   ```cmd
   scripts\install_laptop_guardian_task.bat
   ```
   This creates a scheduled task (`LaptopGuardianAgent`) that:
   - Uses `pythonw.exe` to run silently in the background.
   - Triggers at user logon.
   - Automatically restarts within 1 minute if terminated unexpectedly.
   - Prevents duplicate running instances via Windows kernel mutex.
   - Writes output to `logs\agent.log`.

### Remove Auto-Start Task:
Run as Administrator:
```cmd
scripts\uninstall_laptop_guardian_task.bat
```

---

## 📱 9. Flutter Mobile App Setup

### Prerequisites
- Flutter 3.20+ with Dart 3.4+
- Android SDK installed

### Dependency Check & Run
```bash
cd mobile_app
flutter pub get
```

### Run on Connected Device / Emulator:
```bash
# Debug mode pointing to your Cloud Backend:
flutter run --dart-define=API_BASE_URL=https://your-app.up.railway.app

# Or local development:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

---

## 📦 10. Building Release APK

To build a standalone production APK for your Oppo or Android device:

```bash
cd mobile_app
flutter build apk --release --dart-define=API_BASE_URL=https://your-app.up.railway.app
```

The compiled APK will be generated at:
`mobile_app/build/app/outputs/flutter-apk/app-release.apk`

Transfer this APK to your phone and install it.

---

## 🧪 11. Internet/WAN Testing Procedures

### Test A: Same Wi-Fi Network
1. Connect laptop and phone to the same home/office Wi-Fi.
2. In the app Settings, verify the active URL is `https://your-app.up.railway.app`.
3. Tap **Test Ping** — verify latency is reported and connection is successful.
4. Verify laptop status shows **ONLINE** with accurate battery and location.

### Test B: Laptop on Wi-Fi, Phone on Mobile 4G/5G
1. Turn off Wi-Fi on your Android phone and enable **Mobile Data**.
2. Open Laptop Guardian mobile app.
3. Verify device status is still **ONLINE**.
4. Tap **Quick Lock** on your phone — verify your laptop workstation locks instantly.

### Test C: Laptop on Different Wi-Fi
1. Connect your laptop to a phone mobile hotspot or neighbor Wi-Fi.
2. Verify laptop agent continues sending heartbeats to `https://your-app.up.railway.app`.
3. Verify status on the phone updates without needing any local router port forwarding.

### Test D: Laptop Shuts Down / Disconnects
1. Put laptop to sleep or turn off Wi-Fi.
2. Within 90 seconds (`OFFLINE_TIMEOUT`), the Cloud Watchdog detects missed heartbeats.
3. Phone receives push alert: **⚠️ Unexpected Offline**.
4. In app, laptop badge changes to **OFFLINE**.

### Test E: Laptop Reconnects
1. Turn laptop back on.
2. Within 30 seconds, heartbeat reaches the cloud backend.
3. Backend transitions status to **ONLINE** and sends push alert: **🟢 Laptop Online**.
4. Phone displays updated battery and time.

---

## 🛠️ 12. Troubleshooting

| Symptom | Cause | Solution |
|---|---|---|
| `Cannot reach server. Check your network` on phone | Mobile app pointing to localhost or private IP | Open Settings in the app and set Server Base URL to your cloud HTTPS domain (`https://your-app.up.railway.app`). |
| Laptop agent logs `ConnectionError` | Laptop cannot reach backend | Check internet connection or verify backend is online by opening `https://your-app.up.railway.app/api/health` in browser. |
| No push notifications received on phone | `google-services.json` or `serviceAccountKey.json` missing | Drop `google-services.json` in `mobile_app/android/app/` and `serviceAccountKey.json` in project root. In-app notification center continues working as fallback. |
| Duplicate agent process running | User ran manual agent while scheduled task was active | Built-in kernel mutex automatically terminates duplicate agents. Check `logs\agent.log`. |
| Phone rejects `http://` URL | Insecure HTTP blocked | All WAN deployments must use `https://`. Use Railway, Render, or a Cloudflare SSL proxy. |
