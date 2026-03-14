# Password Management Guide

Complete guide to password management features in Medical App.

## 📋 Overview

The Medical App includes comprehensive password management functionality:
- **Change Password** - Update password while logged in
- **Forgot Password** - Request password reset via email/notifications  
- **Reset Password** - Reset password using secure token
- **Security Notifications** - Users notified of all password changes

## 🔐 Security Features

- **Password Hashing**: PBKDF2-SHA256 via Werkzeug
- **Reset Tokens**: URL-safe 32-byte tokens  
- **Token Expiry**: 1-hour validity for reset tokens
- **Email Enumeration Prevention**: Always returns success for forgot password
- **Security Notifications**: All password changes trigger notifications
- **Minimum Password Length**: 6 characters required

---

## 🔄 Password Management Flows

### 1. Change Password Flow (Authenticated Users)

**Use Case:** User wants to update their password while logged in.

**Frontend Implementation:**

**File:** `lib/screens/auth/change_password_screen.dart` (to be created)

```dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to change password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**AuthService Method:**

**File:** `lib/services/auth_service.dart`

```dart
// Change Password - Change password while logged in
Future<Map<String, dynamic>> changePassword(
  String currentPassword,
  String newPassword,
) async {
  try {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'error': 'No access token'};
    }
    
    final response = await http.post(
      Uri.parse(ApiConstants.changePassword),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['error'] ?? 'Failed to change password'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection error: $e'};
  }
}
```

**Backend Implementation:**

**File:** `backend/app/routes/auth.py`

```python
@auth_bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change password for authenticated user"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user:
        return {'success': False, 'error': 'User not found'}, 404
    
    data = request.get_json()
    
    # Verify current password
    if not user.check_password(data.get('current_password', '')):
        return {'success': False, 'error': 'Current password is incorrect'}, 400
    
    # Validate new password
    new_password = data.get('new_password', '')
    if len(new_password) < 6:
        return {'success': False, 'error': 'Password must be at least 6 characters'}, 400
    
    # Update password
    user.set_password(new_password)
    db.session.commit()
    
    # Send security notification
    notification = Notification(
        user_id=user.id,
        title='Password Changed',
        message='Your password has been changed successfully. If this wasn\'t you, please contact support immediately.',
        type='security'
    )
    db.session.add(notification)
    db.session.commit()
    
    return {
        'success': True,
        'message': 'Password changed successfully'
    }, 200
```

---

### 2. Forgot Password Flow (Unauthenticated)

**Use Case:** User forgot their password and needs to reset it.

**Step 1: Request Reset Token**

**Frontend Implementation:**

**File:** `lib/screens/auth/forgot_password_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.forgotPassword(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        // Show success message with token
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset Token'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A password reset token has been sent to your notifications.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Your reset token:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    result['data']['token'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Copy this token and use it to reset your password. Token expires in 1 hour.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(
                    context,
                    '/reset-password',
                    arguments: _emailController.text.trim(),
                  );
                },
                child: const Text('Continue to Reset Password'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send reset token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Your Password',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestPasswordReset,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Send Reset Token'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**AuthService Method:**

```dart
// Forgot Password - Request reset token
Future<Map<String, dynamic>> forgotPassword(String email) async {
  try {
    final response = await http.post(
      Uri.parse(ApiConstants.forgotPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['error'] ?? 'Failed to send reset token'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection error: $e'};
  }
}
```

**Backend Implementation:**

**File:** `backend/app/routes/auth.py`

```python
@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Request password reset token"""
    data = request.get_json()
    email = data.get('email', '').strip()
    
    user = User.query.filter_by(email=email).first()
    
    if user:
        # Generate secure reset token
        reset_token = user.generate_reset_token()
        db.session.commit()
        
        # Send notification with token
        notification = Notification(
            user_id=user.id,
            title='Password Reset Request',
            message=f'Your password reset token is: {reset_token}\\n\\nThis token will expire in 1 hour. If you did not request this, please ignore this message.',
            type='password_reset'
        )
        db.session.add(notification)
        db.session.commit()
        
        # In development, return token; in production, only send via email
        return {
            'success': True,
            'message': 'Password reset token has been generated. Please check your notifications for the reset token.',
            'token': reset_token  # Remove this in production
        }, 200
    
    # Always return success to prevent email enumeration
    return {
        'success': True,
        'message': 'If the email exists, a reset token has been sent.'
    }, 200
```

**Step 2: Reset Password with Token**

**Frontend Implementation:**

**File:** `lib/screens/auth/reset_password_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get email from navigation arguments if provided
    final email = ModalRoute.of(context)?.settings.arguments as String?;
    if (email != null && _emailController.text.isEmpty) {
      _emailController.text = email;
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(
      _emailController.text.trim(),
      _tokenController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text(
              'Your password has been reset successfully. You can now login with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to reset password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Reset Token'),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**AuthService Method:**

```dart
// Reset Password - Reset password with token
Future<Map<String, dynamic>> resetPassword(
  String email,
  String token,
  String newPassword,
) async {
  try {
    final response = await http.post(
      Uri.parse(ApiConstants.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'reset_token': token,
        'new_password': newPassword,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['error'] ?? 'Failed to reset password'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection error: $e'};
  }
}
```

**Backend Implementation:**

**File:** `backend/app/routes/auth.py`

```python
@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password using token"""
    data = request.get_json()
    email = data.get('email', '').strip()
    reset_token = data.get('reset_token', '').strip()
    new_password = data.get('new_password', '')
    
    user = User.query.filter_by(email=email).first()
    
    if not user:
        return {'success': False, 'error': 'User not found'}, 404
    
    # Verify reset token
    if not user.verify_reset_token(reset_token):
        return {'success': False, 'error': 'Invalid or expired reset token'}, 400
    
    # Validate new password
    if len(new_password) < 6:
        return {'success': False, 'error': 'Password must be at least 6 characters'}, 400
    
    # Update password
    user.set_password(new_password)
    user.clear_reset_token()
    db.session.commit()
    
    # Send security notification
    notification = Notification(
        user_id=user.id,
        title='Password Reset Successful',
        message='Your password has been successfully reset. If this wasn\'t you, please contact support immediately.',
        type='security'
    )
    db.session.add(notification)
    db.session.commit()
    
    return {
        'success': True,
        'message': 'Password reset successfully. You can now login with your new password.'
    }, 200
```

---

## 💾 Database Model Updates

**File:** `backend/app/models/user.py`

```python
import secrets
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from app import db

class User(db.Model):
    __tablename__ = 'user'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.Enum('patient', 'doctor', 'nurse', 'medical_store', 'lab_store', 'admin'), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Password reset fields
    reset_token = db.Column(db.String(100), nullable=True)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)
    
    def set_password(self, password):
        """Hash and set user password"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Verify password"""
        return check_password_hash(self.password_hash, password)
    
    def generate_reset_token(self):
        """Generate secure password reset token"""
        self.reset_token = secrets.token_urlsafe(32)
        self.reset_token_expiry = datetime.utcnow() + timedelta(hours=1)
        return self.reset_token
    
    def verify_reset_token(self, token):
        """Verify reset token is valid and not expired"""
        if not self.reset_token or not self.reset_token_expiry:
            return False
        if self.reset_token != token:
            return False
        if datetime.utcnow() > self.reset_token_expiry:
            return False
        return True
    
    def clear_reset_token(self):
        """Clear reset token after use"""
        self.reset_token = None
        self.reset_token_expiry = None
```

---

## 🎯 API Routes Summary

### Password Management Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/api/auth/change-password` | Yes | Change password while logged in |
| POST | `/api/auth/forgot-password` | No | Request password reset token |
| POST | `/api/auth/reset-password` | No | Reset password with token |

---

## 🧪 Testing

### Manual Testing

```bash
# 1. Test forgot password
curl -X POST http://localhost:5001/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"testpatient2@medical.com"}'

# 2. Test reset password (use token from response)
curl -X POST http://localhost:5001/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email":"testpatient2@medical.com",
    "reset_token":"TOKEN_HERE",
    "new_password":"newPassword123"
  }'

# 3. Test change password (requires login first)
curl -X POST http://localhost:5001/api/auth/change-password \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "current_password":"password123",
    "new_password":"newPassword123"
  }'
```

---

## 🔒 Security Best Practices

1. **Always hash passwords** - Never store plain text passwords
2. **Use secure tokens** - `secrets.token_urlsafe()` generates cryptographically secure tokens
3. **Set token expiry** - Reset tokens expire after 1 hour
4. **Prevent email enumeration** - Always return success for forgot password
5. **Send security notifications** - Notify users of all password changes
6. **Validate password strength** - Minimum 6 characters (can be increased)
7. **Clear old tokens** - Remove reset tokens after use or expiry
8. **Use HTTPS** - Always use encrypted connections in production

---

## 📚 Related Documentation

- [Authentication Flow](./authentication-flow.md) - JWT authentication details
- [Frontend Screens](../03-frontend/frontend-screens.md) - UI implementation
- [API Integration](../03-frontend/api-integration.md) - API service patterns
- [API Endpoints](../02-backend/api-endpoints.md) - Complete API reference

---

**Last Updated:** November 27, 2025
