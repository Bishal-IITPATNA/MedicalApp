# Backend Setup Guide

This guide will help you set up the Flask backend from scratch and understand how everything works together.

## 🎯 What You'll Learn

- Setting up Python environment
- Installing dependencies
- Database setup and migrations
- Running the backend server
- Testing API endpoints

## 📋 Prerequisites

- Python 3.8 or higher installed
- Basic understanding of Python
- Terminal/command line access

## 🚀 Step 1: Python Environment Setup

### What is a Virtual Environment?

A virtual environment is like a separate workspace for your Python project. It keeps project dependencies isolated from your system Python.

**Why use it?**
- Prevents version conflicts between projects
- Makes the project portable
- Easy to replicate on other machines

### Create Virtual Environment

```bash
# Navigate to backend folder
cd backend

# Create virtual environment
python3 -m venv venv

# Activate it
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate

# You'll see (venv) in your terminal prompt:
(venv) user@computer:~/backend$
```

**What just happened?**
- `python3 -m venv venv` created a `venv/` folder
- This folder contains a copy of Python and pip
- When activated, all pip installs go into venv/ folder

## 📦 Step 2: Install Dependencies

### Understanding requirements.txt

The `requirements.txt` file lists all Python packages needed:

```txt
Flask==3.0.0           # Web framework
Flask-SQLAlchemy==3.1.1  # Database ORM
Flask-JWT-Extended==4.5.3  # Authentication
Flask-CORS==4.0.0      # Cross-origin requests
Flask-Migrate==4.0.5   # Database migrations
python-dotenv==1.0.0   # Environment variables
werkzeug==3.0.1        # Password hashing
```

### Install Packages

```bash
# Make sure venv is activated!
pip install -r requirements.txt
```

**What's happening?**
- pip downloads each package from PyPI (Python Package Index)
- Installs them in your venv/lib/python3.x/site-packages/
- Takes 1-2 minutes depending on internet speed

### Verify Installation

```bash
# Check installed packages
pip list

# Should show:
Flask             3.0.0
Flask-SQLAlchemy  3.1.1
Flask-JWT-Extended 4.5.3
# ... and others
```

## 🔐 Step 3: Environment Configuration

### Create .env File

Environment variables store sensitive configuration:

```bash
# In backend/ folder, create .env file
touch .env
```

**Add these variables** (open .env in text editor):

```bash
# Flask Configuration
FLASK_APP=run.py
FLASK_ENV=development
SECRET_KEY=your-super-secret-key-change-this-in-production

# Database
DATABASE_URL=sqlite:///medical_app.db

# JWT Configuration
JWT_SECRET_KEY=your-jwt-secret-key-change-this-too
JWT_ACCESS_TOKEN_EXPIRES=86400  # 24 hours in seconds
JWT_REFRESH_TOKEN_EXPIRES=2592000  # 30 days

# CORS (Frontend URL)
CORS_ORIGINS=http://localhost:8080,http://localhost:3000
```

**What each variable does**:

| Variable | Purpose | Example |
|----------|---------|---------|
| `FLASK_APP` | Entry point file | run.py |
| `FLASK_ENV` | Development/production mode | development |
| `SECRET_KEY` | Flask session encryption | random-string-123 |
| `DATABASE_URL` | Database connection string | sqlite:///app.db |
| `JWT_SECRET_KEY` | JWT token signing | another-random-string |
| `JWT_ACCESS_TOKEN_EXPIRES` | Token validity period | 86400 (24 hours) |

**Security Note**: Never commit .env to git! It's in .gitignore.

## 🗄️ Step 4: Database Setup

### Quick Setup (Recommended)

**Use the setup script to create database and users:**

```bash
# Option 1: Create tables only
python setup_database.py

# Option 2: Create tables + admin user
python setup_database.py --admin

# Option 3: Create tables + test users for all roles
python setup_database.py --with-test-data

# Option 4: Create everything (recommended for development)
python setup_database.py --all
```

**What you'll get:**
- ✅ All database tables created
- ✅ Admin user: `admin@medical.com` / `admin123` (if --admin or --all)
- ✅ Test users for all roles (if --with-test-data or --all):
  - Patient: `patient@test.com` / `password123`
  - Doctor: `doctor@test.com` / `password123`
  - Nurse: `nurse@test.com` / `password123`
  - Medical Store: `medstore@test.com` / `password123`
  - Lab Store: `labstore@test.com` / `password123`

### Alternative: Manual Database Setup

If you prefer manual control or need migrations:

#### Option A: Using Flask CLI (Simpler)

```bash
# Initialize database tables
flask init-db
```

This creates all tables defined in your models.

#### Option B: Using Flask-Migrate (Advanced)

Migrations are version control for your database schema.

**Why migrations?**
- Track schema changes over time
- Apply/revert changes safely
- Share schema with team

**Initialize Migration System:**

```bash
# Initialize Flask-Migrate
flask db init
```

**What this creates**:
```
backend/
├── migrations/          # Migration history folder
│   ├── alembic.ini     # Migration config
│   ├── env.py          # Migration environment
│   ├── script.py.mako  # Template for new migrations
│   └── versions/       # Individual migration files
```

**Create Initial Migration:**

```bash
# Generate migration from current models
flask db migrate -m "Initial migration with all models"
```

**What happens**:
1. Flask-Migrate reads all models in `app/models/`
2. Compares to current database (empty)
3. Generates migration file with CREATE TABLE statements
4. Saves in `migrations/versions/`

**Apply Migration:**

```bash
# Apply migration to database
flask db upgrade
```

**What happens**:
1. Creates `medical_app.db` file
2. Executes all CREATE TABLE statements
3. Records migration as applied in `alembic_version` table

### Verify Database

```bash
# Install sqlite3 command (if not available)
# macOS: brew install sqlite3
# Ubuntu: apt install sqlite3

# Open database
sqlite3 medical_app.db

# List tables
.tables

# Should show:
alembic_version  doctor          medicine_order   prescription
appointment      lab_store       notification     user
chamber          lab_test        order_item       
doctor_schedule  medical_store   patient

# View user table structure
.schema user

# Exit
.quit
```

## 🏃 Step 5: Run the Server

### Start Development Server

```bash
# Make sure you're in backend/ with venv activated
flask run

# Or with auto-reload on code changes:
flask run --reload
```

**Output you'll see**:
```
 * Environment: development
 * Debug mode: on
 * Running on http://127.0.0.1:5000
 * Restarting with stat
 * Debugger is active!
```

**What's running**:
- Flask development server on port 5000
- Auto-reload enabled (restart on code changes)
- Debug mode (shows detailed error pages)

### Test the Server

**Option 1: Browser**
- Open http://localhost:5000 in browser
- You might see "Not Found" - that's okay!
- Backend is API-only (no HTML pages)

**Option 2: curl (command line)**
```bash
# Test health endpoint (if you have one)
curl http://localhost:5000/api/health

# Expected response:
{"status": "ok"}
```

**Option 3: Postman/Thunder Client**
- Use GUI tool to test APIs
- More on this in [API Testing](#api-testing) below

## 🧪 Step 6: Create Test Data

### Why Seed Data?

Empty database is hard to work with. Let's add test users and data.

### Create Seed Script

Create `backend/seed.py`:

```python
from app import create_app, db
from app.models.user import User, Patient, Doctor
from werkzeug.security import generate_password_hash

app = create_app()

with app.app_context():
    # Clear existing data (optional)
    db.drop_all()
    db.create_all()
    
    # Create test patient
    patient_user = User(
        email='patient@test.com',
        password_hash=generate_password_hash('password123'),
        role='patient'
    )
    db.session.add(patient_user)
    db.session.commit()
    
    patient = Patient(
        user_id=patient_user.id,
        name='John Doe',
        phone='1234567890',
        blood_group='O+',
        dob='1990-01-01'
    )
    db.session.add(patient)
    
    # Create test doctor
    doctor_user = User(
        email='doctor@test.com',
        password_hash=generate_password_hash('password123'),
        role='doctor'
    )
    db.session.add(doctor_user)
    db.session.commit()
    
    doctor = Doctor(
        user_id=doctor_user.id,
        name='Dr. Sarah Smith',
        specialization='General Physician',
        qualification='MBBS, MD',
        experience_years=10
    )
    db.session.add(doctor)
    
    db.session.commit()
    print("Test data created successfully!")
```

### Run Seed Script

```bash
python seed.py
```

**What this does**:
1. Creates test users with known passwords
2. Creates linked patient and doctor profiles
3. You can now login with these credentials

## 🔍 API Testing

### Test Login Endpoint

**Using curl**:
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@test.com",
    "password": "password123"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "patient@test.com",
    "role": "patient"
  }
}
```

### Test Authenticated Endpoint

```bash
# Replace YOUR_TOKEN with actual token from login response
curl http://localhost:5000/api/patient/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Using Thunder Client (VS Code Extension)

1. Install Thunder Client extension
2. Create new request
3. Method: POST
4. URL: http://localhost:5000/api/auth/login
5. Body → JSON:
   ```json
   {
     "email": "patient@test.com",
     "password": "password123"
   }
   ```
6. Send request
7. Save token from response for authenticated requests

## 🛠️ Troubleshooting

### Common Issues

**Issue 1: "No module named 'flask'"**
```
Solution: Activate virtual environment
$ source venv/bin/activate
```

**Issue 2: "Database is locked"**
```
Solution: Close any SQLite browser tools
$ flask run  # Restart server
```

**Issue 3: "Port 5000 already in use"**
```
Solution: Use different port
$ flask run --port 5001
```

**Issue 4: "ImportError: cannot import name 'create_app'"**
```
Solution: Check FLASK_APP in .env
FLASK_APP=run.py  # Should point to run.py
```

**Issue 5: "Table doesn't exist"**
```
Solution: Run migrations
$ flask db upgrade
```

## 📊 Project Structure Recap

After setup, you should have:

```
backend/
├── venv/                    # Virtual environment (not in git)
├── migrations/              # Database migrations
│   └── versions/
│       └── 001_initial.py
├── app/
│   ├── __init__.py         # App factory
│   ├── models/             # Database models
│   ├── routes/             # API endpoints
│   └── utils/              # Helper functions
├── .env                    # Environment variables (not in git)
├── config.py               # Configuration classes
├── run.py                  # Application entry point
├── requirements.txt        # Python dependencies
├── seed.py                 # Test data script
└── medical_app.db          # SQLite database (not in git)
```

## ✅ Verification Checklist

- [ ] Virtual environment created and activated
- [ ] All dependencies installed (`pip list` shows packages)
- [ ] .env file created with all variables
- [ ] Database initialized (`medical_app.db` exists)
- [ ] Migrations applied (tables created)
- [ ] Server running on http://localhost:5000
- [ ] Login endpoint works (returns token)
- [ ] Test data created (can login with test users)

## 🎯 Next Steps

Now that backend is running:
1. Read [Database Models Guide](./database-models.md) to understand data structure
2. Read [API Endpoints Guide](./api-endpoints.md) to explore all routes
3. Read [Authentication Guide](./authentication.md) to understand JWT flow

---

**Need Help?**
- Check [Common Issues](../06-maintenance/common-issues.md)
- Review [Backend Module Guide](./backend-module-guide.md) for code walkthrough
