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
    CORS(app)
    
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
    
    return app
