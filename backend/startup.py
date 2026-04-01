#!/usr/bin/env python3
"""
Azure App Service startup file for Medical App Flask Backend
This file is used by Azure App Service to start the Flask application
"""

import os
import sys
from app import create_app

# Create Flask application instance
# Routes (/, /health) are defined inside create_app() in app/__init__.py
app = create_app()

# Ensure we're using the correct port for Azure
port = int(os.environ.get('PORT', 8000))
host = os.environ.get('HOST', '0.0.0.0')

# Database initialization function for Azure
@app.cli.command()
def init_db():
    """Initialize the database."""
    from app import db
    db.create_all()
    print('Database initialized successfully!')

if __name__ == '__main__':
    print(f"Starting Medical App Backend on {host}:{port}")
    # For Azure App Service, we need to bind to all interfaces
    app.run(
        host=host,
        port=port,
        debug=False,  # Always False in production
        use_reloader=False,  # Disable reloader in production
        threaded=True  # Enable threading for better performance
    )
