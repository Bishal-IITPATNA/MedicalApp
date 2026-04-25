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
    
    # Configure CORS with explicit origins for production
    # Note: Avoid fnmatch wildcards (e.g. "http://localhost:*") in Flask-CORS 4.x
    # as they can break origin matching for all origins including production.
    # Allow any *.emergentagent.com preview/production URL plus localhost dev
    public_url = os.environ.get('APP_PUBLIC_URL', '').rstrip('/')
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

    # Use a regex to match any *.emergentagent.com (preview & prod deployments)
    CORS(app,
         resources={r"/*": {"origins": cors_origins + [r"https://.*\.emergentagent\.com"]}},
         supports_credentials=True,
         allow_headers=['Content-Type', 'Authorization'],
         expose_headers=['Content-Type', 'Authorization'],
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
         max_age=600)

    def _origin_allowed(origin: str) -> bool:
        if not origin:
            return False
        if origin in cors_origins:
            return True
        if origin.endswith('.emergentagent.com'):
            return True
        return False

    @app.after_request
    def after_request(response):
        origin = request.headers.get('Origin')
        if _origin_allowed(origin):
            response.headers['Access-Control-Allow-Origin'] = origin
            response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
            response.headers['Access-Control-Allow-Methods'] = 'GET,PUT,POST,DELETE,OPTIONS'
            response.headers['Access-Control-Allow-Credentials'] = 'true'
        return response

    @app.before_request
    def handle_preflight():
        if request.method == "OPTIONS":
            response = make_response()
            origin = request.headers.get('Origin')
            if _origin_allowed(origin):
                response.headers['Access-Control-Allow-Origin'] = origin
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
                response.headers['Access-Control-Allow-Methods'] = 'GET,PUT,POST,DELETE,OPTIONS'
                response.headers['Access-Control-Allow-Credentials'] = 'true'
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
    @app.route('/api/health')
    def health_check():
        """Health check endpoint with detailed environment info"""
        import sys
        is_production = 'WEBSITE_SITE_NAME' in os.environ or app.config.get('ENV') == 'production'
        
        # Get environment information
        env_info = {
            'python_version': sys.version,
            'website_site_name': os.environ.get('WEBSITE_SITE_NAME', 'Not set'),
            'website_hostname': os.environ.get('WEBSITE_HOSTNAME', 'Not set'),
            'pythonpath': sys.path[:3] if len(sys.path) > 3 else sys.path,  # First few paths only
            'working_directory': os.getcwd(),
            'environment': 'production' if is_production else 'development'
        }
        
        return {
            'status': 'healthy',
            'message': 'Seevak Care Medical App Backend is running',
            'version': '1.0.0',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'environment_info': env_info if not is_production else None  # Only show in dev
        }
    
    # Add simple API test endpoint
    @app.route('/api/test')
    def api_test():
        """Simple API test endpoint"""
        return {'message': 'API is working', 'timestamp': datetime.utcnow().isoformat() + 'Z'}
        
    # Add error handlers
    @app.errorhandler(500)
    def internal_error(error):
        return {'error': 'Internal server error', 'message': 'Something went wrong'}, 500
        
    @app.errorhandler(404)
    def not_found(error):
        return {'error': 'Not found', 'message': 'The requested resource was not found'}, 404
    
    return app
