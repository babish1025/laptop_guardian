"""
Laptop Guardian — Event Reporter
Sends lifecycle events (STARTUP, SHUTDOWN, LOCK, UNLOCK, SLEEP, WAKE) to the backend.
"""
import datetime
import logging
import socket

import requests

log = logging.getLogger("laptop_guardian.agent")


def _get_timezone() -> str:
    try:
        import tzlocal
        return str(tzlocal.get_localzone())
    except Exception:
        try:
            return datetime.datetime.now(datetime.timezone.utc).astimezone().tzname() or "UTC"
        except Exception:
            return "UTC"


def _laptop_time_str() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def _local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return ""


def report_event(
    backend_url: str,
    device_id: str,
    device_token: str,
    event_type: str,
    details: str = "",
    location: dict = None,
    timeout: int = 10,
) -> bool:
    """
    POST an event to the backend activity endpoint.
    Returns True on success, False on failure.
    """
    try:
        from laptop_agent.location import format_location_label

        payload = {
            "device_id":    device_id,
            "device_token": device_token,
            "event_type":   event_type,
            "event_details": details,
            "laptop_time":  _laptop_time_str(),
            "timezone":     _get_timezone(),
        }

        if location:
            payload["latitude"]       = location.get("latitude")
            payload["longitude"]      = location.get("longitude")
            payload["location_label"] = format_location_label(location)

        resp = requests.post(
            f"{backend_url}/api/activity",
            json=payload,
            timeout=timeout,
        )
        if resp.status_code == 200 and resp.json().get("success"):
            log.info(f"Event reported: {event_type}")
            return True
        else:
            log.warning(f"Event report failed [{event_type}]: {resp.text[:200]}")
            return False
    except Exception as e:
        log.error(f"Event report error [{event_type}]: {e}")
        return False
