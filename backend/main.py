"""
Simple startup script for Azure App Service
"""

import os
import sys

# Ensure current directory is in Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# Import and create Flask app
from app import create_app

app = create_app()
application = app  # WSGI server expects 'application'

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)

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
