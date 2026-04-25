"""
ASGI entrypoint for the Seevak Care Flask backend.

The Emergent supervisor runs:
    uvicorn server:app --host 0.0.0.0 --port 8001

This file imports the Flask app factory and wraps it with `a2wsgi` so that
uvicorn (an ASGI server) can serve the underlying WSGI Flask application.
"""

import os
import sys
import logging
from pathlib import Path
from dotenv import load_dotenv

# Make sure the backend directory is on sys.path
ROOT_DIR = Path(__file__).parent
sys.path.insert(0, str(ROOT_DIR))
load_dotenv(ROOT_DIR / ".env")

from a2wsgi import WSGIMiddleware  # noqa: E402
from app import create_app, db  # noqa: E402

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("seevak.server")

flask_app = create_app()

# Ensure tables exist on first boot. Safe to call repeatedly.
with flask_app.app_context():
    try:
        db.create_all()
        logger.info("Database tables verified/created on startup.")
    except Exception as exc:  # pragma: no cover
        logger.exception("Failed to create database tables: %s", exc)

# Expose ASGI app for uvicorn (server:app)
app = WSGIMiddleware(flask_app)
