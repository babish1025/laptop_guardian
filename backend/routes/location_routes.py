"""
Laptop Guardian — Location Routes
POST /api/location          — agent posts location update
GET  /api/location/<device_id>  — get last location (user)
GET  /api/location/history/<device_id>  — location history
"""
from datetime import datetime

from flask import Blueprint, request, jsonify
from backend.database import get_db
from backend.auth import require_auth, hash_device_token
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("location", __name__, url_prefix="/api/location")


def _err(msg, code=400):
    return jsonify({"success": False, "error": msg}), code


def _ok(data=None, **kwargs):
    payload = {"success": True}
    if data:
        payload.update(data)
    payload.update(kwargs)
    return jsonify(payload)


def _verify_ownership(user_id, device_id):
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM devices WHERE device_id=%s AND user_id=%s", (device_id, user_id))
        return cur.fetchone() is not None
    finally:
        conn.close()


# ── Agent Posts Location ──────────────────────────────────────────────────────

@bp.route("", methods=["POST"])
def post_location():
    data         = request.get_json(silent=True) or {}
    device_id    = (data.get("device_id") or "").strip()
    device_token = (data.get("device_token") or "")
    if not device_token and "Authorization" in request.headers:
        device_token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()

    latitude     = data.get("latitude")
    longitude    = data.get("longitude")
    accuracy     = data.get("accuracy") if data.get("accuracy") is not None else data.get("accuracy_radius_km")
    source       = (data.get("source") or "UNKNOWN").strip().upper()
    city         = (data.get("city") or "").strip() or None
    state        = (data.get("state") or data.get("region") or "").strip() or None
    country      = (data.get("country") or "").strip() or None
    is_approx    = bool(data.get("is_approximate", True))

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
    if latitude is None or longitude is None:
        return _err("latitude and longitude required.")

    source = source if source in ("GPS", "WIFI", "IP", "UNKNOWN") else "UNKNOWN"

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT user_id, device_token_hash FROM devices WHERE device_id=%s", (device_id,))
        dev = cur.fetchone()
        if not dev:
            return _err("Unknown device.", 404)
        if dev["device_token_hash"]:
            if hash_device_token(device_token) != dev["device_token_hash"]:
                return _err("Invalid device token.", 401)

        cur.execute(
            """INSERT INTO locations
               (device_id, latitude, longitude, accuracy, source, city, state, country, is_approximate)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (device_id, float(latitude), float(longitude),
             float(accuracy) if accuracy is not None else None,
             source, city, state, country, int(is_approx)),
        )
        conn.commit()
        log.info(f"Location updated for {device_id}: {city}, {state} ({source})")
        return _ok(message="Location recorded.")
    finally:
        conn.close()


# ── Get Last Location (user) ──────────────────────────────────────────────────

@bp.route("/<device_id>", methods=["GET"])
def get_location(device_id):
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
            """SELECT * FROM locations WHERE device_id=%s
               ORDER BY created_at DESC LIMIT 1""",
            (device_id,),
        )
        loc = cur.fetchone()
        from decimal import Decimal
        if loc:
            for k, v in loc.items():
                if isinstance(v, datetime):
                    loc[k] = v.isoformat()
                elif isinstance(v, Decimal):
                    loc[k] = float(v)
        return _ok(location=loc)
    finally:
        conn.close()


# ── Location History ──────────────────────────────────────────────────────────

@bp.route("/history/<device_id>", methods=["GET"])
def location_history(device_id):
    try:
        user = require_auth(request)
    except ValueError:
        return _err("Unauthorized.", 401)

    if not _verify_ownership(user["id"], device_id):
        return _err("Device not found or access denied.", 404)

    limit = min(int(request.args.get("limit", 20)), 100)
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            "SELECT * FROM locations WHERE device_id=%s ORDER BY created_at DESC LIMIT %s",
            (device_id, limit),
        )
        rows = cur.fetchall()
        from decimal import Decimal
        for r in rows:
            for k, v in r.items():
                if isinstance(v, datetime):
                    r[k] = v.isoformat()
                elif isinstance(v, Decimal):
                    r[k] = float(v)
        return _ok(locations=rows)
    finally:
        conn.close()
