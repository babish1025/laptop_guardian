"""
Laptop Guardian — Activity Routes
GET  /api/activity/<device_id>          — paginated activity history
POST /api/activity                       — agent reports events
GET  /api/notifications                  — user's in-app notifications
POST /api/notifications/<id>/read        — mark notification read
GET  /api/notifications/unread-count     — badge count
"""
from datetime import datetime

from flask import Blueprint, request, jsonify
from backend.database import get_db
from backend.auth import require_auth, hash_device_token
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("activity", __name__, url_prefix="/api")


def _err(msg, code=400):
    return jsonify({"success": False, "error": msg}), code


def _ok(data=None, **kwargs):
    payload = {"success": True}
    if data:
        payload.update(data)
    payload.update(kwargs)
    return jsonify(payload)


def _serialize(rows):
    from decimal import Decimal
    for r in rows:
        for k, v in r.items():
            if isinstance(v, datetime):
                r[k] = v.isoformat()
            elif isinstance(v, Decimal):
                r[k] = float(v)
    return rows


def _verify_ownership(user_id, device_id):
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM devices WHERE device_id=%s AND user_id=%s", (device_id, user_id))
        return cur.fetchone() is not None
    finally:
        conn.close()


# ── Agent Reports Event ───────────────────────────────────────────────────────

@bp.route("/activity", methods=["POST"])
def report_event():
    data         = request.get_json(silent=True) or {}
    device_id    = (data.get("device_id") or "").strip()
    device_token = (data.get("device_token") or "")
    event_type   = (data.get("event_type") or "").strip().upper()
    event_details= (data.get("event_details") or "").strip()
    laptop_time  = (data.get("laptop_time") or None)
    timezone_str = (data.get("timezone") or None)
    latitude     = data.get("latitude")
    longitude    = data.get("longitude")
    location_label = (data.get("location_label") or "").strip() or None

    ALLOWED_EVENTS = {
        "STARTUP", "SHUTDOWN", "RESTART", "LOCK", "UNLOCK",
        "SLEEP", "WAKE", "UNEXPECTED_OFFLINE", "ONLINE", "OFFLINE",
        "ALARM", "PHOTO", "SCREENSHOT", "LOCATION", "COMMAND",
    }
    if not device_id or not event_type:
        return _err("device_id and event_type required.")
    if event_type not in ALLOWED_EVENTS:
        return _err(f"Invalid event_type.")

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT user_id, device_token_hash, device_name FROM devices WHERE device_id=%s", (device_id,))
        dev = cur.fetchone()
        if not dev:
            return _err("Unknown device.", 404)
        if dev["device_token_hash"]:
            if hash_device_token(device_token) != dev["device_token_hash"]:
                return _err("Invalid device token.", 401)

        # Insert activity
        cur.execute(
            """INSERT INTO activity_logs
               (device_id, event_type, event_details, latitude, longitude, location_label,
                laptop_time, laptop_timezone)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""",
            (device_id, event_type, event_details,
             latitude, longitude, location_label,
             laptop_time, timezone_str),
        )
        conn.commit()

        # Update device status based on event
        status_map = {
            "STARTUP":  "ONLINE",
            "ONLINE":   "ONLINE",
            "SHUTDOWN": "SHUTDOWN",
            "RESTART":  "OFFLINE",
            "OFFLINE":  "OFFLINE",
            "UNEXPECTED_OFFLINE": "OFFLINE",
        }
        new_status = status_map.get(event_type)
        if new_status:
            cur.execute(
                "UPDATE devices SET status=%s, last_seen=UTC_TIMESTAMP() WHERE device_id=%s",
                (new_status, device_id),
            )
            conn.commit()

        log.info(f"Activity logged for {device_id}: {event_type} - {event_details}")

        # In-app notifications for key events
        notif_map = {
            "STARTUP":  ("🟢 Laptop Online", f"{dev['device_name']} came online."),
            "SHUTDOWN": ("🔴 Laptop Shutdown", f"{dev['device_name']} was shut down."),
            "LOCK":     ("🔒 Laptop Locked", f"{dev['device_name']} was locked."),
            "UNLOCK":   ("🔓 Laptop Unlocked", f"{dev['device_name']} was unlocked."),
            "SLEEP":    ("😴 Laptop Sleep", f"{dev['device_name']} entered sleep mode."),
            "WAKE":     ("🟢 Laptop Wake", f"{dev['device_name']} woke up from sleep."),
            "UNEXPECTED_OFFLINE": ("⚠️ Unexpected Offline", f"{dev['device_name']} lost connection unexpectedly."),
        }
        if event_type in notif_map:
            from backend.services.notifications import create_notification
            title, msg = notif_map[event_type]
            create_notification(dev["user_id"], device_id, title, msg)

        return _ok(message="Event recorded.")
    finally:
        conn.close()


# ── Activity History ──────────────────────────────────────────────────────────

@bp.route("/activity", methods=["GET"])
@bp.route("/activity/<device_id>", methods=["GET"])
def activity_history(device_id=None):
    device_id = device_id or request.args.get("device_id")
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    if not device_id:
        return _err("device_id required.")

    if not _verify_ownership(user["id"], device_id):
        return _err("Device not found or access denied.", 404)

    period = request.args.get("period", "7d")  # today/yesterday/7d/30d
    period_map = {
        "today":     "DATE(created_at) = CURDATE()",
        "yesterday": "DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)",
        "7d":        "created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)",
        "30d":       "created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)",
        "all":       "1=1",
    }
    where = period_map.get(period, period_map["7d"])
    limit = int(request.args.get("limit", 100))
    limit = min(limit, 500)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            f"""SELECT * FROM activity_logs
                WHERE device_id=%s AND {where}
                ORDER BY created_at DESC LIMIT {limit}""",
            (device_id,),
        )
        rows = _serialize(cur.fetchall())
        return _ok(activities=rows, period=period)
    finally:
        conn.close()


# ── In-App Notifications ──────────────────────────────────────────────────────

@bp.route("/notifications", methods=["GET"])
@bp.route("/notifications/in-app", methods=["GET"])
def get_notifications():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    limit = min(int(request.args.get("limit", 50)), 200)
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """SELECT * FROM notifications WHERE user_id=%s
               ORDER BY created_at DESC LIMIT %s""",
            (user["id"], limit),
        )
        rows = _serialize(cur.fetchall())
        return _ok(notifications=rows)
    finally:
        conn.close()


@bp.route("/notifications/unread-count", methods=["GET"])
def unread_count():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM notifications WHERE user_id=%s AND is_read=0", (user["id"],))
        count = cur.fetchone()[0]
        return _ok(count=count)
    finally:
        conn.close()


@bp.route("/notifications/<int:notif_id>/read", methods=["POST"])
def mark_read(notif_id):
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute(
            "UPDATE notifications SET is_read=1 WHERE id=%s AND user_id=%s",
            (notif_id, user["id"]),
        )
        conn.commit()
        return _ok(message="Marked as read.")
    finally:
        conn.close()


@bp.route("/notifications/read-all", methods=["POST"])
def mark_all_read():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("UPDATE notifications SET is_read=1 WHERE user_id=%s", (user["id"],))
        conn.commit()
        return _ok(message="All notifications marked as read.")
    finally:
        conn.close()


@bp.route("/notifications/read", methods=["POST"])
def mark_notifications_read():
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    data = request.get_json(silent=True) or {}
    notif_id = data.get("id")
    mark_all = bool(data.get("all", False))

    conn = get_db()
    try:
        cur = conn.cursor()
        if mark_all:
            cur.execute("UPDATE notifications SET is_read=1 WHERE user_id=%s", (user["id"],))
        elif notif_id:
            cur.execute("UPDATE notifications SET is_read=1 WHERE id=%s AND user_id=%s", (notif_id, user["id"]))
        else:
            return _err("id or all:true required.")
        conn.commit()
        return _ok(message="Notification(s) marked as read.")
    finally:
        conn.close()
