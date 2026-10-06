"""
Laptop Guardian — Database Migration Script
Safely adds missing columns and tables to the existing laptop_guardian DB.
Run once: python migrate.py
Idempotent: safe to run multiple times.
"""
import sys
import os

# Allow running from project root
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

import mysql.connector
from utils.logging_config import get_logger

log = get_logger("migrate", "backend.log")


def get_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", 3307)),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "laptop_guardian"),
        autocommit=True,
    )


def column_exists(cursor, table, column):
    cursor.execute(
        "SELECT COUNT(*) FROM information_schema.columns "
        "WHERE table_schema = DATABASE() AND table_name = %s AND column_name = %s",
        (table, column),
    )
    return cursor.fetchone()[0] > 0


def table_exists(cursor, table):
    cursor.execute(
        "SELECT COUNT(*) FROM information_schema.tables "
        "WHERE table_schema = DATABASE() AND table_name = %s",
        (table,),
    )
    return cursor.fetchone()[0] > 0


def add_column_if_missing(cursor, table, column, definition):
    if not column_exists(cursor, table, column):
        cursor.execute(f"ALTER TABLE `{table}` ADD COLUMN `{column}` {definition}")
        log.info(f"Added column: {table}.{column}")
    else:
        log.info(f"Column already exists (skipped): {table}.{column}")


def run_migration():
    log.info("Starting database migration...")
    conn = get_connection()
    cursor = conn.cursor()

    # ----------------------------------------------------------------
    # 1. Augment `devices` table
    # ----------------------------------------------------------------
    add_column_if_missing(cursor, "devices", "ip_address", "VARCHAR(45) NULL DEFAULT NULL AFTER `username`")
    add_column_if_missing(cursor, "devices", "timezone", "VARCHAR(100) NULL DEFAULT NULL AFTER `ip_address`")
    add_column_if_missing(cursor, "devices", "manufacturer", "VARCHAR(150) NULL DEFAULT NULL AFTER `gpu`")
    add_column_if_missing(cursor, "devices", "model", "VARCHAR(150) NULL DEFAULT NULL AFTER `manufacturer`")

    # ----------------------------------------------------------------
    # 2. Augment `commands` table
    # ----------------------------------------------------------------
    add_column_if_missing(cursor, "commands", "user_id", "INT(11) NULL DEFAULT NULL AFTER `device_id`")
    add_column_if_missing(cursor, "commands", "result", "TEXT NULL DEFAULT NULL AFTER `executed_at`")
    add_column_if_missing(cursor, "commands", "expires_at", "DATETIME NULL DEFAULT NULL AFTER `result`")

    # ----------------------------------------------------------------
    # 3. Augment `activity_logs` table — add location snapshot
    # ----------------------------------------------------------------
    add_column_if_missing(cursor, "activity_logs", "latitude", "DECIMAL(10,7) NULL DEFAULT NULL AFTER `event_details`")
    add_column_if_missing(cursor, "activity_logs", "longitude", "DECIMAL(10,7) NULL DEFAULT NULL AFTER `latitude`")
    add_column_if_missing(cursor, "activity_logs", "location_label", "VARCHAR(200) NULL DEFAULT NULL AFTER `longitude`")
    add_column_if_missing(cursor, "activity_logs", "laptop_time", "DATETIME NULL DEFAULT NULL AFTER `location_label`")
    add_column_if_missing(cursor, "activity_logs", "laptop_timezone", "VARCHAR(100) NULL DEFAULT NULL AFTER `laptop_time`")

    # ----------------------------------------------------------------
    # 4. Create `locations` table
    # ----------------------------------------------------------------
    if not table_exists(cursor, "locations"):
        cursor.execute("""
            CREATE TABLE `locations` (
                `id`           INT(11) NOT NULL AUTO_INCREMENT,
                `device_id`    VARCHAR(32) NOT NULL,
                `latitude`     DECIMAL(10,7) NOT NULL,
                `longitude`    DECIMAL(10,7) NOT NULL,
                `accuracy`     FLOAT NULL DEFAULT NULL,
                `source`       ENUM('GPS','WIFI','IP','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
                `city`         VARCHAR(150) NULL DEFAULT NULL,
                `state`        VARCHAR(150) NULL DEFAULT NULL,
                `country`      VARCHAR(100) NULL DEFAULT NULL,
                `is_approximate` TINYINT(1) NOT NULL DEFAULT 1,
                `created_at`   DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_device_id` (`device_id`),
                INDEX `idx_created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """)
        log.info("Created table: locations")
    else:
        log.info("Table already exists (skipped): locations")

    # ----------------------------------------------------------------
    # 5. Create `notification_tokens` table (FCM)
    # ----------------------------------------------------------------
    if not table_exists(cursor, "notification_tokens"):
        cursor.execute("""
            CREATE TABLE `notification_tokens` (
                `id`         INT(11) NOT NULL AUTO_INCREMENT,
                `user_id`    INT(11) NOT NULL,
                `token`      VARCHAR(255) NOT NULL,
                `platform`   VARCHAR(20) NOT NULL DEFAULT 'android',
                `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uq_token` (`token`),
                INDEX `idx_user_id` (`user_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """)
        log.info("Created table: notification_tokens")
    else:
        log.info("Table already exists (skipped): notification_tokens")
    add_column_if_missing(cursor, "notification_tokens", "device_id", "VARCHAR(32) NULL DEFAULT NULL AFTER `user_id`")

    # ----------------------------------------------------------------
    # 6. Create `heartbeats` table (detailed heartbeat log)
    # ----------------------------------------------------------------
    if not table_exists(cursor, "heartbeats"):
        cursor.execute("""
            CREATE TABLE `heartbeats` (
                `id`         INT(11) NOT NULL AUTO_INCREMENT,
                `device_id`  VARCHAR(32) NOT NULL,
                `battery`    INT(3) NULL DEFAULT NULL,
                `charging`   TINYINT(1) NOT NULL DEFAULT 0,
                `ip_address` VARCHAR(45) NULL DEFAULT NULL,
                `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_device_id` (`device_id`),
                INDEX `idx_created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """)
        log.info("Created table: heartbeats")
    else:
        log.info("Table already exists (skipped): heartbeats")

    # ----------------------------------------------------------------
    # 7. Add pairing_code to devices for the new pairing flow
    # ----------------------------------------------------------------
    if not table_exists(cursor, "pairing_codes"):
        cursor.execute("""
            CREATE TABLE `pairing_codes` (
                `id`         INT(11) NOT NULL AUTO_INCREMENT,
                `user_id`    INT(11) NOT NULL,
                `code`       VARCHAR(20) NOT NULL,
                `used`       TINYINT(1) NOT NULL DEFAULT 0,
                `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `expires_at` DATETIME NOT NULL,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uq_code` (`code`),
                INDEX `idx_user_id` (`user_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """)
        log.info("Created table: pairing_codes")
    else:
        log.info("Table already exists (skipped): pairing_codes")

    # ----------------------------------------------------------------
    # 8. Unify table collations to prevent "Illegal mix of collations"
    # ----------------------------------------------------------------
    all_tables = ["devices", "locations", "heartbeats", "activity_logs", "commands",
                  "notifications", "notification_tokens", "pairing_codes", "sessions", "users"]
    for t in all_tables:
        if table_exists(cursor, t):
            try:
                cursor.execute(f"ALTER TABLE `{t}` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
            except Exception as e:
                log.warning(f"Could not convert collation for {t}: {e}")

    cursor.close()
    conn.close()
    log.info("Migration complete.")
    print("\n[OK] Migration completed successfully!")


if __name__ == "__main__":
    run_migration()
