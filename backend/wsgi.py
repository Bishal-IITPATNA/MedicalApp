"""
WSGI entry point for Azure App Service
Alternative to startup.py - provides a clean WSGI interface
"""

import os
import sys
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from app import create_app
    logger.info("Successfully imported create_app in wsgi.py")
except Exception as e:
    logger.error(f"Failed to import create_app in wsgi.py: {e}")
    raise

# Create the WSGI application
try:
    application = create_app()
    logger.info("Flask WSGI application created successfully")
except Exception as e:
    logger.error(f"Failed to create Flask WSGI application: {e}")
    raise

# For backward compatibility
app = application

if __name__ == "__main__":
    application.run()
