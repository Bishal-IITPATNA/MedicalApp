"""
Minimal WSGI entry point for Azure App Service  
"""

import os
import sys

# Add current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

# Import Flask app factory
from app import create_app

# Create application instance
application = create_app()

if __name__ == "__main__":
    port = int(os.environ.get('PORT', 8000))
    application.run(host='0.0.0.0', port=port, debug=False)

# For backward compatibility
app = application

if __name__ == "__main__":
    application.run()
