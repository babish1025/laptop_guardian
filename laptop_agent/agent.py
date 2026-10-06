"""
Laptop Guardian — Main Background Agent

This is the primary Windows background process that:
1. Loads credentials from the local config file
2. Sends startup event
3. Sends periodic heartbeats (every 20s by default)
4. Updates location periodically (every 5 min)
5. Polls for and executes pending commands
6. Sends shutdown event on clean exit

Run: python agent.py
"""
import os
import sys
import json
import time
import signal
import logging
import atexit
import datetime

# Ensure project root is importable
_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, _PROJECT_ROOT)

from dotenv import load_dotenv
load_dotenv(os.path.join(_PROJECT_ROOT, ".env"))

from utils.logging_config import get_logger
from laptop_agent.heartbeat import send_heartbeat
from laptop_agent.location  import get_location, format_location_label
from laptop_agent.events    import report_event
from laptop_agent.commands  import execute_command

log = get_logger("agent", "agent.log")

# ── Configuration ─────────────────────────────────────────────────────────────

BACKEND_URL        = os.getenv("BACKEND_URL", "http://127.0.0.1:5000").strip().rstrip("/")
HEARTBEAT_INTERVAL = int(os.getenv("HEARTBEAT_INTERVAL", 30))
LOCATION_INTERVAL  = 300  # update location every 5 minutes
CREDENTIALS_FILE   = os.path.join(_PROJECT_ROOT, ".device_credentials.json")


# ── Credential Loading ────────────────────────────────────────────────────────

def load_credentials() -> dict | None:
    """Load device credentials from local JSON file."""
    if not os.path.exists(CREDENTIALS_FILE):
        return None
    try:
        with open(CREDENTIALS_FILE, "r") as f:
            creds = json.load(f)
        if creds.get("device_id") and creds.get("device_token"):
            return creds
    except Exception as e:
        log.error(f"Failed to load credentials: {e}")
    return None


# ── Event Wrapper ─────────────────────────────────────────────────────────────

_current_location = None


def _report(event_type: str, details: str = "", location: dict = None):
    creds = load_credentials()
    if not creds:
        log.warning(f"Cannot report {event_type}: no credentials.")
        return False
    return report_event(
        backend_url=BACKEND_URL,
        device_id=creds["device_id"],
        device_token=creds["device_token"],
        event_type=event_type,
        details=details,
        location=location or _current_location,
    )


# ── Shutdown Hook ─────────────────────────────────────────────────────────────

_shutting_down = False


def _on_exit():
    global _shutting_down
    if not _shutting_down:
        _shutting_down = True
        log.info("Agent exiting — sending shutdown event...")
        # Only report clean shutdown if this is a normal exit (not a crash)
        # SIGTERM or keyboard interrupt -> clean shutdown
        # Unexpected crash -> watchdog will detect UNEXPECTED_OFFLINE
        _report("SHUTDOWN", "Agent clean shutdown.")


def _signal_handler(sig, frame):
    global _shutting_down
    _shutting_down = True
    log.info(f"Signal {sig} received — initiating clean shutdown.")
    _report("SHUTDOWN", "Clean shutdown via signal.")
    sys.exit(0)


# ── Location Update ───────────────────────────────────────────────────────────

def _update_location(creds: dict):
    global _current_location
    log.debug("Updating location...")
    try:
        loc = get_location()
        if loc:
            _current_location = loc
            import requests
            payload = {
                "device_id":    creds["device_id"],
                "device_token": creds["device_token"],
                **loc,
            }
            resp = requests.post(f"{BACKEND_URL}/api/location", json=payload, timeout=8)
            if resp.status_code == 200:
                label = format_location_label(loc)
                log.info(f"Location updated: {label}")
            else:
                log.warning(f"Location post failed: {resp.text[:100]}")
        else:
            log.warning("Could not determine location.")
    except Exception as e:
        log.error(f"Location update error: {e}")


_mutex_handle = None


def _acquire_single_instance_lock() -> bool:
    """Ensure only one instance of the agent runs at a time using Windows kernel mutex."""
    global _mutex_handle
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        mutex_name = "Global\\LaptopGuardianAgentMutex"
        _mutex_handle = kernel32.CreateMutexW(None, False, mutex_name)
        last_error = kernel32.GetLastError()
        ERROR_ALREADY_EXISTS = 183
        if last_error == ERROR_ALREADY_EXISTS:
            log.warning("Another instance of Laptop Guardian Agent is already running. Exiting.")
            return False
        return True
    except Exception as e:
        log.warning(f"Single-instance mutex warning: {e}")
        return True


# ── Main Loop ─────────────────────────────────────────────────────────────────

def main():
    global _current_location, _shutting_down

    if not _acquire_single_instance_lock():
        sys.exit(0)

    # Register shutdown hooks
    atexit.register(_on_exit)
    signal.signal(signal.SIGTERM, _signal_handler)
    try:
        signal.signal(signal.SIGBREAK, _signal_handler)  # Windows Ctrl+Break
    except AttributeError:
        pass

    log.info("=" * 60)
    log.info("Laptop Guardian Agent v2.0 starting...")
    log.info(f"Backend: {BACKEND_URL}")
    log.info(f"Heartbeat interval: {HEARTBEAT_INTERVAL}s")

    # Load credentials
    creds = load_credentials()
    if not creds:
        log.error(
            "No device credentials found.\n"
            "Please run: python register_device.py\n"
            "to pair this laptop with your account first."
        )
        sys.exit(1)

    device_id    = creds["device_id"]
    device_token = creds["device_token"]
    log.info(f"Device ID: {device_id}")

    # Initial location fetch
    log.info("Fetching initial location...")
    _update_location(creds)

    # Send startup event
    _report("STARTUP", f"Agent started. Device: {device_id}", _current_location)

    last_location_update = time.time()

    # Main heartbeat loop
    while not _shutting_down:
        try:
            # Send heartbeat and get commands
            pending_cmds = send_heartbeat(BACKEND_URL, device_id, device_token)

            # Execute any pending commands
            for cmd in pending_cmds:
                execute_command(
                    cmd=cmd,
                    backend_url=BACKEND_URL,
                    device_id=device_id,
                    device_token=device_token,
                    event_reporter=lambda etype, details, loc=None: report_event(
                        BACKEND_URL, device_id, device_token, etype, details, loc or _current_location
                    ),
                    location=_current_location,
                )

            # Update location every LOCATION_INTERVAL seconds
            now = time.time()
            if now - last_location_update >= LOCATION_INTERVAL:
                _update_location(creds)
                last_location_update = now

        except KeyboardInterrupt:
            log.info("KeyboardInterrupt — clean shutdown.")
            _shutting_down = True
            _report("SHUTDOWN", "Clean shutdown by user.")
            break
        except Exception as e:
            log.error(f"Main loop error: {e}")

        # Sleep in small chunks so we can react to shutdown quickly
        for _ in range(HEARTBEAT_INTERVAL):
            if _shutting_down:
                break
            time.sleep(1)

    log.info("Agent stopped.")


if __name__ == "__main__":
    main()
