"""
Laptop Guardian — Heartbeat Sender
Sends periodic heartbeats to the backend and returns any pending commands.
"""
import datetime
import logging
import socket

import requests

log = logging.getLogger("laptop_guardian.agent")


def _local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return ""


def _get_battery() -> tuple[int | None, bool]:
    """Returns (battery_percent, is_charging). Both None/False if unavailable."""
    try:
        import psutil
        batt = psutil.sensors_battery()
        if batt:
            return int(batt.percent), batt.power_plugged
    except Exception:
        pass
    return None, False


def _get_timezone() -> str:
    try:
        import tzlocal
        return str(tzlocal.get_localzone())
    except Exception:
        return ""


def send_heartbeat(backend_url: str, device_id: str, device_token: str) -> list[dict]:
    """
    POST heartbeat to backend.
    Returns list of pending commands from the response (may be empty).
    """
    battery, charging = _get_battery()
    payload = {
        "device_id":    device_id,
        "device_token": device_token,
        "battery":      battery,
        "charging":     charging,
        "ip_address":   _local_ip(),
        "timezone":     _get_timezone(),
        "laptop_time":  datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }
    try:
        resp = requests.post(
            f"{backend_url}/api/heartbeat",
            json=payload,
            timeout=8,
        )
        if resp.status_code == 200:
            data = resp.json()
            commands = data.get("commands", [])
            if commands:
                log.info(f"Heartbeat OK — {len(commands)} pending command(s) received.")
            return commands
        else:
            log.warning(f"Heartbeat HTTP {resp.status_code}: {resp.text[:100]}")
            return []
    except requests.exceptions.ConnectionError:
        log.warning("Heartbeat failed: cannot connect to backend.")
        return []
    except Exception as e:
        log.error(f"Heartbeat error: {e}")
        return []
