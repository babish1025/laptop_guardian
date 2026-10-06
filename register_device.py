"""
Laptop Guardian — Device Registration & Pairing Tool

Usage: python register_device.py

This tool:
1. Collects hardware info about this laptop
2. Asks for a pairing code (generated in the web dashboard)
3. Registers the device with the backend
4. Saves credentials to .device_credentials.json

Run once per machine. Re-run to re-pair if needed.
"""
import os
import sys
import json
import uuid
import socket
import hashlib
import secrets
import getpass
import platform

# Ensure project root is importable
_PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _PROJECT_ROOT)

from dotenv import load_dotenv
load_dotenv(os.path.join(_PROJECT_ROOT, ".env"))

import requests

BACKEND_URL      = os.getenv("BACKEND_URL", "http://127.0.0.1:5000").strip().rstrip("/")
CREDENTIALS_FILE = os.path.join(_PROJECT_ROOT, ".device_credentials.json")


# ── Hardware Info Collection ──────────────────────────────────────────────────

def _generate_device_id() -> str:
    """Generate a stable unique device ID based on machine UUID."""
    try:
        # Use Windows machine GUID for stability
        import winreg
        key = winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            r"SOFTWARE\Microsoft\Cryptography",
        )
        guid, _ = winreg.QueryValueEx(key, "MachineGuid")
        winreg.CloseKey(key)
        short = hashlib.md5(guid.encode()).hexdigest()[:8].upper()
        return f"LG-{short}"
    except Exception:
        # Fallback: use hostname + MAC address
        mac = uuid.getnode()
        h = hashlib.md5(f"{socket.gethostname()}{mac}".encode()).hexdigest()[:8].upper()
        return f"LG-{h}"


def _collect_hw_info() -> dict:
    info = {
        "device_name": socket.gethostname(),
        "os":          f"{platform.system()} {platform.version()}",
        "username":    getpass.getuser(),
        "cpu":         "",
        "ram":         "",
        "storage":     "",
        "gpu":         "",
        "manufacturer": "",
        "model":       "",
    }

    try:
        info["os"] = f"Windows {platform.win32_ver()[0]}" if platform.system() == "Windows" else info["os"]
        import subprocess

        # CPU
        cpu_out = subprocess.check_output(
            ["wmic", "cpu", "get", "Name", "/value"], text=True, timeout=5
        )
        for line in cpu_out.splitlines():
            if line.startswith("Name="):
                info["cpu"] = line.split("=", 1)[1].strip()
                break

        # RAM
        ram_out = subprocess.check_output(
            ["wmic", "computersystem", "get", "TotalPhysicalMemory", "/value"], text=True, timeout=5
        )
        for line in ram_out.splitlines():
            if line.startswith("TotalPhysicalMemory="):
                val = int(line.split("=", 1)[1].strip() or 0)
                info["ram"] = f"{round(val / 1e9, 1)} GB"
                break

        # Manufacturer / Model
        model_out = subprocess.check_output(
            ["wmic", "computersystem", "get", "Manufacturer,Model", "/value"], text=True, timeout=5
        )
        for line in model_out.splitlines():
            if line.startswith("Manufacturer="):
                info["manufacturer"] = line.split("=", 1)[1].strip()
            elif line.startswith("Model="):
                info["model"] = line.split("=", 1)[1].strip()

        # Use model as device_name if available
        if info["model"]:
            info["device_name"] = info["model"]

        # GPU
        gpu_out = subprocess.check_output(
            ["wmic", "path", "win32_VideoController", "get", "Name", "/value"], text=True, timeout=5
        )
        gpus = []
        for line in gpu_out.splitlines():
            if line.startswith("Name="):
                gpus.append(line.split("=", 1)[1].strip())
        info["gpu"] = "; ".join(gpus)

        # Storage
        import shutil
        total, _, _ = shutil.disk_usage("/")
        info["storage"] = f"{round(total / 1e9, 0):.0f} GB"

    except Exception as e:
        print(f"  (Some hardware info could not be collected: {e})")

    return info


# ── Pairing Flow ──────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  💻 Laptop Guardian — Device Registration")
    print("=" * 60)
    print()
    print(f"Backend URL: {BACKEND_URL}")
    print()

    device_id = _generate_device_id()
    print(f"Device ID:   {device_id}")
    print()

    # Check for existing credentials
    if os.path.exists(CREDENTIALS_FILE):
        print("⚠️  Existing credentials found.")
        overwrite = input("Re-pair this device? (y/N): ").strip().lower()
        if overwrite != "y":
            print("Registration cancelled.")
            sys.exit(0)

    print("Collecting hardware information...")
    hw = _collect_hw_info()
    print(f"  Device name: {hw['device_name']}")
    print(f"  OS:          {hw['os']}")
    print(f"  CPU:         {hw['cpu'] or 'unknown'}")
    print(f"  RAM:         {hw['ram'] or 'unknown'}")
    print(f"  Username:    {hw['username']}")
    print()

    # ── Authentication Choice ─────────────────────────────────────────────────
    print("How do you want to authenticate?")
    print("  1. Pairing code (recommended — generate from web dashboard)")
    print("  2. Email + password (legacy)")
    choice = input("Choice [1/2]: ").strip()

    payload = {
        "device_id":    device_id,
        "device_name":  hw["device_name"],
        "os":           hw["os"],
        "cpu":          hw["cpu"],
        "ram":          hw["ram"],
        "storage":      hw["storage"],
        "gpu":          hw["gpu"],
        "username":     hw["username"],
        "manufacturer": hw["manufacturer"],
        "model":        hw["model"],
    }

    if choice == "2":
        email    = input("Email: ").strip()
        password = getpass.getpass("Password: ")
        payload["email"]    = email
        payload["password"] = password
    else:
        pairing_code = input("Pairing code (from dashboard): ").strip()
        if not pairing_code:
            print("❌ No pairing code entered. Exiting.")
            sys.exit(1)
        payload["pairing_code"] = pairing_code

    # Generate a device token for ongoing auth
    device_token = secrets.token_urlsafe(32)
    payload["device_token"] = device_token

    print()
    print("Registering with backend...")
    try:
        resp = requests.post(
            f"{BACKEND_URL}/api/devices/register",
            json=payload,
            timeout=15,
        )
        data = resp.json()
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to backend at {BACKEND_URL}")
        print("   Make sure the backend is running: python backend/app.py")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Registration error: {e}")
        sys.exit(1)

    if not data.get("success"):
        error = data.get("error", "Unknown error")
        print(f"❌ Registration failed: {error}")
        log_file = os.path.join(_PROJECT_ROOT, "logs", "agent.log")
        with open(log_file, "a") as f:
            f.write(f"[{__import__('datetime').datetime.now()}] [ERROR] [laptop_guardian.agent]: Registration failed: {error}\n")
        sys.exit(1)

    # Save credentials securely
    creds = {
        "device_id":    device_id,
        "device_token": device_token,
        "registered_at": str(__import__("datetime").datetime.now()),
    }
    with open(CREDENTIALS_FILE, "w") as f:
        json.dump(creds, f, indent=2)

    # Log to agent.log
    log_dir = os.path.join(_PROJECT_ROOT, "logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "agent.log")
    with open(log_file, "a") as f:
        f.write(f"[{__import__('datetime').datetime.now()}] [INFO] [laptop_guardian.agent]: Credentials stored securely for device {device_id}\n")
        f.write(f"[{__import__('datetime').datetime.now()}] [INFO] [laptop_guardian.agent]: Device {device_id} registered successfully!\n")

    print()
    print("✅ Device registered successfully!")
    print(f"   Device ID:    {device_id}")
    print(f"   Device name:  {hw['device_name']}")
    print()
    print("To start monitoring, run:")
    print("   python laptop_agent/agent.py")
    print()
    print("To auto-start with Windows, run (as Administrator):")
    print("   scripts\\install_windows_startup.bat")


if __name__ == "__main__":
    main()
