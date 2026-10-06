"""
Laptop Guardian — Heartbeat Routes
POST /api/heartbeat  — agent sends heartbeat every 20s
"""
from datetime import datetime
from flask import Blueprint, request, jsonify
from backend.database import get_db
from backend.auth import hash_device_token
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("heartbeat", __name__, url_prefix="/api")


def _err(msg, code=400):
    return jsonify({"success": False, "error": msg}), code


def _ok(**kwargs):
    return jsonify({"success": True, **kwargs})


def _verify_device_token(device_id: str, token: str) -> int | None:
    """Return user_id if device_id + token match, else None."""
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            "SELECT user_id, device_token_hash FROM devices WHERE device_id=%s",
            (device_id,),
        )
        row = cur.fetchone()
        if not row:
            return None
        if row["device_token_hash"] is None:
            # No token set — allow (legacy / open registration)
            return row["user_id"]
        if hash_device_token(token) == row["device_token_hash"]:
            return row["user_id"]
        return None
    finally:
        conn.close()


@bp.route("/heartbeat", methods=["POST"])
def heartbeat():
    data = request.get_json(silent=True) or {}
    device_id    = (data.get("device_id") or "").strip()
    device_token = (data.get("device_token") or "")
    if not device_token and "Authorization" in request.headers:
        device_token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()

    battery      = data.get("battery") if data.get("battery") is not None else data.get("battery_level")
    charging     = bool(data.get("charging", False) or data.get("battery_charging", False))
    ip_address   = (data.get("ip_address") or "").strip() or None
    timezone_str = (data.get("timezone") or "").strip() or None
    laptop_time  = (data.get("laptop_time") or "").strip() or None

    if not device_id and device_token:
        conn = get_db()
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT device_id FROM devices WHERE device_token_hash=%s", (hash_device_token(device_token),))
            row = cur.fetchone()
            if row:
                device_id = row["device_id"]
        finally:
            conn.close()

    if not device_id:
        return _err("device_id required.")

    user_id = _verify_device_token(device_id, device_token)
    if user_id is None:
        return _err("Invalid device credentials.", 401)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)

        # Check previous status before updating
        cur.execute("SELECT status, device_name FROM devices WHERE device_id=%s", (device_id,))
        dev_row = cur.fetchone()
        prev_status = dev_row["status"] if dev_row else "OFFLINE"
        device_name = dev_row["device_name"] if dev_row else device_id

        # Update device last_seen + status
        update_fields = ["status='ONLINE'", "last_seen=UTC_TIMESTAMP()"]
        update_vals = []
        if battery is not None:
            update_fields.append("battery=%s")
            update_vals.append(int(battery))
        update_fields.append("charging=%s")
        update_vals.append(int(charging))
        if ip_address:
            update_fields.append("ip_address=%s")
            update_vals.append(ip_address)
        if timezone_str:
            update_fields.append("timezone=%s")
            update_vals.append(timezone_str)

        update_vals.append(device_id)
        cur.execute(
            f"UPDATE devices SET {', '.join(update_fields)} WHERE device_id=%s",
            tuple(update_vals),
        )

        # Log to heartbeats table
        cur.execute(
            "INSERT INTO heartbeats (device_id, battery, charging, ip_address) VALUES (%s,%s,%s,%s)",
            (device_id, battery, int(charging), ip_address),
        )

        # If device was previously OFFLINE or SHUTDOWN, it has reconnected!
        reconnected = prev_status in ("OFFLINE", "SHUTDOWN")
        if reconnected:
            log.info(f"Device {device_id} came back ONLINE (was {prev_status}).")
            cur.execute(
                """INSERT INTO activity_logs (device_id, event_type, event_details, laptop_time, laptop_timezone)
                   VALUES (%s, 'ONLINE', %s, %s, %s)""",
                (device_id, f"Laptop reconnected to cloud backend.", laptop_time, timezone_str),
            )

        conn.commit()
    finally:
        conn.close()

    if reconnected:
        from backend.services.notifications import create_notification
        create_notification(
            user_id,
            device_id,
            "🟢 Laptop Online",
            f"{device_name} is back online and connected.",
        )

    # Check for pending commands — return them with the heartbeat response
    from backend.services.command_service import get_pending_commands
    pending = get_pending_commands(device_id)
    return _ok(commands=pending, pending_commands=pending)
