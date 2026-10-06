"""
Laptop Guardian — Database Export Helper
Safely exports the existing XAMPP MySQL database schema and data to a .sql file.
Does NOT modify, reset, or delete any data in your database.

Usage:
  python scripts/export_database.py
"""
import os
import sys
import subprocess

# Ensure project root is importable
_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, _PROJECT_ROOT)

from dotenv import load_dotenv
load_dotenv(os.path.join(_PROJECT_ROOT, ".env"))

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "laptop_guardian")

OUTPUT_FILE = os.path.join(_PROJECT_ROOT, "laptop_guardian_backup.sql")

def export_db():
    print("=" * 60)
    print(" Laptop Guardian — Safe Database Exporter")
    print("=" * 60)
    print(f"Connecting to: {DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    print(f"Destination:   {OUTPUT_FILE}")
    print("-" * 60)

    # 1. Try mysqldump if available in PATH or common XAMPP paths
    xampp_paths = [
        "mysqldump",
        r"C:\xampp\mysql\bin\mysqldump.exe",
        r"D:\xampp\mysql\bin\mysqldump.exe",
    ]

    mysqldump_bin = None
    for p in xampp_paths:
        try:
            res = subprocess.run([p, "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if res.returncode == 0:
                mysqldump_bin = p
                break
        except FileNotFoundError:
            continue

    if mysqldump_bin:
        print(f"Found mysqldump binary: {mysqldump_bin}")
        cmd = [
            mysqldump_bin,
            f"--host={DB_HOST}",
            f"--port={DB_PORT}",
            f"--user={DB_USER}",
        ]
        if DB_PASS:
            cmd.append(f"--password={DB_PASS}")
        cmd.extend([
            "--routines",
            "--triggers",
            "--single-transaction",
            DB_NAME,
        ])

        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            proc = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE)

        if proc.returncode == 0:
            size = os.path.getsize(OUTPUT_FILE)
            print(f"\n[SUCCESS] Database exported successfully! ({size:,} bytes)")
            print(f"File: {OUTPUT_FILE}")
            print("\nYou can now import this file into Railway MySQL or any cloud database.")
            return
        else:
            print(f"mysqldump error: {proc.stderr.decode('utf-8', errors='ignore')}")

    # 2. Python-based fallback using pymysql
    print("\nFalling back to pure Python export (using pymysql)...")
    try:
        import pymysql
    except ImportError:
        print("pymysql is required. Run: pip install pymysql")
        return

    conn = pymysql.connect(
        host=DB_HOST,
        port=int(DB_PORT),
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )

    with conn.cursor() as cursor, open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(f"-- Laptop Guardian Database Export\n")
        f.write(f"-- Database: {DB_NAME}\n")
        f.write(f"-- Host: {DB_HOST}:{DB_PORT}\n\n")
        f.write("SET FOREIGN_KEY_CHECKS = 0;\n\n")

        cursor.execute("SHOW TABLES")
        tables = [list(row.values())[0] for row in cursor.fetchall()]

        for table in tables:
            f.write(f"-- --------------------------------------------------------\n")
            f.write(f"-- Table structure for table `{table}`\n")
            f.write(f"-- --------------------------------------------------------\n")
            cursor.execute(f"SHOW CREATE TABLE `{table}`")
            create_stmt = cursor.fetchone()["Create Table"]
            f.write(f"DROP TABLE IF EXISTS `{table}`;\n")
            f.write(f"{create_stmt};\n\n")

            cursor.execute(f"SELECT * FROM `{table}`")
            rows = cursor.fetchall()
            if rows:
                f.write(f"-- Dumping data for table `{table}`\n")
                columns = list(rows[0].keys())
                col_names = ", ".join([f"`{c}`" for c in columns])

                for row in rows:
                    vals = []
                    for c in columns:
                        v = row[c]
                        if v is None:
                            vals.append("NULL")
                        elif isinstance(v, (int, float)):
                            vals.append(str(v))
                        else:
                            clean = str(v).replace("\\", "\\\\").replace("'", "\\'")
                            vals.append(f"'{clean}'")
                    f.write(f"INSERT INTO `{table}` ({col_names}) VALUES ({', '.join(vals)});\n")
                f.write("\n")

        f.write("SET FOREIGN_KEY_CHECKS = 1;\n")

    size = os.path.getsize(OUTPUT_FILE)
    print(f"\n[SUCCESS] Export complete! ({size:,} bytes, {len(tables)} tables)")
    print(f"File: {OUTPUT_FILE}")
    print("\nThis file can be uploaded directly to Railway MySQL or any cloud database.")

if __name__ == "__main__":
    export_db()
