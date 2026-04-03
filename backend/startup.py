#!/usr/bin/env python3
"""
Azure App Service startup file for Medical App Flask Backend
This file is used by Azure App Service to start the Flask application
"""

import os
import sys
import logging

# Configure logging for Azure
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add current directory to Python path for module imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from app import create_app
    logger.info("Successfully imported create_app")
except Exception as e:
    logger.error(f"Failed to import create_app: {e}")
    sys.exit(1)

# Create Flask application instance for WSGI
# This must be at module level for gunicorn to find it
try:
    application = create_app()  # Use 'application' for better WSGI compatibility
    app = application  # Keep 'app' for backward compatibility
    logger.info("Flask app created successfully")
except Exception as e:
    logger.error(f"Failed to create Flask app: {e}")
    sys.exit(1)

# Azure App Service uses different environment variables
port = int(os.environ.get('PORT', os.environ.get('SERVER_PORT', 8000)))
host = os.environ.get('HOST', '0.0.0.0')

logger.info(f"Configured to run on {host}:{port}")

# Database initialization function for Azure
@application.cli.command()
def init_db():
    """Initialize the database."""
    try:
        from app import db
        with application.app_context():
            db.create_all()
        logger.info('Database initialized successfully!')
        print('Database initialized successfully!')
    except Exception as e:
        logger.error(f'Database initialization failed: {e}')
        raise

# For development/direct execution only
if __name__ == '__main__':
    logger.info(f"Starting Medical App Backend on {host}:{port}")
    print(f"Starting Medical App Backend on {host}:{port}")
    
    try:
        # For Azure App Service, we need to bind to all interfaces
        application.run(
            host=host,
            port=port,
            debug=False,  # Always False in production
            use_reloader=False,  # Disable reloader in production
            threaded=True  # Enable threading for better performance
        )
    except Exception as e:
        logger.error(f"Failed to start Flask app: {e}")
        raise
