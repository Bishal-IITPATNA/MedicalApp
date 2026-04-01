import os
from flask import Flask
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
    
    # Register blueprints
    from app.routes import auth, patient, doctor, nurse, medical_store, lab_store, admin, appointments, notifications, payments, prescriptions, patient_history, doctor_lab_tests
    
    app.register_blueprint(auth.bp)
    app.register_blueprint(patient.bp)
    app.register_blueprint(doctor.bp)
    app.register_blueprint(nurse.bp)
    app.register_blueprint(medical_store.bp)
    app.register_blueprint(lab_store.bp)
    app.register_blueprint(admin.bp)
    app.register_blueprint(appointments.bp)
    app.register_blueprint(notifications.bp)
    app.register_blueprint(payments.bp)
    app.register_blueprint(prescriptions.bp)
    app.register_blueprint(patient_history.bp)
    app.register_blueprint(doctor_lab_tests.bp)
    
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
