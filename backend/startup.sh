#!/bin/bash
# Alternative startup script for Azure App Service
# Uses gunicorn with proper WSGI module specification

# Set environment variables
export PYTHONPATH="${PYTHONPATH}:/home/site/wwwroot"

cd /home/site/wwwroot

# Start with gunicorn using wsgi module
exec gunicorn \
    --bind=0.0.0.0:${PORT:-8000} \
    --workers=2 \
    --worker-class=gevent \
    --timeout=600 \
    --preload \
    --access-logfile=- \
    --error-logfile=- \
    wsgi:application
