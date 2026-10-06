"""
Laptop Guardian — Auth Routes
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET  /api/auth/me
"""
from flask import Blueprint, request, jsonify
from backend.database import get_db
from backend.auth import (
    hash_password, verify_password,
    create_session, delete_session,
    token_from_request, get_session_user,
)
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")
bp = Blueprint("auth", __name__, url_prefix="/api/auth")


def _err(msg, code=400):
    return jsonify({"success": False, "error": msg}), code


def _ok(data=None, **kwargs):
    payload = {"success": True}
    if data:
        payload.update(data)
    payload.update(kwargs)
    return jsonify(payload)


# ── Register ────────────────────────────────────────────────────────────────

@bp.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    name  = (data.get("name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    pwd   = (data.get("password") or "")

    if not name or not email or not pwd:
        return _err("name, email, and password are required.")
    if len(pwd) < 8:
        return _err("Password must be at least 8 characters.")
    if "@" not in email:
        return _err("Invalid email address.")

    pw_hash = hash_password(pwd)
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            return _err("Email already registered.", 409)
        cur.execute(
            "INSERT INTO users (name, email, password_hash) VALUES (%s, %s, %s)",
            (name, email, pw_hash),
        )
        conn.commit()
        user_id = cur.lastrowid
        log.info(f"User registered successfully: id={user_id}, email={email}")
        token = create_session(user_id)
        resp = _ok({"token": token, "user": {"id": user_id, "name": name, "email": email}})
        resp.set_cookie("lg_session", token, httponly=True, samesite="Lax", path="/", max_age=30*24*3600)
        return resp, 201
    finally:
        conn.close()


# ── Login ────────────────────────────────────────────────────────────────────

@bp.route("/login", methods=["POST"])
def login():
    data  = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    pwd   = (data.get("password") or "")

    if not email or not pwd:
        return _err("email and password are required.")

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT id, name, email, password_hash FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
    finally:
        conn.close()

    if not user or not verify_password(pwd, user["password_hash"]):
        log.warning(f"Invalid password for user: {email}")
        return _err("Invalid email or password.", 401)

    log.info(f"User authenticated successfully: {email}")
    token = create_session(user["id"])
    resp = _ok({"token": token, "user": {"id": user["id"], "name": user["name"], "email": user["email"]}})
    resp.set_cookie("lg_session", token, httponly=True, samesite="Lax", path="/", max_age=30*24*3600)
    return resp


# ── Logout ───────────────────────────────────────────────────────────────────

@bp.route("/logout", methods=["POST"])
def logout():
    token = token_from_request(request)
    if token:
        delete_session(token)
    resp = _ok({"message": "Logged out."})
    resp.delete_cookie("lg_session")
    return resp


# ── Me ───────────────────────────────────────────────────────────────────────

@bp.route("/me", methods=["GET"])
def me():
    token = token_from_request(request)
    user = get_session_user(token)
    if not user:
        return _err("Not authenticated.", 401)
    return _ok({"user": user})
