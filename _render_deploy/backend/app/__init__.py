import os
from datetime import datetime
from flask import Flask, request, make_response
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_migrate import Migrate
from config import Config

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    # ------------------------------------------------------------------
    # CORS
    # Allow:
    #   - APP_PUBLIC_URL (set per environment)
    #   - any *.onrender.com  (Render)
    #   - any *.emergentagent.com  (Emergent preview / production)
    #   - localhost dev ports
    # ------------------------------------------------------------------
    public_url = (os.environ.get("APP_PUBLIC_URL") or "").rstrip("/")
    cors_origins = [
        public_url,
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ]
    cors_origins = [o for o in cors_origins if o]

    cors_regex_origins = [
        r"https://.*\.onrender\.com",
        r"https://.*\.emergentagent\.com",
    ]

    CORS(
        app,
        resources={r"/*": {"origins": cors_origins + cors_regex_origins}},
        supports_credentials=True,
        allow_headers=["Content-Type", "Authorization"],
        expose_headers=["Content-Type", "Authorization"],
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        max_age=600,
    )

    def _origin_allowed(origin: str) -> bool:
        if not origin:
            return False
        if origin in cors_origins:
            return True
        if origin.endswith(".onrender.com") or origin.endswith(".emergentagent.com"):
            return True
        return False

    @app.after_request
    def after_request(response):
        origin = request.headers.get("Origin")
        if _origin_allowed(origin):
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
            response.headers["Access-Control-Allow-Methods"] = "GET,PUT,POST,DELETE,OPTIONS"
            response.headers["Access-Control-Allow-Credentials"] = "true"
        return response

    @app.before_request
    def handle_preflight():
        if request.method == "OPTIONS":
            response = make_response()
            origin = request.headers.get("Origin")
            if _origin_allowed(origin):
                response.headers["Access-Control-Allow-Origin"] = origin
                response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
                response.headers["Access-Control-Allow-Methods"] = "GET,PUT,POST,DELETE,OPTIONS"
                response.headers["Access-Control-Allow-Credentials"] = "true"
            return response

    # ------------------------------------------------------------------
    # Blueprints
    # ------------------------------------------------------------------
    from app.routes.auth import bp as auth_bp
    from app.routes.patient import bp as patient_bp
    from app.routes.doctor import bp as doctor_bp
    from app.routes.nurse import bp as nurse_bp
    from app.routes.medical_store import bp as medical_store_bp
    from app.routes.lab_store import bp as lab_store_bp
    from app.routes.admin import bp as admin_bp
    from app.routes.appointments import bp as appointments_bp
    from app.routes.notifications import bp as notifications_bp
    from app.routes.payments import bp as payments_bp
    from app.routes.prescriptions import bp as prescriptions_bp
    from app.routes.patient_history import bp as patient_history_bp
    from app.routes.doctor_lab_tests import bp as doctor_lab_tests_bp

    for bp in (
        auth_bp,
        patient_bp,
        doctor_bp,
        nurse_bp,
        medical_store_bp,
        lab_store_bp,
        admin_bp,
        appointments_bp,
        notifications_bp,
        payments_bp,
        prescriptions_bp,
        patient_history_bp,
        doctor_lab_tests_bp,
    ):
        app.register_blueprint(bp)

    # ------------------------------------------------------------------
    # Health check
    # ------------------------------------------------------------------
    @app.route("/")
    @app.route("/health")
    @app.route("/api/health")
    def health_check():
        return {
            "status": "healthy",
            "service": "Seevak Care backend",
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    @app.route("/api/test")
    def api_test():
        return {"message": "API is working", "timestamp": datetime.utcnow().isoformat() + "Z"}

    @app.errorhandler(500)
    def internal_error(_):
        return {"error": "Internal server error"}, 500

    @app.errorhandler(404)
    def not_found(_):
        return {"error": "Not found"}, 404

    # ------------------------------------------------------------------
    # First-boot bootstrap: create tables and (optionally) seed default
    # users so a brand-new Render deployment is usable out of the box.
    # ------------------------------------------------------------------
    with app.app_context():
        try:
            db.create_all()
            if os.environ.get("SEED_DEFAULT_USERS", "false").lower() == "true":
                try:
                    from seed_default_users import seed  # local module
                    seed()
                except Exception as exc:  # pragma: no cover
                    app.logger.warning("Seed step skipped/failed: %s", exc)
        except Exception as exc:  # pragma: no cover
            app.logger.exception("DB bootstrap failed: %s", exc)

    return app
