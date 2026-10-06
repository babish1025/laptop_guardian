"""
Laptop Guardian — Command Routes
POST /api/commands                  — issue command (authenticated user)
GET  /api/commands/<device_id>      — poll pending commands (agent)
POST /api/commands/<id>/result      — agent reports command result
GET  /api/commands/history/<device_id> — command history (user)
"""
import os
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify
from backend.database import get_db
from backend.auth import require_auth, hash_device_token
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("commands", __name__, url_prefix="/api/commands")

ALLOWED_COMMANDS = {
    "SHUTDOWN", "RESTART", "LOCK",
    "ALARM", "PHOTO", "SCREENSHOT", "SLEEP", "LOCATION"
}
EXPIRY_MINUTES = int(os.getenv("COMMAND_EXPIRY_MINUTES", 5))


def _err(msg, code=400):
    return jsonify({"success": False, "error": msg}), code


def _ok(data=None, **kwargs):
    payload = {"success": True}
    if data:
        payload.update(data)
    payload.update(kwargs)
    return jsonify(payload)


def _verify_ownership(user_id: int, device_id: str) -> bool:
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM devices WHERE device_id=%s AND user_id=%s", (device_id, user_id))
        return cur.fetchone() is not None
    finally:
        conn.close()


# ── Issue Command ─────────────────────────────────────────────────────────────

@bp.route("", methods=["POST"])
def issue_command():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    data      = request.get_json(silent=True) or {}
    device_id = (data.get("device_id") or "").strip()
    command   = (data.get("command") or data.get("action") or "").strip().upper()

    if not device_id or not command:
        return _err("device_id and command (or action) are required.")
    if command not in ALLOWED_COMMANDS:
        return _err(f"Invalid command. Allowed: {', '.join(ALLOWED_COMMANDS)}")

    # SECURITY: verify the user owns this device
    if not _verify_ownership(user["id"], device_id):
        log.warning(f"Unauthorized command attempt by user {user['id']} on device {device_id}")
        return _err("Device not found or access denied.", 403)

    # Check device is online
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT status, device_name FROM devices WHERE device_id=%s", (device_id,))
        dev = cur.fetchone()
    finally:
        conn.close()

    if not dev:
        return _err("Device not found.", 404)
    if dev["status"] not in ("ONLINE",):
        return _err(f"Cannot send command: laptop is {dev['status']}. It must be ONLINE.", 409)

    expires = datetime.utcnow() + timedelta(minutes=EXPIRY_MINUTES)

    conn = get_db()
    try:
        cur = conn.cursor()
        # Cancel any older pending commands of same type for this device
        cur.execute(
            """UPDATE commands SET status='EXPIRED'
               WHERE device_id=%s AND command=%s AND status='PENDING'""",
            (device_id, command),
        )
        cur.execute(
            """INSERT INTO commands (device_id, user_id, command, status, expires_at)
               VALUES (%s, %s, %s, 'PENDING', %s)""",
            (device_id, user["id"], command, expires),
        )
        conn.commit()
        cmd_id = cur.lastrowid
        log.info(f"{command} command created [ID {cmd_id}] for device {device_id} by user {user['id']}")
        return _ok({"command_id": cmd_id, "command": command, "expires_at": expires.isoformat()}), 201
    finally:
        conn.close()


# ── Agent Polls Pending Commands ──────────────────────────────────────────────

@bp.route("/pending/<device_id>", methods=["GET"])
def poll_commands(device_id):
    device_token = request.headers.get("X-Device-Token", "")

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        # Verify device token
        cur.execute("SELECT user_id, device_token_hash FROM devices WHERE device_id=%s", (device_id,))
        dev = cur.fetchone()
        if not dev:
            return _err("Unknown device.", 404)
        if dev["device_token_hash"]:
            if hash_device_token(device_token) != dev["device_token_hash"]:
                return _err("Invalid device token.", 401)

        # Expire old commands
        cur.execute(
            """UPDATE commands SET status='EXPIRED'
               WHERE device_id=%s AND status='PENDING' AND expires_at < UTC_TIMESTAMP()""",
            (device_id,),
        )
        conn.commit()

        # Fetch pending
        cur.execute(
            """SELECT id, command, created_at, expires_at FROM commands
               WHERE device_id=%s AND status='PENDING'
               ORDER BY created_at ASC""",
            (device_id,),
        )
        rows = cur.fetchall()
        for r in rows:
            for k, v in r.items():
                if isinstance(v, datetime):
                    r[k] = v.isoformat()
            # Mark as RECEIVED
            cur.execute("UPDATE commands SET status='RECEIVED' WHERE id=%s", (r["id"],))
        conn.commit()

        return _ok(commands=rows)
    finally:
        conn.close()


# ── Agent Reports Result ──────────────────────────────────────────────────────

@bp.route("/<int:cmd_id>/result", methods=["POST"])
@bp.route("/result", methods=["POST"])
def report_result(cmd_id=None):
    data         = request.get_json(silent=True) or {}
    cmd_id       = cmd_id or data.get("command_id") or data.get("id")
    device_id    = (data.get("device_id") or "").strip()
    device_token = (data.get("device_token") or "")
    if not device_token and "Authorization" in request.headers:
        device_token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
    status       = (data.get("status") or "").strip().upper()
    result_text  = (data.get("result") or "").strip()

    if not cmd_id:
        return _err("command_id is required.")
    if status not in ("EXECUTED", "FAILED"):
        return _err("status must be EXECUTED or FAILED.")

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        if not device_id:
            cur.execute("SELECT device_id FROM commands WHERE id=%s", (cmd_id,))
            crow = cur.fetchone()
            if crow:
                device_id = crow["device_id"]

        cur.execute("SELECT device_token_hash FROM devices WHERE device_id=%s", (device_id,))
        dev = cur.fetchone()
        if not dev:
            return _err("Unknown device.", 404)
        if dev["device_token_hash"]:
            if hash_device_token(device_token) != dev["device_token_hash"]:
                return _err("Invalid device token.", 401)

        cur.execute(
            """UPDATE commands SET status=%s, result=%s, executed_at=UTC_TIMESTAMP()
               WHERE id=%s AND device_id=%s""",
            (status, result_text, cmd_id, device_id),
        )
        conn.commit()
        log.info(f"Command result for device {device_id}: ID {cmd_id} -> {status}")

        # Log activity
        cur.execute(
            "SELECT command, user_id FROM commands WHERE id=%s", (cmd_id,)
        )
        cmd = cur.fetchone()
        if cmd:
            event_map = {
                "SHUTDOWN":   ("SHUTDOWN",   "Remote shutdown executed."),
                "RESTART":    ("RESTART",    "Remote restart executed."),
                "LOCK":       ("LOCK",       "Remote lock executed."),
                "ALARM":      ("ALARM",      "Audible alarm played on laptop speakers."),
                "PHOTO":      ("PHOTO",      result_text or "Webcam photo captured."),
                "SCREENSHOT": ("SCREENSHOT", result_text or "Desktop screenshot captured."),
                "SLEEP":      ("SLEEP",      "Laptop put into sleep mode."),
                "LOCATION":   ("LOCATION",   result_text or "Location refreshed."),
            }
            ev_type, ev_detail = event_map.get(cmd["command"], ("COMMAND", result_text))
            cur.execute(
                "INSERT INTO activity_logs (device_id, event_type, event_details) VALUES (%s,%s,%s)",
                (device_id, ev_type, ev_detail),
            )
            conn.commit()

            if status == "EXECUTED":
                from backend.services.notifications import create_notification
                icons = {
                    "SHUTDOWN": "🔴", "RESTART": "🔄", "LOCK": "🔒",
                    "ALARM": "🔔", "PHOTO": "📷", "SCREENSHOT": "📸",
                    "SLEEP": "🌙", "LOCATION": "📍"
                }
                icon = icons.get(cmd["command"], "⚙️")
                create_notification(
                    cmd["user_id"], device_id,
                    f"{icon} Laptop {cmd['command'].capitalize()}",
                    ev_detail or f"Remote {cmd['command'].lower()} was executed successfully."
                )

        return _ok(message="Result recorded.")
    finally:
        conn.close()


# ── Command History ───────────────────────────────────────────────────────────

@bp.route("/history/<device_id>", methods=["GET"])
def command_history(device_id):
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    if not _verify_ownership(user["id"], device_id):
        return _err("Device not found or access denied.", 404)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """SELECT id, command, status, result, created_at, executed_at
               FROM commands WHERE device_id=%s
               ORDER BY created_at DESC LIMIT 50""",
            (device_id,),
        )
        rows = cur.fetchall()
        for r in rows:
            for k, v in r.items():
                if isinstance(v, datetime):
                    r[k] = v.isoformat()
        return _ok(commands=rows)
    finally:
        conn.close()
