# Authentication & Authorization Flow

Complete guide to the authentication system in Medical App.

## 📋 Overview

The app uses **JWT (JSON Web Token)** based authentication with role-based access control.

**Supported Roles:**
- `patient` - Book appointments, order medicines, view prescriptions
- `doctor` - View appointments, write prescriptions, manage schedule
- `medical_store` - Manage medicine inventory, process orders
- `lab_store` - Manage lab tests, process test orders
- `admin` - Full system access, analytics, user management

---

## 🔐 Authentication Flow

### Registration Flow

```
┌─────────┐         ┌──────────┐         ┌──────────┐
│         │         │          │         │          │
│ Client  │────────▶│ Backend  │────────▶│ Database │
│         │  1      │          │  2      │          │
└─────────┘         └──────────┘         └──────────┘
    │                     │                     │
    │                     │◀────────────────────┘
    │                     │         3
    │◀────────────────────│
    │         4           │
    │                     │
```

**Steps:**

1. **Client sends registration request**
```dart
// lib/services/auth_service.dart
Future<Map<String, dynamic>> register(String email, String password, String role) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
      'role': role,
    }),
  );
  return json.decode(response.body);
}
```

2. **Backend validates and creates user**
```python
# app/routes/auth.py
@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # Validate email
    if User.query.filter_by(email=data['email']).first():
        return {'success': False, 'error': 'Email already registered'}, 400
    
    # Create user
    user = User(email=data['email'], role=data['role'])
    user.set_password(data['password'])  # Hashes password
    
    db.session.add(user)
    db.session.commit()
    
    # Create role-specific profile
    if data['role'] == 'patient':
        patient = Patient(user_id=user.id)
        db.session.add(patient)
    elif data['role'] == 'doctor':
        doctor = Doctor(user_id=user.id)
        db.session.add(doctor)
    # ... other roles
    
    db.session.commit()
    
    return {'success': True, 'message': 'Registration successful'}
```

3. **User and profile created in database**
```sql
INSERT INTO user (email, password_hash, role, created_at) 
VALUES ('test@test.com', 'hashed_password', 'patient', '2024-01-01');

INSERT INTO patient (user_id, created_at)
VALUES (1, '2024-01-01');
```

4. **Client receives success response**
```json
{
  "success": true,
  "message": "Registration successful"
}
```

---

### Login Flow

```
┌─────────┐         ┌──────────┐         ┌──────────┐
│         │    1    │          │    2    │          │
│ Client  │────────▶│ Backend  │────────▶│ Database │
│         │         │          │◀────────│          │
└─────────┘         └──────────┘    3    └──────────┘
    │                     │
    │◀────────────────────│
    │         4           │
    │  (Store token)      │
    │                     │
```

**Steps:**

1. **Client sends login request**
```dart
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
    }),
  );
  return json.decode(response.body);
}
```

2. **Backend verifies credentials**
```python
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    # Find user
    user = User.query.filter_by(email=data['email']).first()
    
    # Verify password
    if not user or not user.check_password(data['password']):
        return {'success': False, 'error': 'Invalid credentials'}, 401
    
    # Generate tokens
    access_token = create_access_token(identity=user.id)
    refresh_token = create_refresh_token(identity=user.id)
    
    return {
        'success': True,
        'access_token': access_token,
        'refresh_token': refresh_token,
        'role': user.role,
        'user_id': user.id
    }
```

3. **Database query validates user**
```sql
SELECT id, email, password_hash, role 
FROM user 
WHERE email = 'test@test.com';
```

4. **Client stores tokens**
```dart
// Store tokens securely
await storage.write(key: 'access_token', value: tokens['access_token']);
await storage.write(key: 'refresh_token', value: tokens['refresh_token']);
await storage.write(key: 'user_role', value: tokens['role']);

// Navigate based on role
if (tokens['role'] == 'patient') {
  Navigator.pushReplacementNamed(context, '/patient/dashboard');
} else if (tokens['role'] == 'doctor') {
  Navigator.pushReplacementNamed(context, '/doctor/dashboard');
}
// ... other roles
```

---

## 🔑 JWT Token Structure

### Access Token

**Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "fresh": false,
  "iat": 1704067200,
  "jti": "abc123-def456",
  "type": "access",
  "sub": 1,              // User ID
  "nbf": 1704067200,
  "exp": 1704153600      // Expires in 24 hours
}
```

**Signature:**
```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret_key
)
```

---

## 🛡️ Protected Requests

### Making Authenticated API Calls

**Frontend:**
```dart
// lib/services/api_service.dart
class ApiService {
  final AuthService _authService = AuthService();
  
  Future<Map<String, dynamic>> get(String endpoint) async {
    // Get token from storage
    final token = await _authService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // Add token here
      },
    );
    
    // Handle token expiration
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry request with new token
        return get(endpoint);
      } else {
        // Redirect to login
        throw Exception('Session expired');
      }
    }
    
    return json.decode(response.body);
  }
}
```

**Backend:**
```python
# app/routes/patient.py
from flask_jwt_extended import jwt_required, get_jwt_identity

@patient_bp.route('/profile', methods=['GET'])
@jwt_required()  # Requires valid JWT token
def get_profile():
    # Get user ID from token
    user_id = get_jwt_identity()
    
    # Fetch user data
    user = User.query.get(user_id)
    patient = Patient.query.filter_by(user_id=user_id).first()
    
    return {
        'success': True,
        'data': {
            'email': user.email,
            'phone': patient.phone,
            'address': patient.address
        }
    }
```

---

## 🔄 Token Refresh

When access token expires (after 24 hours), use refresh token:

**Frontend:**
```dart
Future<bool> refreshToken() async {
  try {
    final refreshToken = await storage.read(key: 'refresh_token');
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
      headers: {
        'Authorization': 'Bearer $refreshToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await storage.write(key: 'access_token', value: data['access_token']);
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}
```

**Backend:**
```python
@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=user_id)
    
    return {
        'access_token': new_access_token
    }
```

---

## 👤 Role-Based Access Control

### Restricting Endpoints by Role

**Backend:**
```python
from functools import wraps
from flask_jwt_extended import get_jwt_identity

def role_required(required_role):
    def decorator(fn):
        @wraps(fn)
        @jwt_required()
        def wrapper(*args, **kwargs):
            user_id = get_jwt_identity()
            user = User.query.get(user_id)
            
            if user.role != required_role:
                return {'error': 'Access denied'}, 403
            
            return fn(*args, **kwargs)
        return wrapper
    return decorator

# Usage
@doctor_bp.route('/appointments', methods=['GET'])
@role_required('doctor')
def get_appointments():
    # Only accessible by doctors
    user_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(user_id=user_id).first()
    appointments = Appointment.query.filter_by(doctor_id=doctor.id).all()
    return {'appointments': [a.to_dict() for a in appointments]}
```

### Frontend Route Guards

```dart
// lib/utils/route_guard.dart
class RouteGuard {
  static Future<bool> canAccess(String route, BuildContext context) async {
    final storage = FlutterSecureStorage();
    final role = await storage.read(key: 'user_role');
    
    // Define role-based routes
    final roleRoutes = {
      'patient': ['/patient/dashboard', '/patient/appointments', '/patient/medicines'],
      'doctor': ['/doctor/dashboard', '/doctor/appointments', '/doctor/prescriptions'],
      'medical_store': ['/medical-store/dashboard', '/medical-store/orders'],
      // ... other roles
    };
    
    if (role == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return false;
    }
    
    final allowedRoutes = roleRoutes[role] ?? [];
    return allowedRoutes.any((r) => route.startsWith(r));
  }
}

// Usage in route
onGenerateRoute: (settings) {
  RouteGuard.canAccess(settings.name!, context).then((allowed) {
    if (!allowed) {
      return MaterialPageRoute(builder: (_) => UnauthorizedScreen());
    }
    // Return actual route
  });
}
```

---

## 🔒 Security Best Practices

### 1. Password Hashing
```python
# app/models.py
from werkzeug.security import generate_password_hash, check_password_hash

class User(db.Model):
    password_hash = db.Column(db.String(200))
    
    def set_password(self, password):
        # Uses pbkdf2:sha256 by default
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
```

### 2. Token Expiration
```python
# config.py
from datetime import timedelta

class Config:
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
```

### 3. Secure Token Storage
```dart
// Use FlutterSecureStorage, NOT SharedPreferences
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
```

### 4. HTTPS Only
```python
# In production
app.config['SESSION_COOKIE_SECURE'] = True
app.config['REMEMBER_COOKIE_SECURE'] = True
```

### 5. CORS Configuration
```python
from flask_cors import CORS

# Only allow specific origins
CORS(app, origins=[
    'https://your-frontend.com',
    'http://localhost:3000'  # Development only
])
```

---

## 🧪 Testing Authentication

### Backend Tests

```python
# tests/test_auth.py
def test_registration(client):
    response = client.post('/api/auth/register', json={
        'email': 'test@test.com',
        'password': 'password123',
        'role': 'patient'
    })
    assert response.status_code == 201
    assert response.json['success'] == True

def test_login(client):
    # Register first
    client.post('/api/auth/register', json={...})
    
    # Then login
    response = client.post('/api/auth/login', json={
        'email': 'test@test.com',
        'password': 'password123'
    })
    assert response.status_code == 200
    assert 'access_token' in response.json

def test_protected_route_without_token(client):
    response = client.get('/api/patient/profile')
    assert response.status_code == 401

def test_protected_route_with_token(client, auth_headers):
    response = client.get('/api/patient/profile', headers=auth_headers)
    assert response.status_code == 200
```

### Frontend Tests

```dart
// test/services/auth_service_test.dart
testWidgets('Login with valid credentials', (tester) async {
  final authService = AuthService();
  
  final result = await authService.login('test@test.com', 'password123');
  
  expect(result['success'], true);
  expect(result['access_token'], isNotNull);
  expect(result['role'], 'patient');
});

testWidgets('Login with invalid credentials', (tester) async {
  final authService = AuthService();
  
  final result = await authService.login('test@test.com', 'wrong_password');
  
  expect(result['success'], false);
  expect(result['error'], 'Invalid credentials');
});
```

---

## 📊 Authentication Flow Diagram

```
Registration:
Client                Backend              Database
  |                     |                     |
  |-- POST /register -->|                     |
  |   {email,pwd,role}  |                     |
  |                     |                     |
  |                     |-- Check email ----->|
  |                     |<-- Not exists ------| 
  |                     |                     |
  |                     |-- Hash password     |
  |                     |-- Create user ----->|
  |                     |-- Create profile -->|
  |                     |<-- Success ---------|
  |                     |                     |
  |<-- 201 Created -----|                     |
  |   {success: true}   |                     |

Login:
Client                Backend              Database
  |                     |                     |
  |-- POST /login ----->|                     |
  |   {email,pwd}       |                     |
  |                     |                     |
  |                     |-- Find user ------->|
  |                     |<-- User data -------|
  |                     |                     |
  |                     |-- Verify password   |
  |                     |-- Generate JWT      |
  |                     |                     |
  |<-- 200 OK ----------|                     |
  |   {token,role}      |                     |
  |                     |                     |
  |-- Store token       |                     |
  |   in secure storage |                     |

Authenticated Request:
Client                Backend              Database
  |                     |                     |
  |-- GET /profile ---->|                     |
  |   Authorization:    |                     |
  |   Bearer <token>    |                     |
  |                     |                     |
  |                     |-- Verify JWT        |
  |                     |-- Extract user_id   |
  |                     |                     |
  |                     |-- Get profile ----->|
  |                     |<-- Profile data ----|
  |                     |                     |
  |<-- 200 OK ----------|                     |
  |   {user data}       |                     |
```

---

**Next:** See [Appointment System](./appointment-system.md) for booking flow.
