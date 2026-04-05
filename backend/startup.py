#!/usr/bin/env python3
"""
Azure App Service startup script for Seevak Care Backend
"""
import os
import sys
import logging

# Configure logging for Azure
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Ensure current directory is in Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# Import Flask app
from main import application

# This is what Azure App Service looks for
app = application

if __name__ == "__main__":
    # Get port from Azure environment
    port = int(os.environ.get('PORT', 8000))
    logger.info(f"Starting Seevak Care on port {port}")
    app.run(host='0.0.0.0', port=port)
