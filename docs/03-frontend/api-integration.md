# API Integration Guide

Complete guide to integrating frontend with backend APIs.

## 🎯 API Service Architecture

```
Screen/Widget
    ↓
ApiService (HTTP layer)
    ↓
Network Request
    ↓
Backend API
    ↓
Response
    ↓
Model (fromJson)
    ↓
Screen/Widget (setState)
```

## 📡 ApiService Implementation

**File:** `lib/services/api_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ApiService {
  // Configuration
  static const String baseUrl = 'http://localhost:5000';
  
  final AuthService _authService = AuthService();

  // GET Request
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

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await _authService.getAccessToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Handle HTTP Response
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final data = json.decode(response.body);

    // Success (200-299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': data,
        ...data, // Merge response data
      };
    }

    // Unauthorized (401) - Token expired
    if (response.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _authService.refreshAccessToken();
      
      if (refreshed) {
        // Token refreshed, caller should retry
        return {
          'success': false,
          'error': 'Token refreshed, please retry',
          'should_retry': true,
        };
      } else {
        // Refresh failed, logout user
        await _authService.logout();
        return {
          'success': false,
          'error': 'Session expired, please login again',
          'should_logout': true,
        };
      }
    }

    // Other errors
    return {
      'success': false,
      'error': data['error'] ?? 'Request failed',
      'status_code': response.statusCode,
    };
  }
}
```

## 🔐 Authenticated Requests

### Automatic Token Injection

```dart
// Token is automatically added by ApiService
final response = await apiService.get('/api/patient/profile');

// Under the hood, ApiService adds:
// headers: {
//   'Authorization': 'Bearer eyJhbGci...',
//   'Content-Type': 'application/json',
// }
```

### Token Refresh Flow

```dart
// User makes request → Token expired → Auto-refresh → Retry

// 1. Initial request
final response = await apiService.get('/api/patient/appointments');

// 2. If 401, ApiService automatically:
//    - Calls refreshAccessToken()
//    - Returns {success: false, should_retry: true}

// 3. Your screen handles retry:
Future<void> _loadAppointments() async {
  var response = await apiService.get('/api/patient/appointments');
  
  if (response['should_retry'] == true) {
    // Retry once after token refresh
    response = await apiService.get('/api/patient/appointments');
  }
  
  if (response['should_logout'] == true) {
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }
  
  if (response['success']) {
    setState(() {
      _appointments = (response['data'] as List)
          .map((json) => Appointment.fromJson(json))
          .toList();
    });
  }
}
```

## 📥 API Call Patterns

### Pattern 1: Simple GET Request

```dart
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _apiService.get('/api/patient/profile');

    if (response['success']) {
      setState(() {
        _profile = response['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response['error'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return _buildProfile();
  }
}
```

### Pattern 2: POST Request with Form Data

```dart
Future<void> _bookAppointment() async {
  final data = {
    'doctor_id': widget.doctorId,
    'chamber_id': _selectedChamberId,
    'appointment_date': _selectedDateTime.toIso8601String(),
    'problem_description': _problemController.text,
  };

  setState(() => _isLoading = true);

  final response = await apiService.post(
    '/api/patient/appointments',
    data,
  );

  setState(() => _isLoading = false);

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment booked successfully!')),
    );
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['error'] ?? 'Booking failed'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Pattern 3: PUT Request (Update)

```dart
Future<void> _updateProfile() async {
  final updates = {
    'name': _nameController.text,
    'phone': _phoneController.text,
    'address': _addressController.text,
  };

  setState(() => _isLoading = true);

  final response = await apiService.put(
    '/api/patient/profile',
    updates,
  );

  setState(() => _isLoading = false);

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated!')),
    );
    Navigator.pop(context);
  } else {
    _showError(response['error']);
  }
}
```

### Pattern 4: DELETE Request

```dart
Future<void> _deleteChamber(int chamberId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Delete'),
      content: Text('Are you sure you want to delete this chamber?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final response = await apiService.delete(
    '/api/doctor/chambers/$chamberId',
  );

  if (response['success']) {
    setState(() {
      _chambers.removeWhere((c) => c.id == chamberId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chamber deleted')),
    );
  } else {
    _showError(response['error']);
  }
}
```

## 🔄 Data Model Conversion

### Model Class with fromJson

```dart
class Appointment {
  final int id;
  final int patientId;
  final int doctorId;
  final String doctorName;
  final DateTime appointmentDate;
  final String status;
  final String? problemDescription;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDate,
    required this.status,
    this.problemDescription,
  });

  // Convert JSON to Appointment object
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      status: json['status'],
      problemDescription: json['problem_description'],
    );
  }

  // Convert Appointment object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': status,
      'problem_description': problemDescription,
    };
  }
}
```

### Usage in API Call

```dart
Future<List<Appointment>> _loadAppointments() async {
  final response = await apiService.get('/api/patient/appointments');

  if (response['success']) {
    return (response['data'] as List)
        .map((json) => Appointment.fromJson(json))
        .toList();
  }

  return [];
}

// In your widget
List<Appointment> _appointments = [];

@override
void initState() {
  super.initState();
  _loadAppointments().then((appointments) {
    setState(() {
      _appointments = appointments;
    });
  });
}
```

## 🌐 Environment Configuration

### Development vs Production

```dart
class ApiConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static String get baseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.medical-app.com';
      case 'staging':
        return 'https://staging-api.medical-app.com';
      default:
        return 'http://localhost:5000';
    }
  }
}

// In ApiService
class ApiService {
  static final String baseUrl = ApiConfig.baseUrl;
  // ...
}

// Run with environment variable
// flutter run --dart-define=ENV=production
```

### Testing on Physical Device

```dart
// Find your computer's IP address
// macOS: ifconfig | grep "inet " | grep -v 127.0.0.1
// Windows: ipconfig

class ApiService {
  // Use computer's local IP for physical device testing
  static const String baseUrl = 'http://192.168.1.100:5000';
  
  // Or use localhost for simulator
  // static const String baseUrl = 'http://localhost:5000';
}
```

## ⚡ Performance Optimization

### Caching API Responses

```dart
class CachedApiService {
  final ApiService _apiService = ApiService();
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  static const cacheDuration = Duration(minutes: 5);

  Future<Map<String, dynamic>> getCached(String endpoint) async {
    final timestamp = _cacheTimestamps[endpoint];
    
    // Check if cached and not expired
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < cacheDuration) {
      return _cache[endpoint]!;
    }

    // Fetch from API
    final response = await _apiService.get(endpoint);
    
    if (response['success']) {
      _cache[endpoint] = response;
      _cacheTimestamps[endpoint] = DateTime.now();
    }

    return response;
  }

  void clearCache([String? endpoint]) {
    if (endpoint != null) {
      _cache.remove(endpoint);
      _cacheTimestamps.remove(endpoint);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
}
```

### Debouncing Search Requests

```dart
import 'dart:async';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Doctor> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start new timer (wait 500ms before searching)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final response = await _apiService.get(
      '/api/doctor/search?name=$query',
    );

    if (response['success']) {
      setState(() {
        _results = (response['data'] as List)
            .map((json) => Doctor.fromJson(json))
            .toList();
      });
    }
  }
}
```

## 🐛 Error Handling

### Comprehensive Error Handler

```dart
class ErrorHandler {
  static void handle(BuildContext context, Map<String, dynamic> response) {
    if (response['should_logout'] == true) {
      // Session expired
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final error = response['error'] ?? 'An error occurred';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

// Usage
final response = await apiService.post('/api/patient/appointments', data);

if (!response['success']) {
  ErrorHandler.handle(context, response);
  return;
}

// Continue with success flow...
```

## 🔐 Password Management APIs

### Change Password (Authenticated)

**Method:** `AuthService.changePassword()`

```dart
Future<void> _changePassword() async {
  final authService = AuthService();
  
  final response = await authService.changePassword(
    _currentPasswordController.text,
    _newPasswordController.text,
  );

  if (response['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['error'] ?? 'Failed to change password'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**API Endpoint:** `POST /api/auth/change-password`

**Request:**
```json
{
  "current_password": "oldPassword123",
  "new_password": "newPassword123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

### Forgot Password (Request Reset Token)

**Method:** `AuthService.forgotPassword()`

```dart
Future<void> _requestPasswordReset() async {
  final authService = AuthService();
  
  final response = await authService.forgotPassword(
    _emailController.text.trim(),
  );

  if (response['success']) {
    // Show token dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Password Reset Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your reset token:'),
            SizedBox(height: 10),
            SelectableText(
              response['data']['token'],
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Copy this token to reset your password.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamed(
                context,
                '/reset-password',
                arguments: _emailController.text.trim(),
              );
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
}
```

**API Endpoint:** `POST /api/auth/forgot-password`

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "If email exists, reset token has been sent",
  "data": {
    "token": "abc123xyz789..." 
  }
}
```

**Note:** In production, token should be sent via email, not in response.

### Reset Password (Using Token)

**Method:** `AuthService.resetPassword()`

```dart
Future<void> _resetPassword() async {
  if (_newPasswordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final authService = AuthService();
  
  final response = await authService.resetPassword(
    _emailController.text.trim(),
    _tokenController.text.trim(),
    _newPasswordController.text,
  );

  if (response['success']) {
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(
          'Your password has been reset successfully. '
          'You can now login with your new password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false, // Remove all routes
              );
            },
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['error'] ?? 'Failed to reset password'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**API Endpoint:** `POST /api/auth/reset-password`

**Request:**
```json
{
  "email": "user@example.com",
  "token": "abc123xyz789...",
  "new_password": "newPassword123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

**Security Notes:**
- Token expires in 1 hour
- Token is single-use (cleared after successful reset)
- Email enumeration prevention (always returns success)
- Minimum password length: 6 characters

## 📚 Summary

**Key Concepts:**
- Centralized ApiService for all HTTP requests
- Automatic token management and refresh
- Consistent error handling
- Model classes with fromJson/toJson
- Caching and debouncing for performance

**Best Practices:**
- Always check `response['success']` before processing
- Handle network errors gracefully
- Show loading indicators during requests
- Provide user feedback (success/error messages)
- Use models for type safety
- Cache when appropriate

---

**Next:** Read [Frontend Module Guide](./frontend-module-guide.md) for team organization.
