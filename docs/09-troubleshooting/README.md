# Troubleshooting Guide

## Common Issues & Solutions

### Backend Issues

#### 1. Server Won't Start
**Error**: `Address already in use` or `Port 5001 is in use`

**Solution**:
```bash
# Find process using port 5001
lsof -ti:5001

# Kill the process
kill -9 <process_id>

# Or use a different port
export FLASK_RUN_PORT=5002
```

#### 2. Database Connection Error
**Error**: `sqlite3.OperationalError: no such table`

**Solution**:
```bash
cd backend
python scripts/setup_database.py
```

#### 3. Import Error
**Error**: `ModuleNotFoundError: No module named 'app'`

**Solution**:
```bash
cd backend
source venv/bin/activate  # or .\venv\Scripts\activate on Windows
pip install -r requirements.txt
```

#### 4. JWT Token Error
**Error**: `Not enough segments` or `Invalid token`

**Solution**:
- Check token format in frontend
- Verify JWT secret key configuration
- Ensure token is properly included in Authorization header

### Frontend Issues

#### 1. Flutter Compilation Error
**Error**: `The Dart compiler exited unexpectedly`

**Solution**:
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

#### 2. Package Dependency Error
**Error**: Package version conflicts

**Solution**:
```bash
cd frontend
rm pubspec.lock
flutter pub get
```

#### 3. Network Request Failed
**Error**: `Connection error` or `Failed to load`

**Solutions**:
- Check if backend is running on port 5001
- Verify API endpoints in frontend code
- Check CORS configuration
- Ensure proper error handling in API service

#### 4. Navigation Error
**Error**: `selectedIndex && selectedIndex < destinations.length is not true`

**Solution**:
- Verify NavigationBar destinations match index usage
- Check selectedIndex bounds in dashboard code

### Database Issues

#### 1. Migration Error
**Error**: Database schema mismatch

**Solution**:
```bash
cd backend
# Backup existing database
cp instance/medical_app.db instance/medical_app_backup.db

# Run migration scripts
python scripts/update_schema.py
```

#### 2. Data Not Showing
**Issue**: Created records not appearing in UI

**Debugging**:
```sql
-- Connect to database
sqlite3 backend/instance/medical_app.db

-- Check if data exists
.tables
SELECT * FROM users LIMIT 5;
SELECT * FROM lab_test_orders LIMIT 5;
```

### Performance Issues

#### 1. Slow API Responses
**Symptoms**: API takes >3 seconds to respond

**Solutions**:
- Add database indexes
- Optimize query joins
- Implement pagination
- Use database connection pooling

#### 2. Frontend Lag
**Symptoms**: UI becomes unresponsive

**Solutions**:
- Optimize widget rebuilds
- Use const constructors
- Implement lazy loading
- Profile with Flutter DevTools

### Authentication Issues

#### 1. Login Failed
**Error**: `Invalid credentials` for correct password

**Debugging**:
```python
# Check user in database
python3
>>> from app import create_app, db
>>> from app.models.user import User
>>> app = create_app()
>>> with app.app_context():
...     user = User.query.filter_by(email='test@example.com').first()
...     if user:
...         print(f"User found: {user.email}")
...         print(f"Password check: {user.check_password('your_password')}")
```

#### 2. Token Expired
**Error**: `Token has expired`

**Solution**:
- Implement token refresh logic
- Check token expiration time
- Clear stored tokens and re-login

### Development Environment

#### 1. Virtual Environment Issues
**Error**: `Command not found` or dependency issues

**Solution**:
```bash
# Recreate virtual environment
cd backend
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. Flutter Path Issues
**Error**: `flutter command not found`

**Solution**:
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or reinstall Flutter
# Visit: https://flutter.dev/docs/get-started/install
```

## Debugging Tools

### Backend Debugging
```python
# Add to Flask routes for debugging
import logging
logging.basicConfig(level=logging.DEBUG)

# Print request data
print(f"Request data: {request.get_json()}")
```

### Frontend Debugging
```dart
// Add debug prints
print('API Response: $response');

// Use Flutter Inspector
flutter inspector

// Check network requests
flutter logs
```

### Database Debugging
```bash
# SQLite command line
sqlite3 backend/instance/medical_app.db

# Useful queries
.schema users
.headers on
.mode column
SELECT * FROM users WHERE email = 'test@example.com';
```

## Getting Help

1. Check error logs:
   - Backend: Terminal where Flask is running
   - Frontend: Browser console / Flutter logs
   - Database: SQLite error messages

2. Common debugging steps:
   - Restart servers
   - Clear cache/storage
   - Check network connectivity
   - Verify configuration files

3. Create minimal reproducible example

4. Check documentation:
   - Flask documentation
   - Flutter documentation  
   - SQLite documentation

## Performance Monitoring

### Backend Monitoring
```python
# Add timing decorators
import time
from functools import wraps

def timing_decorator(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = f(*args, **kwargs)
        end = time.time()
        print(f"{f.__name__} took {end - start:.2f} seconds")
        return result
    return wrapper
```

### Frontend Monitoring
```dart
// Performance tracking
import 'package:flutter/foundation.dart';

// Use Timeline for performance
Timeline.startSync('api_call');
// Your API call here
Timeline.finishSync();
```