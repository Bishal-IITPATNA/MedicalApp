# Azure App Service - Gunicorn Configuration
# This file provides production-ready configuration for running Flask app with Gunicorn

import os

# Server socket
bind = f"0.0.0.0:{os.environ.get('PORT', 8000)}"
backlog = 2048

# Worker processes
workers = int(os.environ.get('GUNICORN_WORKERS', 2))
worker_class = "gevent"
worker_connections = 1000
timeout = 30
keepalive = 2

# Restart workers after this many requests, to help prevent memory leaks
max_requests = 1000
max_requests_jitter = 50

# Logging
loglevel = 'info'
access_log_format = '%h %l %u %t "%r" %s %b "%{Referer}i" "%{User-Agent}i"'

# Process naming
proc_name = 'medical_app_backend'

# Daemonize the Gunicorn process (detach & enter background)
daemon = False

# The socket to bind to
user = None
group = None
tmp_upload_dir = None

# SSL
keyfile = None
certfile = None

# Worker configuration
preload_app = True
reload = False

# Application configuration
wsgi_file = "startup:app"

def when_ready(server):
    print("Medical App Backend server is ready. Accepting connections...")

def worker_int(worker):
    print(f"Worker {worker.pid} received INT signal")

def on_exit(server):
    print("Medical App Backend server is shutting down...")

def post_fork(server, worker):
    print(f"Worker spawned (pid: {worker.pid})")

def pre_fork(server, worker):
    print("Worker about to fork")

def worker_abort(worker):
    print(f"Worker {worker.pid} aborted")
