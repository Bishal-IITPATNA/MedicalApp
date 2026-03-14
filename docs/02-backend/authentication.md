# Authentication & Authorization Guide

Complete guide to JWT-based authentication in the Medical App.

## 🎯 Overview

The app uses **JWT (JSON Web Tokens)** for stateless authentication.

**Why JWT?**
- Stateless (no session storage needed)
- Scalable (works across multiple servers)
- Secure (signed tokens, tamper-proof)
- Mobile-friendly (easy token storage)

## 🔐 Authentication Flow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. USER REGISTRATION                                         │
├──────────────────────────────────────────────────────────────┤
│ User fills registration form                                 │
│   ↓                                                          │
│ POST /api/auth/register                                      │
│   ↓                                                          │
│ Backend:                                                     │
│   - Validate email format                                    │
│   - Check if email already exists                            │
│   - Hash password with bcrypt                                │
│   - Create User record                                       │
│   - Create role-specific profile (Patient/Doctor/etc)        │
│   ↓                                                          │
│ Response: {"success": true, "user": {...}}                   │
└──────────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. USER LOGIN                                                │
├──────────────────────────────────────────────────────────────┤
│ User enters email & password                                 │
│   ↓                                                          │
│ POST /api/auth/login                                         │
│   ↓                                                          │
│ Backend:                                                     │
│   - Find user by email                                       │
│   - Verify password hash                                     │
│   - Generate access token (24h expiry)                       │
│   - Generate refresh token (30d expiry)                      │
│   ↓                                                          │
│ Response:                                                    │
│   {                                                          │
│     "access_token": "eyJhbGci...",                           │
│     "refresh_token": "eyJhbGci...",                          │
│     "user": {"id": 1, "role": "patient"}                     │
│   }                                                          │
│   ↓                                                          │
│ Frontend:                                                    │
│   - Stores tokens in secure storage                          │
│   - Redirects to appropriate dashboard                       │
└──────────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. AUTHENTICATED REQUEST                                     │
├──────────────────────────────────────────────────────────────┤
│ User requests protected resource                             │
│   ↓                                                          │
│ GET /api/patient/profile                                     │
│ Header: Authorization: Bearer <access_token>                 │
│   ↓                                                          │
│ Backend:                                                     │
│   - Extract token from header                                │
│   - Verify token signature                                   │
│   - Check expiration                                         │
│   - Extract user_id from token payload                       │
│   - Process request with user context                        │
│   ↓                                                          │
│ Response: {"success": true, "data": {...}}                   │
└──────────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. TOKEN EXPIRATION & REFRESH                                │
├──────────────────────────────────────────────────────────────┤
│ Access token expires (after 24 hours)                        │
│   ↓                                                          │
│ Backend returns 401 Unauthorized                             │
│   ↓                                                          │
│ Frontend detects 401:                                        │
│   - Calls POST /api/auth/refresh                             │
│   - Sends refresh_token                                      │
│   ↓                                                          │
│ Backend:                                                     │
│   - Validates refresh token                                  │
│   - Generates new access token                               │
│   ↓                                                          │
│ Response: {"access_token": "new_token"}                      │
│   ↓                                                          │
│ Frontend:                                                    │
│   - Stores new access token                                  │
│   - Retries original request                                 │
└──────────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. PASSWORD MANAGEMENT                                       │
├──────────────────────────────────────────────────────────────┤
│ A. CHANGE PASSWORD (Logged-in user)                          │
│   POST /api/auth/change-password                             │
│   Headers: Authorization: Bearer <access_token>              │
│   Body: {"current_password": "...", "new_password": "..."}   │
│   ↓                                                          │
│   - Verify current password                                  │
│   - Update to new password                                   │
│   - Create security notification                             │
│                                                              │
│ B. FORGOT PASSWORD (Token generation)                        │
│   POST /api/auth/forgot-password                             │
│   Body: {"email": "user@example.com"}                        │
│   ↓                                                          │
│   - Generate secure reset token (32 bytes)                   │
│   - Set expiry (1 hour)                                      │
│   - Send token via email/SMS (production)                    │
│   - Returns success (prevents email enumeration)             │
│                                                              │
│ C. RESET PASSWORD (Using token)                              │
│   POST /api/auth/reset-password                              │
│   Body: {                                                    │
│     "email": "user@example.com",                             │
│     "token": "reset_token_here",                             │
│     "new_password": "new_password"                           │
│   }                                                          │
│   ↓                                                          │
│   - Verify token matches and not expired                     │
│   - Update password                                          │
│   - Clear reset token                                        │
│   - Create security notification                             │
└──────────────────────────────────────────────────────────────┘
```

## 🔑 JWT Token Structure

### Access Token Payload

```json
{
  "sub": 1,                    // user_id (subject)
  "email": "user@example.com",
  "role": "patient",
  "iat": 1702300000,           // issued at (timestamp)
  "exp": 1702386400            // expires at (timestamp)
}
```

### Token Components

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImVtYWlsIjoidXNlckBleGFtcGxlLmNvbSJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
└────────────┬────────────┘ └───────────────┬──────────────┘ └──────────────┬──────────────┘
          Header                        Payload                        Signature
```

**Header:**
```json
{
  "alg": "HS256",    // Algorithm
  "typ": "JWT"       // Type
}
```

**Signature:**
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret_key
)
```

## 💻 Backend Implementation

### File: `app/routes/auth.py`

```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity
)
from werkzeug.security import generate_password_hash, check_password_hash
from app.models.user import User, Patient, Doctor
from app import db

bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@bp.route('/register', methods=['POST'])
def register():
    """Register new user"""
    data = request.get_json()
    
    # Validate required fields
    required = ['email', 'password', 'role']
    if not all(field in data for field in required):
        return jsonify({'error': 'Missing required fields'}), 400
    
    # Check if user exists
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already registered'}), 400
    
    # Create user
    user = User(
        email=data['email'],
        password_hash=generate_password_hash(data['password']),
        role=data['role']
    )
    db.session.add(user)
    db.session.commit()
    
    # Create role-specific profile
    if data['role'] == 'patient':
        patient = Patient(
            user_id=user.id,
            name=data.get('name'),
            phone=data.get('phone'),
            dob=data.get('dob'),
            gender=data.get('gender'),
            blood_group=data.get('blood_group')
        )
        db.session.add(patient)
    # ... similar for other roles
    
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'User registered successfully',
        'user': user.to_dict()
    }), 201

@bp.route('/login', methods=['POST'])
def login():
    """Login user and return tokens"""
    data = request.get_json()
    
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({'error': 'Email and password required'}), 400
    
    # Find user
    user = User.query.filter_by(email=email).first()
    
    # Verify password
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({'error': 'Invalid credentials'}), 401
    
    # Check if account is active
    if not user.is_active:
        return jsonify({'error': 'Account is deactivated'}), 403
    
    # Create tokens
    access_token = create_access_token(
        identity=user.id,
        additional_claims={
            'email': user.email,
            'role': user.role
        }
    )
    
    refresh_token = create_refresh_token(identity=user.id)
    
    return jsonify({
        'success': True,
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.to_dict()
    }), 200

@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresh access token"""
    current_user_id = get_jwt_identity()
    
    # Generate new access token
    access_token = create_access_token(identity=current_user_id)
    
    return jsonify({
        'access_token': access_token
    }), 200

@bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """Logout user (client handles token removal)"""
    return jsonify({
        'success': True,
        'message': 'Logged out successfully'
    }), 200

@bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change password for logged-in user"""
    data = request.get_json()
    current_user_id = get_jwt_identity()
    
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({'error': 'Current and new password required'}), 400
    
    # Validate new password length
    if len(new_password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400
    
    # Get user
    user = User.query.get(current_user_id)
    
    # Verify current password
    if not check_password_hash(user.password_hash, current_password):
        return jsonify({'error': 'Current password is incorrect'}), 401
    
    # Update password
    user.password_hash = generate_password_hash(new_password)
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Password changed successfully'
    }), 200

@bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Generate password reset token"""
    data = request.get_json()
    email = data.get('email')
    
    if not email:
        return jsonify({'error': 'Email required'}), 400
    
    # Find user (don't reveal if user exists - security)
    user = User.query.filter_by(email=email).first()
    
    if user:
        # Generate reset token
        reset_token = user.generate_reset_token()
        db.session.commit()
        
        # In production, send email with reset link
        # For now, return token in response (DEVELOPMENT ONLY)
        # TODO: Implement email service
    
    # Always return success to prevent email enumeration
    return jsonify({
        'success': True,
        'message': 'If email exists, reset token has been sent',
        'token': reset_token if user else None  # Remove in production
    }), 200

@bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password using token"""
    data = request.get_json()
    
    email = data.get('email')
    token = data.get('token')
    new_password = data.get('new_password')
    
    if not all([email, token, new_password]):
        return jsonify({'error': 'Email, token, and new password required'}), 400
    
    # Validate password length
    if len(new_password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400
    
    # Find user
    user = User.query.filter_by(email=email).first()
    
    if not user:
        return jsonify({'error': 'Invalid email or token'}), 400
    
    # Verify token
    if not user.verify_reset_token(token):
        return jsonify({'error': 'Invalid or expired token'}), 400
    
    # Update password
    user.password_hash = generate_password_hash(new_password)
    user.clear_reset_token()
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Password reset successfully'
    }), 200
```

### File: `config.py`

```python
from datetime import timedelta
import os

class Config:
    # JWT Configuration
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # Token location
    JWT_TOKEN_LOCATION = ['headers']
    JWT_HEADER_NAME = 'Authorization'
    JWT_HEADER_TYPE = 'Bearer'
```

### File: `app/__init__.py`

```python
from flask import Flask
from flask_jwt_extended import JWTManager

jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Initialize JWT
    jwt.init_app(app)
    
    # Register blueprints
    from app.routes import auth
    app.register_blueprint(auth.bp)
    
    return app
```

## 📱 Frontend Implementation

### File: `frontend/lib/services/auth_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  // Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        '/api/auth/login',
        {'email': email, 'password': password},
      );

      if (response['success'] == true) {
        // Store tokens
        await _storage.write(
          key: 'access_token',
          value: response['access_token'],
        );
        await _storage.write(
          key: 'refresh_token',
          value: response['refresh_token'],
        );
        await _storage.write(
          key: 'user_data',
          value: json.encode(response['user']),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  // Refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _apiService.post(
        '/api/auth/refresh',
        {},
        token: refreshToken,
      );

      if (response['access_token'] != null) {
        await _storage.write(
          key: 'access_token',
          value: response['access_token'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_data');
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}
```

### File: `frontend/lib/services/api_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000';
  final AuthService _authService = AuthService();

  // GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _authService.getAccessToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final authToken = token ?? await _authService.getAccessToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: json.encode(data),
      );

      return await _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Handle response
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final data = json.decode(response.body);

    // Handle 401 Unauthorized (token expired)
    if (response.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _authService.refreshAccessToken();
      if (!refreshed) {
        // Refresh failed, logout user
        await _authService.logout();
        // Navigate to login (handled by app)
      }
      return {'success': false, 'error': 'Unauthorized'};
    }

    // Return response data
    return {
      'success': response.statusCode >= 200 && response.statusCode < 300,
      'data': data,
      ...data,
    };
  }
}
```

## 🛡️ Security Best Practices

### Backend Security

1. **Password Hashing**
```python
# Use bcrypt (via werkzeug)
from werkzeug.security import generate_password_hash, check_password_hash

# Hash password before storing
password_hash = generate_password_hash('password123')

# Verify password
is_valid = check_password_hash(password_hash, 'password123')
```

2. **Strong Secret Keys**
```python
# Generate strong secret key
import secrets
secret_key = secrets.token_urlsafe(32)

# Store in .env
JWT_SECRET_KEY=your-super-secret-key-here
```

3. **Token Expiration**
```python
# Short-lived access tokens
JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)

# Long-lived refresh tokens
JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
```

4. **HTTPS Only (Production)**
```python
# Force HTTPS in production
if not app.debug:
    from flask_talisman import Talisman
    Talisman(app, force_https=True)
```

### Frontend Security

1. **Secure Storage**
```dart
// Use FlutterSecureStorage (encrypted)
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
```

2. **Never Log Tokens**
```dart
// DON'T DO THIS:
print('Token: $token');  // ❌

// DO THIS:
if (kDebugMode) {
  print('Token received');  // ✅
}
```

3. **Clear Tokens on Logout**
```dart
Future<void> logout() async {
  await _storage.deleteAll();  // Clear all stored data
}
```

## 🔒 Role-Based Access Control (RBAC)

### Backend Implementation

```python
from functools import wraps
from flask_jwt_extended import get_jwt

def role_required(allowed_roles):
    """Decorator to restrict access by role"""
    def wrapper(fn):
        @wraps(fn)
        @jwt_required()
        def decorator(*args, **kwargs):
            claims = get_jwt()
            user_role = claims.get('role')
            
            if user_role not in allowed_roles:
                return jsonify({'error': 'Forbidden'}), 403
            
            return fn(*args, **kwargs)
        return decorator
    return wrapper

# Usage
@bp.route('/admin/users')
@role_required(['admin'])
def get_users():
    # Only admins can access
    pass

@bp.route('/doctor/appointments')
@role_required(['doctor', 'nurse'])
def get_doctor_appointments():
    # Doctors and nurses can access
    pass
```

### Frontend Route Guards

```dart
class AuthGuard {
  static Future<bool> canAccess(BuildContext context, String role) async {
    final authService = AuthService();
    final userData = await authService.getUserData();
    
    if (userData == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return false;
    }
    
    if (userData['role'] != role) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access denied')),
      );
      return false;
    }
    
    return true;
  }
}

// Usage in screen
@override
void initState() {
  super.initState();
  _checkAccess();
}

Future<void> _checkAccess() async {
  final hasAccess = await AuthGuard.canAccess(context, 'doctor');
  if (!hasAccess) {
    Navigator.pop(context);
  }
}
```

## 🐛 Troubleshooting

### Common Issues

**Issue: "Token has expired"**
```
Solution: Implement automatic token refresh
- Frontend catches 401 errors
- Calls refresh endpoint
- Retries original request
```

**Issue: "Invalid signature"**
```
Solution: Check JWT_SECRET_KEY matches between environments
- Ensure .env file has correct key
- Restart server after changing key
```

**Issue: "No authorization header"**
```
Solution: Ensure frontend sends token
- Check ApiService adds Authorization header
- Verify token is stored after login
```

---

**Next:** Read [Backend Module Guide](./backend-module-guide.md) for code organization.
