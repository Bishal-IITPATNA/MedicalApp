# Deployment Guide

## Production Deployment

### Prerequisites

1. **Server Requirements**
   - Ubuntu 20.04+ or CentOS 8+
   - Python 3.9+
   - PostgreSQL 13+
   - Nginx
   - SSL Certificate

2. **Domain Setup**
   - Domain name configured
   - DNS A record pointing to server IP
   - SSL certificate (Let's Encrypt recommended)

### Backend Deployment

#### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx certbot python3-certbot-nginx

# Create application user
sudo useradd -m -s /bin/bash medicalapp
sudo usermod -aG sudo medicalapp
```

#### 2. Database Setup

```bash
# Switch to postgres user
sudo -u postgres psql

-- Create database and user
CREATE DATABASE medical_app_prod;
CREATE USER medicalapp_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE medical_app_prod TO medicalapp_user;
ALTER USER medicalapp_user CREATEDB;
\q
```

#### 3. Application Deployment

```bash
# Switch to application user
sudo -u medicalapp -i

# Clone repository
git clone https://github.com/yourusername/medical_app_v1.git
cd medical_app_v1/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn psycopg2-binary

# Create production environment file
cp .env.example .env.production
# Edit .env.production with production values
```

#### 4. Environment Configuration

Create `.env.production`:

```env
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-super-secret-production-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here

# Database Configuration
DATABASE_URL=postgresql://medicalapp_user:your_secure_password@localhost/medical_app_prod

# Email Configuration (for notifications)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password

# File Upload Configuration
MAX_CONTENT_LENGTH=16777216  # 16MB
UPLOAD_FOLDER=/var/www/medical_app/uploads

# External API Keys
SMS_API_KEY=your-sms-api-key
PAYMENT_GATEWAY_KEY=your-payment-key

# Security
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
REMEMBER_COOKIE_SECURE=True
```

#### 5. Database Migration

```bash
# Run migrations
export FLASK_APP=run.py
export FLASK_ENV=production
flask db upgrade

# Create admin user
python create_admin.py
```

#### 6. Gunicorn Configuration

Create `/home/medicalapp/medical_app_v1/backend/gunicorn.conf.py`:

```python
bind = "127.0.0.1:5000"
workers = 4
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2
max_requests = 1000
max_requests_jitter = 100
preload_app = True
reload = False
daemon = False
user = "medicalapp"
group = "medicalapp"
tmp_upload_dir = None
secure_scheme_headers = {
    'X-FORWARDED-PROTOCOL': 'ssl',
    'X-FORWARDED-PROTO': 'https',
    'X-FORWARDED-SSL': 'on'
}
```

#### 7. Systemd Service

Create `/etc/systemd/system/medical-app.service`:

```ini
[Unit]
Description=Medical App Gunicorn daemon
After=network.target

[Service]
User=medicalapp
Group=medicalapp
WorkingDirectory=/home/medicalapp/medical_app_v1/backend
Environment="PATH=/home/medicalapp/medical_app_v1/backend/venv/bin"
ExecStart=/home/medicalapp/medical_app_v1/backend/venv/bin/gunicorn --config gunicorn.conf.py run:app
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable medical-app
sudo systemctl start medical-app
sudo systemctl status medical-app
```

#### 8. Nginx Configuration

Create `/etc/nginx/sites-available/medical-app`:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    client_max_body_size 16M;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /uploads/ {
        alias /var/www/medical_app/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /static/ {
        alias /home/medicalapp/medical_app_v1/backend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/medical-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### 9. SSL Certificate

```bash
# Get SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Test renewal
sudo certbot renew --dry-run

# Set up auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Frontend Deployment

#### 1. Build Flutter Web App

```bash
# On development machine
cd medical_app_v1/frontend

# Update API base URL for production
# Edit lib/utils/api_constants.dart
# Set baseUrl to 'https://yourdomain.com/api'

# Build for web
flutter build web --release

# Upload build files to server
scp -r build/web/* user@yourserver:/var/www/medical_app_frontend/
```

#### 2. Nginx Configuration for Frontend

Add to existing nginx configuration:

```nginx
server {
    listen 443 ssl;
    server_name app.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    root /var/www/medical_app_frontend;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Docker Deployment

### 1. Backend Dockerfile

Create `backend/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Start command
CMD ["gunicorn", "--config", "gunicorn.conf.py", "run:app"]
```

### 2. Docker Compose

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: medical_app_prod
      POSTGRES_USER: medicalapp_user
      POSTGRES_PASSWORD: your_secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://medicalapp_user:your_secure_password@postgres:5432/medical_app_prod
    depends_on:
      - postgres
    volumes:
      - ./uploads:/app/uploads

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl/certs
    depends_on:
      - backend

volumes:
  postgres_data:
```

### 3. Deploy with Docker

```bash
# Build and start services
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec backend flask db upgrade

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Monitoring and Logging

### 1. Application Monitoring

```bash
# Install monitoring tools
pip install prometheus-client
pip install flask-prometheus-metrics

# Add to your Flask app
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

@app.route('/metrics')
def metrics():
    return generate_latest()
```

### 2. Log Configuration

Create `logging.conf`:

```ini
[loggers]
keys=root,gunicorn.error,gunicorn.access

[handlers]
keys=console,error_file,access_file

[formatters]
keys=generic,access

[logger_root]
level=INFO
handlers=console

[logger_gunicorn.error]
level=INFO
handlers=error_file
propagate=1
qualname=gunicorn.error

[logger_gunicorn.access]
level=INFO
handlers=access_file
propagate=0
qualname=gunicorn.access

[handler_console]
class=StreamHandler
formatter=generic
args=(sys.stdout, )

[handler_error_file]
class=logging.FileHandler
formatter=generic
args=('/var/log/medical_app/error.log',)

[handler_access_file]
class=logging.FileHandler
formatter=access
args=('/var/log/medical_app/access.log',)

[formatter_generic]
format=%(asctime)s [%(process)d] [%(levelname)s] %(message)s
datefmt=%Y-%m-%d %H:%M:%S
class=logging.Formatter

[formatter_access]
format=%(message)s
class=logging.Formatter
```

### 3. Log Rotation

Create `/etc/logrotate.d/medical-app`:

```
/var/log/medical_app/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 medicalapp medicalapp
    postrotate
        systemctl reload medical-app
    endscript
}
```

## Backup Strategy

### 1. Database Backup Script

Create `backup_db.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/medical_app"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="medical_app_prod"
DB_USER="medicalapp_user"

mkdir -p $BACKUP_DIR

# Create database backup
pg_dump -U $DB_USER -h localhost $DB_NAME > $BACKUP_DIR/db_backup_$DATE.sql

# Compress backup
gzip $BACKUP_DIR/db_backup_$DATE.sql

# Keep only last 30 days
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +30 -delete

echo "Database backup completed: db_backup_$DATE.sql.gz"
```

### 2. File Backup Script

Create `backup_files.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/medical_app"
DATE=$(date +%Y%m%d_%H%M%S)
APP_DIR="/home/medicalapp/medical_app_v1"
UPLOAD_DIR="/var/www/medical_app/uploads"

# Backup application files (excluding venv)
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    $APP_DIR

# Backup uploads
tar -czf $BACKUP_DIR/uploads_backup_$DATE.tar.gz $UPLOAD_DIR

# Clean old backups
find $BACKUP_DIR -name "*_backup_*.tar.gz" -mtime +7 -delete
```

### 3. Automated Backup

Add to crontab:

```bash
# Database backup daily at 2 AM
0 2 * * * /home/medicalapp/scripts/backup_db.sh

# File backup daily at 3 AM
0 3 * * * /home/medicalapp/scripts/backup_files.sh
```

## Security Checklist

- [ ] SSL/TLS certificate configured and working
- [ ] Database passwords are strong and secure
- [ ] JWT secret keys are random and secure
- [ ] File upload restrictions in place
- [ ] Rate limiting configured
- [ ] Firewall configured (only necessary ports open)
- [ ] Regular security updates applied
- [ ] Backup and recovery tested
- [ ] Monitoring and alerting configured
- [ ] Error pages don't reveal sensitive information
- [ ] CORS properly configured
- [ ] SQL injection protection verified
- [ ] XSS protection enabled
- [ ] CSRF protection configured

## Performance Optimization

### 1. Database Optimization

```sql
-- Create necessary indexes
CREATE INDEX CONCURRENTLY idx_appointments_date_doctor ON appointments(appointment_date, doctor_id);
CREATE INDEX CONCURRENTLY idx_orders_status_created ON medicine_orders(status, created_at);
```

### 2. Caching

```bash
# Install Redis
sudo apt install redis-server

# Configure Redis caching in Flask
pip install flask-caching redis
```

### 3. CDN Setup

- Configure CloudFlare or AWS CloudFront
- Serve static assets from CDN
- Enable browser caching

## Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   sudo systemctl status medical-app
   sudo journalctl -u medical-app -f
   ```

2. **Database connection issues**
   ```bash
   sudo -u postgres psql
   \l  # List databases
   \du  # List users
   ```

3. **SSL certificate issues**
   ```bash
   sudo certbot certificates
   sudo nginx -t
   ```

4. **Performance issues**
   ```bash
   # Check system resources
   htop
   iotop
   # Check database performance
   sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
   ```