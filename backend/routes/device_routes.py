"""
Laptop Guardian — Device Routes
POST /api/devices/register          — laptop agent registers/re-registers
GET  /api/devices                   — list user's devices
GET  /api/devices/<device_id>       — device detail + location + last activity
POST /api/devices/pairing-code      — generate pairing code (web user)
POST /api/devices/pair              — laptop uses pairing code (agent)
DELETE /api/devices/<device_id>     — remove device
"""
import secrets
import string
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify
from backend.database import get_db
from backend.auth import require_auth, hash_device_token
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("devices", __name__, url_prefix="/api/devices")


def _err(msg, code=400):
    return jsonify({"success": False, "error": msg}), code


def _ok(data=None, **kwargs):
    payload = {"success": True}
    if data:
        payload.update(data)
    payload.update(kwargs)
    return jsonify(payload)


def _verify_ownership(user_id: int, device_id: str) -> bool:
    """Return True if user owns the device."""
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT id FROM devices WHERE device_id = %s AND user_id = %s",
            (device_id, user_id),
        )
        return cur.fetchone() is not None
    finally:
        conn.close()


# ── Generate Pairing Code ────────────────────────────────────────────────────

@bp.route("/pairing-code", methods=["POST"])
@bp.route("/pair-code", methods=["POST"])
def generate_pairing_code():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    # Create a 6-digit numeric code
    code = "".join(secrets.choice(string.digits) for _ in range(6))
    expires = datetime.utcnow() + timedelta(minutes=15)

    conn = get_db()
    try:
        cur = conn.cursor()
        # Invalidate old unused codes for this user
        cur.execute(
            "UPDATE pairing_codes SET used=1 WHERE user_id=%s AND used=0",
            (user["id"],),
        )
        cur.execute(
            "INSERT INTO pairing_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
            (user["id"], code, expires),
        )
        conn.commit()
    finally:
        conn.close()

    return _ok({"pairing_code": code, "expires_in_minutes": 15})


# ── Register Device (agent uses pairing code) ────────────────────────────────

@bp.route("/register", methods=["POST"])
def register_device():
    data = request.get_json(silent=True) or {}
    pairing_code = (data.get("pairing_code") or "").strip()
    device_id    = (data.get("device_id") or "").strip()
    device_name  = (data.get("device_name") or "Laptop").strip()
    os_info      = (data.get("os") or "").strip()
    cpu          = (data.get("cpu") or "").strip()
    ram          = (data.get("ram") or "").strip()
    storage      = (data.get("storage") or "").strip()
    gpu          = (data.get("gpu") or "").strip()
    username     = (data.get("username") or "").strip()
    manufacturer = (data.get("manufacturer") or "").strip()
    model        = (data.get("model") or "").strip()
    device_token = (data.get("device_token") or "").strip()

    # ── Legacy path: agent can still authenticate with email+password
    email    = (data.get("email") or "").strip().lower()
    password = (data.get("password") or "")

    if not device_id:
        device_id = f"laptop_{secrets.token_hex(6)}"
    if not device_token:
        device_token = secrets.token_urlsafe(32)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        user_id = None

        # Method 1: pairing code
        if pairing_code:
            cur.execute(
                """SELECT id, user_id FROM pairing_codes
                   WHERE code=%s AND used=0 AND expires_at > UTC_TIMESTAMP()""",
                (pairing_code,),
            )
            pc = cur.fetchone()
            if not pc:
                return _err("Invalid or expired pairing code.", 400)
            user_id = pc["user_id"]
            cur.execute("UPDATE pairing_codes SET used=1 WHERE id=%s", (pc["id"],))

        # Method 2: email + password (legacy)
        elif email and password:
            cur.execute("SELECT id, password_hash FROM users WHERE email=%s", (email,))
            row = cur.fetchone()
            if not row:
                return _err("Invalid owner credentials.", 401)
            import bcrypt
            if not bcrypt.checkpw(password.encode(), row["password_hash"].encode()):
                return _err("Invalid owner credentials.", 401)
            user_id = row["id"]
        else:
            return _err("Provide pairing_code or email+password.")

        token_hash = hash_device_token(device_token) if device_token else None

        # Upsert device
        cur.execute("SELECT id FROM devices WHERE device_id=%s", (device_id,))
        existing = cur.fetchone()

        if existing:
            cur.execute(
                """UPDATE devices SET user_id=%s, device_name=%s, os=%s, cpu=%s, ram=%s,
                   storage=%s, gpu=%s, username=%s, manufacturer=%s, model=%s,
                   device_token_hash=%s, status='ONLINE', last_seen=UTC_TIMESTAMP()
                   WHERE device_id=%s""",
                (user_id, device_name, os_info, cpu, ram, storage, gpu, username,
                 manufacturer, model, token_hash, device_id),
            )
        else:
            cur.execute(
                """INSERT INTO devices
                   (user_id, device_id, device_name, os, cpu, ram, storage, gpu,
                    username, manufacturer, model, device_token_hash, status, last_seen)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'ONLINE',UTC_TIMESTAMP())""",
                (user_id, device_id, device_name, os_info, cpu, ram, storage, gpu,
                 username, manufacturer, model, token_hash),
            )

        # Log startup activity
        cur.execute(
            """INSERT INTO activity_logs (device_id, event_type, event_details)
               VALUES (%s, 'STARTUP', %s)""",
            (device_id, f"Device paired/started. User: {username}, OS: {os_info}"),
        )

        conn.commit()
        log.info(f"Device registered: {device_id} for user {user_id}")

        # Create in-app notification
        from backend.services.notifications import create_notification
        create_notification(user_id, device_id, "🟢 Laptop Started",
                           f"{device_name} came online.")

        return _ok({
            "message": "Device registered successfully.",
            "device_id": device_id,
            "device_token": device_token,
            "device": {"device_id": device_id, "device_name": device_name}
        }), 201
    finally:
        conn.close()


# ── List Devices ─────────────────────────────────────────────────────────────

@bp.route("", methods=["GET"])
def list_devices():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """SELECT d.*,
                      l.latitude, l.longitude, l.city, l.state, l.country,
                      l.source AS loc_source, l.is_approximate, l.created_at AS location_updated_at
               FROM devices d
               LEFT JOIN locations l ON l.id = (
                   SELECT id FROM locations WHERE device_id = d.device_id COLLATE utf8mb4_unicode_ci
                   ORDER BY created_at DESC LIMIT 1
               )
               WHERE d.user_id = %s
               ORDER BY d.created_at DESC""",
            (user["id"],),
        )
        devices = cur.fetchall()
        from decimal import Decimal
        # Serialize datetimes and Decimals
        for d in devices:
            for k, v in d.items():
                if isinstance(v, datetime):
                    d[k] = v.isoformat()
                elif isinstance(v, Decimal):
                    d[k] = float(v)
        return _ok({"devices": devices})
    finally:
        conn.close()


# ── Device Detail ─────────────────────────────────────────────────────────────

@bp.route("/<device_id>", methods=["GET"])
@bp.route("/<device_id>/status", methods=["GET"])
def device_detail(device_id):
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    if not _verify_ownership(user["id"], device_id):
        return _err("Device not found or access denied.", 404)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT * FROM devices WHERE device_id=%s", (device_id,))
        device = cur.fetchone()

        cur.execute(
            """SELECT * FROM locations WHERE device_id=%s
               ORDER BY created_at DESC LIMIT 1""",
            (device_id,),
        )
        location = cur.fetchone()

        cur.execute(
            """SELECT battery, charging FROM heartbeats WHERE device_id=%s
               ORDER BY created_at DESC LIMIT 1""",
            (device_id,),
        )
        hb = cur.fetchone()
        if hb:
            device["battery_level"] = hb["battery"]
            device["battery_charging"] = bool(hb["charging"])
        else:
            device["battery_level"] = None
            device["battery_charging"] = False

        cur.execute(
            """SELECT * FROM activity_logs WHERE device_id=%s
               ORDER BY created_at DESC LIMIT 10""",
            (device_id,),
        )
        activities = cur.fetchall()

        from decimal import Decimal
        # Serialize
        for k, v in device.items():
            if isinstance(v, datetime):
                device[k] = v.isoformat()
            elif isinstance(v, Decimal):
                device[k] = float(v)
        if location:
            for k, v in location.items():
                if isinstance(v, datetime):
                    location[k] = v.isoformat()
                elif isinstance(v, Decimal):
                    location[k] = float(v)
        for a in activities:
            for k, v in a.items():
                if isinstance(v, datetime):
                    a[k] = v.isoformat()
                elif isinstance(v, Decimal):
                    a[k] = float(v)

        return _ok({"device": device, "location": location, "recent_activity": activities})
    finally:
        conn.close()


# ── Remove Device ─────────────────────────────────────────────────────────────

@bp.route("/<device_id>", methods=["DELETE"])
def remove_device(device_id):
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    if not _verify_ownership(user["id"], device_id):
        return _err("Device not found or access denied.", 404)

    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM devices WHERE device_id=%s AND user_id=%s", (device_id, user["id"]))
        conn.commit()
        log.info(f"Device removed: {device_id} by user {user['id']}")
        return _ok({"message": "Device removed."})
    finally:
        conn.close()
