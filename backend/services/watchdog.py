"""
Laptop Guardian — Watchdog Service
Background thread that monitors heartbeats and marks devices OFFLINE
when no heartbeat arrives within the configured timeout.

Distinguishes:
- UNEXPECTED_OFFLINE: heartbeat stopped without a clean shutdown event
- SHUTDOWN: agent sent an explicit SHUTDOWN event (already handled by activity route)
"""
import os
import time
import threading
import logging
from datetime import datetime, timedelta

log = logging.getLogger("laptop_guardian.backend")

OFFLINE_TIMEOUT = int(os.getenv("OFFLINE_TIMEOUT", 90))  # seconds (default 90s, allowing multiple missed heartbeats)
CHECK_INTERVAL  = int(os.getenv("WATCHDOG_CHECK_INTERVAL", 15))  # how often watchdog scans (seconds)


def _get_db():
    # Import here to avoid circular dependency
    from backend.database import get_db
    return get_db()


def _run_watchdog():
    log.info("Watchdog thread started: monitoring online devices...")
    while True:
        try:
            _check_devices()
        except Exception as e:
            log.error(f"Watchdog error: {e}")
        time.sleep(CHECK_INTERVAL)


def _check_devices():
    conn = _get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cutoff = datetime.utcnow() - timedelta(seconds=OFFLINE_TIMEOUT)

        # Find ONLINE devices whose heartbeat has timed out
        cur.execute(
            """SELECT device_id, user_id, device_name, last_seen
               FROM devices
               WHERE status = 'ONLINE'
                 AND (last_seen IS NULL OR last_seen < %s)""",
            (cutoff,),
        )
        stale = cur.fetchall()

        for dev in stale:
            device_id = dev["device_id"]
            log.warning(f"Device {device_id} marked OFFLINE (heartbeat timeout).")

            # Mark device offline
            cur.execute(
                "UPDATE devices SET status='OFFLINE', last_seen=UTC_TIMESTAMP() WHERE device_id=%s",
                (device_id,),
            )

            # Log unexpected offline event
            cur.execute(
                """INSERT INTO activity_logs (device_id, event_type, event_details)
                   VALUES (%s, 'UNEXPECTED_OFFLINE', %s)""",
                (device_id, f"Unexpected offline event detected. No heartbeat for >{OFFLINE_TIMEOUT}s."),
            )
            conn.commit()

            # Create notification
            from backend.services.notifications import create_notification
            create_notification(
                dev["user_id"],
                device_id,
                "⚠️ Unexpected Offline",
                f"{dev['device_name']} lost connection unexpectedly. Last seen: "
                + (dev["last_seen"].strftime("%d %b %Y %I:%M:%S %p") if dev["last_seen"] else "unknown"),
            )
    finally:
        conn.close()


def start_watchdog():
    """Start the watchdog in a daemon thread."""
    t = threading.Thread(target=_run_watchdog, daemon=True, name="lg-watchdog")
    t.start()
    return t
