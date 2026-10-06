"""
Laptop Guardian — Misc Routes
POST /api/fcm-token                  — mobile app registers push token
POST /api/notifications/fcm-token    — Flutter alias for the above
GET  /api/status                     — legacy status check
GET  /api/health                     — cloud health probe (Railway/Render)
GET  /api/server-time                — UTC time for clock sync
GET  /api/network-info               — LAN IPs (local dev helper)
"""
import socket
import os
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify
from backend.auth import require_auth
from backend.services.notifications import register_fcm_token
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("misc", __name__, url_prefix="/api")


# ── Legacy status ─────────────────────────────────────────────────────────────

@bp.route("/status", methods=["GET"])
def status():
    return jsonify({"status": "ok", "service": "Laptop Guardian Backend", "version": "2.0"})


# ── Cloud health probe ────────────────────────────────────────────────────────

@bp.route("/health", methods=["GET"])
def health():
    """Standard health check used by Railway/Render/load-balancer probes."""
    from backend.database import get_db
    db_ok = False
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.fetchone()
        conn.close()
        db_ok = True
    except Exception as exc:
        log.warning(f"Health check DB error: {exc}")

    payload = {
        "status": "ok" if db_ok else "degraded",
        "db":     "connected" if db_ok else "error",
        "service": "Laptop Guardian API",
        "version": "2.0",
    }
    return jsonify(payload), (200 if db_ok else 503)


# ── Server time ───────────────────────────────────────────────────────────────

@bp.route("/server-time", methods=["GET"])
def server_time():
    """Return UTC timestamp so clients can detect clock skew."""
    now = datetime.now(timezone.utc)
    return jsonify({"utc": now.isoformat(), "timestamp": now.timestamp()})


# ── LAN network info (local dev helper only) ──────────────────────────────────

@bp.route("/network-info", methods=["GET"])
def network_info():
    """Return server LAN IPs — useful during local development."""
    try:
        hostname = socket.gethostname()
        addresses = []
        for info in socket.getaddrinfo(hostname, None):
            ip = info[4][0]
            if ip and not ip.startswith("127.") and ":" not in ip:
                if ip not in addresses:
                    addresses.append(ip)
        port = int(os.getenv("FLASK_PORT", 5000))
        return jsonify({
            "success": True,
            "hostname": hostname,
            "addresses": addresses,
            "port": port,
            "urls": [f"http://{ip}:{port}" for ip in addresses],
        })
    except Exception as exc:
        return jsonify({"success": False, "error": str(exc)}), 500


# ── FCM token registration ────────────────────────────────────────────────────

def _fcm_token_impl():
    """Shared handler for FCM token registration routes."""
    try:
        user = require_auth(request)
    except ValueError:
        return jsonify({"success": False, "error": "Unauthorized."}), 401

    data      = request.get_json(silent=True) or {}
    token     = (data.get("token") or data.get("fcm_token") or "").strip()
    platform  = (data.get("platform") or "android").strip()
    device_id = (data.get("device_id") or "").strip() or None

    if not token:
        return jsonify({"success": False, "error": "token required."}), 400

    register_fcm_token(user["id"], token, platform=platform, device_id=device_id)
    log.info(f"FCM token registered for user {user['id']} device={device_id} platform={platform}")
    return jsonify({"success": True, "message": "FCM token registered."})


@bp.route("/fcm-token", methods=["POST"])
def register_token():
    return _fcm_token_impl()


@bp.route("/notifications/fcm-token", methods=["POST"])
def register_notification_token():
    """Alias matching the Flutter app's expected path."""
    return _fcm_token_impl()


@bp.route("/devices/fcm-token", methods=["POST"])
def register_device_fcm_token():
    """Alias explicitly matching /api/devices/fcm-token."""
    return _fcm_token_impl()
