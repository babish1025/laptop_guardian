"""
Laptop Guardian — Main Flask Application
"""
import os
import sys

# Ensure project root is on the path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))

from flask import Flask, render_template, redirect, url_for, request, jsonify, send_from_directory
from flask_cors import CORS
from utils.logging_config import get_logger

log = get_logger("backend", "backend.log")

# ── Create App ───────────────────────────────────────────────────────────────

def create_app() -> Flask:
    template_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "frontend", "templates")
    static_dir   = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "frontend", "static")

    app = Flask(__name__, template_folder=template_dir, static_folder=static_dir)
    app.secret_key = os.getenv("SECRET_KEY", "change_me_in_production")

    # CORS configuration — support explicit CORS_ORIGINS or development dynamic origin
    cors_origins_env = os.getenv("CORS_ORIGINS", "").strip()
    if cors_origins_env and cors_origins_env != "*":
        allowed_origins = [o.strip() for o in cors_origins_env.split(",") if o.strip()]
        CORS(app, supports_credentials=True, origins=allowed_origins)
    else:
        # Development / permissive mode with credentials support
        CORS(app, supports_credentials=True, origins=lambda origin: True)

    # ── Register API Blueprints ───────────────────────────────────────────────
    from backend.routes.auth_routes      import bp as auth_bp
    from backend.routes.device_routes    import bp as device_bp
    from backend.routes.heartbeat_routes import bp as hb_bp
    from backend.routes.command_routes   import bp as cmd_bp
    from backend.routes.activity_routes  import bp as act_bp
    from backend.routes.location_routes  import bp as loc_bp
    from backend.routes.misc_routes      import bp as misc_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(device_bp)
    app.register_blueprint(hb_bp)
    app.register_blueprint(cmd_bp)
    app.register_blueprint(act_bp)
    app.register_blueprint(loc_bp)
    app.register_blueprint(misc_bp)

    # ── Frontend Routes ───────────────────────────────────────────────────────

    @app.route("/")
    def index():
        return render_template("index.html")

    @app.route("/login")
    def login_page():
        return render_template("login.html")

    @app.route("/register")
    def register_page():
        return render_template("register.html")

    @app.route("/activity")
    def activity_page():
        return render_template("activity.html")

    @app.route("/pair")
    def pair_page():
        return render_template("pair.html")

    # ── Error Handlers ────────────────────────────────────────────────────────

    @app.errorhandler(404)
    def not_found(e):
        if request.path.startswith("/api/"):
            return jsonify({"success": False, "error": "Not found."}), 404
        return render_template("login.html"), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"success": False, "error": "Method not allowed."}), 405

    @app.errorhandler(500)
    def internal_error(e):
        log.error(f"Internal server error: {e}")
        if request.path.startswith("/api/"):
            return jsonify({"success": False, "error": "Internal server error."}), 500
        return render_template("login.html"), 500

    # ── Start Watchdog (works under both dev and gunicorn) ────────────────────
    # Guard with an env flag so we only start one watchdog even if gunicorn
    # spawns multiple workers (each worker would otherwise start its own thread).
    if os.getenv("WERKZEUG_RUN_MAIN") != "false":
        _start_watchdog_once()

    return app


_watchdog_started = False

def _start_watchdog_once():
    """Start the watchdog daemon thread exactly once per process."""
    global _watchdog_started
    if not _watchdog_started:
        from backend.services.watchdog import start_watchdog
        start_watchdog()
        _watchdog_started = True


# ── Module-level app instance (for gunicorn: gunicorn "backend.app:app") ──────

app = create_app()

# ── Dev server entry point ───────────────────────────────────────────────────

if __name__ == "__main__":
    host  = os.getenv("FLASK_HOST", "0.0.0.0")
    port  = int(os.getenv("PORT", os.getenv("FLASK_PORT", 5000)))
    debug = os.getenv("FLASK_ENV", "development") == "development"
    log.info(f"Starting Laptop Guardian backend on {host}:{port}")
    app.run(host=host, port=port, debug=debug, use_reloader=False)
