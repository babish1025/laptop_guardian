"""
Laptop Guardian — Notification Service

Handles two notification channels:
1. In-app notifications (always active) — stored in DB, polled by dashboard
2. Firebase Cloud Messaging (FCM) — modern Firebase Admin SDK (HTTP v1) with legacy fallback
"""
import os
import json
import logging

from backend.database import get_db

log = logging.getLogger("laptop_guardian.backend")

FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "").strip()
FCM_LEGACY_URL = "https://fcm.googleapis.com/fcm/send"

_firebase_app = None
_firebase_initialized = False


def _init_firebase_admin():
    """Lazily initialize Firebase Admin SDK using credentials file or env JSON."""
    global _firebase_app, _firebase_initialized
    if _firebase_initialized:
        return _firebase_app
    _firebase_initialized = True
    try:
        import firebase_admin
        from firebase_admin import credentials

        # 1. Environment variable pointing to service account file
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "").strip()
        # 2. Raw JSON string in env
        cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
        # 3. Default file in project root
        project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        default_file = os.path.join(project_root, "serviceAccountKey.json")

        cred = None
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            log.info(f"Loaded Firebase credentials from: {cred_path}")
        elif cred_json:
            try:
                cert_dict = json.loads(cred_json)
                cred = credentials.Certificate(cert_dict)
                log.info("Loaded Firebase credentials from FIREBASE_SERVICE_ACCOUNT_JSON.")
            except Exception as e:
                log.error(f"Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: {e}")
        elif os.path.exists(default_file):
            cred = credentials.Certificate(default_file)
            log.info(f"Loaded Firebase credentials from default file: {default_file}")

        if cred:
            if not firebase_admin._apps:
                _firebase_app = firebase_admin.initialize_app(cred)
            else:
                _firebase_app = firebase_admin.get_app()
            log.info("Firebase Admin SDK initialized successfully.")
    except Exception as e:
        log.warning(f"Firebase Admin SDK initialization skipped: {e}")
    return _firebase_app


# ---------------------------------------------------------------------------
# In-App Notification (always works)
# ---------------------------------------------------------------------------

def create_notification(user_id: int, device_id: str, title: str, message: str):
    """Store a notification in the DB for dashboard/polling and trigger FCM."""
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO notifications (user_id, device_id, title, message)
               VALUES (%s, %s, %s, %s)""",
            (user_id, device_id, title, message),
        )
        conn.commit()
        notif_id = cur.lastrowid
        log.info(f"Notification created [ID {notif_id}] for user {user_id} - {title}")

        # Attempt FCM push
        _send_fcm_to_user(user_id, title, message, device_id)

    except Exception as e:
        log.error(f"Failed to create notification: {e}")
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# FCM Push Notifications
# ---------------------------------------------------------------------------

def _send_fcm_to_user(user_id: int, title: str, body: str, device_id: str = ""):
    """Send FCM push to all tokens registered for this user."""
    tokens = _get_fcm_tokens(user_id)
    if not tokens:
        log.debug(f"No FCM tokens for user {user_id}; skipping push.")
        return

    for token in tokens:
        _send_fcm(token, title, body, {"device_id": str(device_id or "")})


def _get_fcm_tokens(user_id: int) -> list[str]:
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT token FROM notification_tokens WHERE user_id=%s", (user_id,))
        return [row[0] for row in cur.fetchall()]
    except Exception as e:
        log.error(f"Error querying FCM tokens: {e}")
        return []
    finally:
        conn.close()


def _remove_fcm_token(token: str):
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM notification_tokens WHERE token=%s", (token,))
        conn.commit()
        log.info(f"Removed stale FCM token: ...{token[-8:]}")
    except Exception as e:
        log.warning(f"Failed to remove stale FCM token: {e}")
    finally:
        conn.close()


def _send_fcm(token: str, title: str, body: str, data: dict = None):
    """Send a single FCM message using Firebase Admin SDK or legacy HTTP fallback."""
    data = data or {}
    str_data = {str(k): str(v) for k, v in data.items()}

    # 1. Primary: Firebase Admin SDK (HTTP v1)
    app = _init_firebase_admin()
    if app:
        try:
            from firebase_admin import messaging
            msg = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=str_data,
                token=token,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="laptop_guardian_alerts",
                        priority="max",
                        default_sound=True,
                    ),
                ),
            )
            resp = messaging.send(msg)
            log.info(f"FCM v1 message sent successfully to ...{token[-8:]}: {resp}")
            return
        except Exception as e:
            err_str = str(e)
            log.warning(f"Firebase Admin SDK send error: {err_str}")
            if "Requested entity was not found" in err_str or "registration-token-not-registered" in err_str:
                _remove_fcm_token(token)
            return

    # 2. Secondary fallback: Legacy FCM server key if configured
    if FCM_SERVER_KEY:
        try:
            import requests
            headers = {
                "Authorization": f"key={FCM_SERVER_KEY}",
                "Content-Type": "application/json",
            }
            payload = {
                "to": token,
                "notification": {"title": title, "body": body},
                "data": str_data,
                "priority": "high",
            }
            resp = requests.post(FCM_LEGACY_URL, headers=headers, json=payload, timeout=10)
            if resp.status_code == 200:
                result = resp.json()
                if result.get("failure", 0) > 0:
                    log.warning(f"Legacy FCM delivery failed for token ...{token[-8:]}: {result}")
                else:
                    log.info(f"Legacy FCM push sent successfully to token ...{token[-8:]}")
            else:
                log.error(f"Legacy FCM HTTP error {resp.status_code}: {resp.text[:200]}")
        except Exception as e:
            log.error(f"Legacy FCM send error: {e}")


# ---------------------------------------------------------------------------
# FCM Token Registration
# ---------------------------------------------------------------------------

def register_fcm_token(user_id: int, token: str, platform: str = "android", device_id: str = None):
    """Register or refresh an FCM token for a user."""
    conn = get_db()
    try:
        cur = conn.cursor()
        # Check if device_id column exists
        cur.execute(
            """SELECT COUNT(*) FROM information_schema.columns 
               WHERE table_schema = DATABASE() AND table_name = 'notification_tokens' AND column_name = 'device_id'"""
        )
        has_device_col = cur.fetchone()[0] > 0

        if has_device_col and device_id:
            cur.execute(
                """INSERT INTO notification_tokens (user_id, token, platform, device_id)
                   VALUES (%s, %s, %s, %s)
                   ON DUPLICATE KEY UPDATE user_id=%s, platform=%s, device_id=%s, updated_at=NOW()""",
                (user_id, token, platform, device_id, user_id, platform, device_id),
            )
        else:
            cur.execute(
                """INSERT INTO notification_tokens (user_id, token, platform)
                   VALUES (%s, %s, %s)
                   ON DUPLICATE KEY UPDATE user_id=%s, platform=%s, updated_at=NOW()""",
                (user_id, token, platform, user_id, platform),
            )
        conn.commit()
        log.info(f"FCM token registered for user {user_id} (platform={platform}, device={device_id})")
    finally:
        conn.close()
