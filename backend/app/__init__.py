import os
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
    
    # Configure CORS with explicit origins for production
    # Note: Avoid fnmatch wildcards (e.g. "http://localhost:*") in Flask-CORS 4.x
    # as they can break origin matching for all origins including production.
    cors_origins = [
        "https://seevak-care.azurestaticapps.net",           # Production custom domain
        "https://brave-smoke-045200400.6.azurestaticapps.net",  # Production default Azure SWA URL
        "http://localhost:3000",  # Flutter web dev server
        "http://127.0.0.1:3000",  # Alternative localhost
        "http://localhost:5000",  # Local Flask dev server
        "http://127.0.0.1:5000",  # Local Flask dev server (alt)
        "http://localhost:8080",  # Common alt dev port
        "http://127.0.0.1:8080",  # Common alt dev port (alt)
    ]
    
    CORS(app,
         origins=cors_origins,
         supports_credentials=True,
         allow_headers=['Content-Type', 'Authorization'],
         expose_headers=['Content-Type', 'Authorization'],
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
         max_age=600)
    
    # Manual CORS headers for Azure App Service compatibility
    @app.after_request
    def after_request(response):
        origin = request.headers.get('Origin')
        if origin in cors_origins:
            response.headers.add('Access-Control-Allow-Origin', origin)
            response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
            response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
            response.headers.add('Access-Control-Allow-Credentials', 'true')
        return response
    
    # Handle preflight requests
    @app.before_request
    def handle_preflight():
        if request.method == "OPTIONS":
            response = make_response()
            origin = request.headers.get('Origin')
            if origin in cors_origins:
                response.headers.add("Access-Control-Allow-Origin", origin)
                response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
                response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
                response.headers.add('Access-Control-Allow-Credentials', 'true')
            return response
    
    # Register blueprints - Use late imports to avoid circular imports
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
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(patient_bp)
    app.register_blueprint(doctor_bp)
    app.register_blueprint(nurse_bp)
    app.register_blueprint(medical_store_bp)
    app.register_blueprint(lab_store_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(appointments_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(payments_bp)
    app.register_blueprint(prescriptions_bp)
    app.register_blueprint(patient_history_bp)
    app.register_blueprint(doctor_lab_tests_bp)
    
    # Add health check endpoint for monitoring and troubleshooting
    @app.route('/')
    @app.route('/health')
    def health_check():
        is_production = 'WEBSITE_SITE_NAME' in os.environ or app.config.get('ENV') == 'production'
        return {
            'status': 'healthy',
            'message': 'Seevak Care Medical App Backend is running',
            'version': '1.0.0',
            'environment': 'production' if is_production else 'development'
        }
    
    return app
