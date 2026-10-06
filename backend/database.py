"""
Laptop Guardian — MySQL Connection Pool
"""
import os
import mysql.connector
from mysql.connector import pooling
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))


_pool = None


def _create_pool():
    global _pool
    if _pool is None:
        db_kwargs = {
            "pool_name": "lg_pool",
            "pool_size": int(os.getenv("DB_POOL_SIZE", 10)),
            "pool_reset_session": True,
            "host": os.getenv("DB_HOST", "127.0.0.1"),
            "port": int(os.getenv("DB_PORT", 3307)),
            "user": os.getenv("DB_USER", "root"),
            "password": os.getenv("DB_PASSWORD", ""),
            "database": os.getenv("DB_NAME", "laptop_guardian"),
            "charset": "utf8mb4",
            "collation": "utf8mb4_general_ci",
            "autocommit": False,
        }
        ssl_ca = os.getenv("DB_SSL_CA")
        if ssl_ca and os.path.exists(ssl_ca):
            db_kwargs["ssl_ca"] = ssl_ca
        elif os.getenv("DB_SSL", "").lower() in ("true", "1", "required"):
            db_kwargs["ssl_disabled"] = False
        _pool = pooling.MySQLConnectionPool(**db_kwargs)
    return _pool


def get_db():
    """Get a connection from the pool. Caller must close it."""
    return _create_pool().get_connection()


class DatabaseError(Exception):
    """Raised when a database operation fails."""
    pass
