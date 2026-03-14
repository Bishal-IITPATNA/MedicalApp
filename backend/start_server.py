#!/usr/bin/env python3
import os
import sys

# Add the current directory to the Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

# Import and run the app
from app import create_app

if __name__ == '__main__':
    app = create_app()
    print("Starting Flask server on port 5001...")
    app.run(host='0.0.0.0', port=5001, debug=True)