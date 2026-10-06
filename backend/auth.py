"""
Laptop Guardian — Authentication Helpers
Handles: password hashing, session token creation/validation, device token verification.
"""
import os
import hashlib
import secrets
import bcrypt
from datetime import datetime, timedelta
from backend.database import get_db


# ---------------------------------------------------------------------------
# Password helpers
# ---------------------------------------------------------------------------

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except Exception:
        return False


# ---------------------------------------------------------------------------
# Session token helpers
# ---------------------------------------------------------------------------

def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def create_session(user_id: int, hours: int = 720) -> str:
    """Create a new session, return the plain token (store hash in DB)."""
    token = secrets.token_urlsafe(48)
    token_hash = _hash_token(token)
    expires = datetime.utcnow() + timedelta(hours=hours)

    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO sessions (user_id, session_token_hash, expires_at) VALUES (%s, %s, %s)",
            (user_id, token_hash, expires),
        )
        conn.commit()
    finally:
        conn.close()
    return token


def get_session_user(token: str) -> dict | None:
    """Validate a session token and return the user dict, or None."""
    if not token:
        return None
    token_hash = _hash_token(token)
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT u.id, u.name, u.email
            FROM sessions s
            JOIN users u ON u.id = s.user_id
            WHERE s.session_token_hash = %s
              AND s.expires_at > UTC_TIMESTAMP()
            LIMIT 1
            """,
            (token_hash,),
        )
        return cur.fetchone()
    finally:
        conn.close()


def delete_session(token: str):
    token_hash = _hash_token(token)
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM sessions WHERE session_token_hash = %s", (token_hash,))
        conn.commit()
    finally:
        conn.close()


def token_from_request(request) -> str | None:
    """Extract bearer token from Authorization header or cookie."""
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:]
    return request.cookies.get("lg_session")


def require_auth(request):
    """Return user dict or raise ValueError."""
    token = token_from_request(request)
    user = get_session_user(token)
    if not user:
        raise ValueError("Unauthorized")
    return user


# ---------------------------------------------------------------------------
# Device token helpers
# ---------------------------------------------------------------------------

def hash_device_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
