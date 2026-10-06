"""
Laptop Guardian — Command Service Helper
Used by heartbeat route to return pending commands inline.
"""
from datetime import datetime
from backend.database import get_db


def get_pending_commands(device_id: str) -> list[dict]:
    """Return and mark-received any pending non-expired commands for a device."""
    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        # Expire stale commands first
        cur.execute(
            """UPDATE commands SET status='EXPIRED'
               WHERE device_id=%s AND status='PENDING' AND expires_at < UTC_TIMESTAMP()""",
            (device_id,),
        )
        conn.commit()

        cur.execute(
            """SELECT id, command, created_at, expires_at FROM commands
               WHERE device_id=%s AND status='PENDING'
               ORDER BY created_at ASC""",
            (device_id,),
        )
        rows = cur.fetchall()
        ids = [r["id"] for r in rows]
        if ids:
            placeholders = ",".join(["%s"] * len(ids))
            cur.execute(f"UPDATE commands SET status='RECEIVED' WHERE id IN ({placeholders})", ids)
            conn.commit()

        for r in rows:
            for k, v in r.items():
                if isinstance(v, datetime):
                    r[k] = v.isoformat()
            r["action"] = r.get("command")
        return rows
    finally:
        conn.close()
