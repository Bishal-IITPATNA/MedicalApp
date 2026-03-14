# Deployment Guide

Complete guide for deploying Seevak Care to production.

## 📋 Prerequisites

Before deployment, ensure:
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Database migrations created
- [ ] Environment variables configured
- [ ] Security review completed

---

## 🔧 Backend Deployment

### Option 1: Deploy to Heroku

**1. Install Heroku CLI:**
```bash
brew tap heroku/brew && brew install heroku  # macOS
# OR download from https://devcenter.heroku.com/articles/heroku-cli
```

**2. Login to Heroku:**
```bash
heroku login
```

**3. Create Heroku app:**
```bash
cd backend
heroku create medical-app-backend
```

**4. Add PostgreSQL database:**
```bash
# SQLite doesn't work on Heroku, use PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev
```

**5. Update backend for PostgreSQL:**

```python
# requirements.txt - add
psycopg2-binary==2.9.9

# config.py - update
import os

class Config:
    # Use PostgreSQL on production, SQLite on development
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///medical_app.db')
    
    # Fix for Heroku postgres URL
    if SQLALCHEMY_DATABASE_URI.startswith("postgres://"):
        SQLALCHEMY_DATABASE_URI = SQLALCHEMY_DATABASE_URI.replace("postgres://", "postgresql://", 1)
```

**6. Create Procfile:**
```bash
# backend/Procfile
web: flask db upgrade && gunicorn app:app
```

**7. Add gunicorn:**
```bash
pip install gunicorn
pip freeze > requirements.txt
```

**8. Set environment variables:**
```bash
heroku config:set JWT_SECRET_KEY="your-super-secret-key-change-in-production"
heroku config:set FLASK_ENV=production
```

**9. Deploy:**
```bash
git add .
git commit -m "Prepare for Heroku deployment"
git push heroku main

# OR if on different branch
git push heroku your-branch:main
```

**10. Run migrations:**
```bash
heroku run flask db upgrade
```

**11. Create admin user:**
```bash
heroku run flask shell

>>> from app import db
>>> from app.models import User
>>> admin = User(email='admin@hospital.com', role='admin')
>>> admin.set_password('admin123')
>>> db.session.add(admin)
>>> db.session.commit()
>>> exit()
```

**12. Check logs:**
```bash
heroku logs --tail
```

**13. Open app:**
```bash
heroku open
```

---

### Option 2: Deploy to AWS EC2

**1. Launch EC2 instance:**
- Ubuntu Server 22.04 LTS
- t2.micro (free tier)
- Configure security group:
  - SSH (22) - Your IP
  - HTTP (80) - 0.0.0.0/0
  - HTTPS (443) - 0.0.0.0/0
  - Custom TCP (5000) - 0.0.0.0/0

**2. SSH into instance:**
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@your-ec2-ip
```

**3. Install dependencies:**
```bash
sudo apt update
sudo apt install python3-pip python3-venv nginx -y
```

**4. Clone repository:**
```bash
git clone https://github.com/yourusername/medical-app.git
cd medical-app/backend
```

**5. Setup virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn
```

**6. Create .env file:**
```bash
nano .env

# Add:
JWT_SECRET_KEY=your-production-secret-key
FLASK_ENV=production
DATABASE_URL=sqlite:///medical_app.db
```

**7. Initialize database:**
```bash
flask db upgrade
```

**8. Create systemd service:**
```bash
sudo nano /etc/systemd/system/medical-app.service

# Add:
[Unit]
Description=Medical App Flask Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/medical-app/backend
Environment="PATH=/home/ubuntu/medical-app/backend/venv/bin"
ExecStart=/home/ubuntu/medical-app/backend/venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 app:app

[Install]
WantedBy=multi-user.target
```

**9. Start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl start medical-app
sudo systemctl enable medical-app
sudo systemctl status medical-app
```

**10. Configure Nginx:**
```bash
sudo nano /etc/nginx/sites-available/medical-app

# Add:
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**11. Enable site:**
```bash
sudo ln -s /etc/nginx/sites-available/medical-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**12. Setup SSL (Optional but recommended):**
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## 📱 Frontend Deployment

### Option 1: Deploy as Web App

**1. Build for web:**
```bash
cd frontend
flutter build web
```

**2. Deploy to Firebase Hosting:**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting

# Select build/web as public directory
# Configure as single-page app: Yes
# Set up automatic builds: No

# Deploy
firebase deploy --only hosting
```

**3. Update API URL:**

```dart
// lib/services/api_service.dart
class ApiService {
  // Change to production URL
  static const String baseUrl = 'https://your-backend-url.herokuapp.com';
}
```

Rebuild and redeploy:
```bash
flutter build web
firebase deploy --only hosting
```

---

### Option 2: Deploy to Netlify

**1. Build web app:**
```bash
flutter build web
```

**2. Deploy:**
- Go to [netlify.com](https://netlify.com)
- Drag & drop `build/web` folder
- OR use Netlify CLI:

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

**3. Configure redirects for Flutter:**

Create `build/web/_redirects`:
```
/*    /index.html   200
```

---

### Option 3: Mobile App Stores

#### Android - Google Play Store

**1. Create keystore:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

**2. Configure signing:**

Create `android/key.properties`:
```
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/Users/you/upload-keystore.jks
```

Update `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**3. Build APK/AAB:**
```bash
# For APK
flutter build apk --release

# For App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**4. Upload to Play Console:**
- Go to [Google Play Console](https://play.google.com/console)
- Create app
- Upload `build/app/outputs/bundle/release/app-release.aab`
- Fill in store listing
- Submit for review

---

#### iOS - App Store

**1. Configure signing:**
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner > Signing & Capabilities
- Select your team
- Update Bundle Identifier

**2. Build archive:**
```bash
flutter build ios --release
```

**3. Open in Xcode:**
```bash
open ios/Runner.xcworkspace
```

**4. Archive:**
- Product > Archive
- Upload to App Store
- Fill in App Store Connect details
- Submit for review

---

## 🗄️ Database Migration

### Production Migration Strategy

**1. Backup database:**
```bash
# Heroku
heroku pg:backups:capture
heroku pg:backups:download

# AWS
sqlite3 medical_app.db ".backup backup.db"
```

**2. Test migration locally:**
```bash
# Copy production DB
cp medical_app.db medical_app_backup.db

# Run migration
flask db upgrade

# Test thoroughly
flask shell
# ... test queries ...

# If issues, restore
mv medical_app_backup.db medical_app.db
```

**3. Run in production:**
```bash
# Heroku
heroku maintenance:on
heroku run flask db upgrade
heroku maintenance:off

# AWS
sudo systemctl stop medical-app
flask db upgrade
sudo systemctl start medical-app
```

---

## 🔐 Security Checklist

Before production:

- [ ] Change all default passwords
- [ ] Use strong JWT_SECRET_KEY (at least 32 random characters)
- [ ] Enable HTTPS (SSL certificate)
- [ ] Set secure CORS origins
- [ ] Disable debug mode
- [ ] Add rate limiting
- [ ] Sanitize user inputs
- [ ] Use environment variables for secrets
- [ ] Enable database backups
- [ ] Setup error monitoring (Sentry)
- [ ] Configure logging
- [ ] Review permissions
- [ ] Add WAF (Web Application Firewall)

---

## 📊 Monitoring

### Setup Error Tracking

**Sentry (Recommended):**

```python
# Backend - requirements.txt
sentry-sdk[flask]==1.40.0

# app/__init__.py
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[FlaskIntegration()],
    traces_sample_rate=1.0
)
```

```dart
// Frontend - pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0

// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'your-sentry-dsn';
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

---

### Setup Logging

**Backend:**
```python
# app/__init__.py
import logging
from logging.handlers import RotatingFileHandler

def create_app():
    app = Flask(__name__)
    
    if not app.debug:
        file_handler = RotatingFileHandler('logs/medical_app.log', 
                                          maxBytes=10240, 
                                          backupCount=10)
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
        ))
        file_handler.setLevel(logging.INFO)
        app.logger.addHandler(file_handler)
        
        app.logger.setLevel(logging.INFO)
        app.logger.info('Medical App startup')
    
    return app
```

---

## 🔄 Continuous Deployment

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to Heroku
        uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{secrets.HEROKU_API_KEY}}
          heroku_app_name: "medical-app-backend"
          heroku_email: "your-email@example.com"
          appdir: "backend"

  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - run: flutter pub get
        working-directory: ./frontend
      
      - run: flutter build web
        working-directory: ./frontend
      
      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only hosting
        env:
          FIREBASE_TOKEN: ${{secrets.FIREBASE_TOKEN}}
```

---

## 📞 Rollback Plan

If deployment fails:

**Heroku:**
```bash
# View releases
heroku releases

# Rollback to previous
heroku rollback v123
```

**AWS:**
```bash
# Restore from backup
sudo systemctl stop medical-app
mv medical_app.db medical_app_failed.db
mv backup.db medical_app.db
sudo systemctl start medical-app
```

---

**Next:** See [Performance Optimization](./performance.md) for scaling tips.
