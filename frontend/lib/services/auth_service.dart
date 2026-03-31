import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  // Keys for storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  
  // Check what roles are available for a user
  Future<Map<String, dynamic>> checkUserRoles(String loginId, String password) async {
    try {
      print('🔍 AuthService: checkUserRoles called for: $loginId'); // Debug log
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/check-roles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_id': loginId,
          'password': password,
        }),
      );
      
      print('🔍 AuthService: Check roles response status: ${response.statusCode}'); // Debug log
      print('🔍 AuthService: Check roles response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to check roles'};
      }
    } catch (e) {
      print('🔍 AuthService: Exception in checkUserRoles: $e'); // Debug log
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Login with role selection
  Future<Map<String, dynamic>> loginWithRole(String loginId, String password, String role) async {
    try {
      print('🔍 AuthService: loginWithRole called with role: $role'); // Debug log
      
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_id': loginId,
          'password': password,
          'role': role,
        }),
      );
      
      print('🔍 AuthService: Response status: ${response.statusCode}'); // Debug log
      print('🔍 AuthService: Response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store tokens and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, data['access_token']);
        await prefs.setString(_refreshTokenKey, data['refresh_token']);
        await prefs.setString(_userDataKey, jsonEncode(data['user']));
        
        print('🔍 AuthService: User data stored: ${data['user']}'); // Debug log
        
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Login failed'};
      }
    } catch (e) {
      print('🔍 AuthService: Exception occurred: $e'); // Debug log
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Original login method for backward compatibility
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await loginWithRole(email, password, 'patient');
  }
  
  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('🔍 Sending registration request to: ${ApiConstants.register}'); // Debug logging
      print('🔍 Request data: $userData'); // Debug logging
      
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      
      print('🔍 Registration response status: ${response.statusCode}'); // Debug logging
      print('🔍 Registration response body: ${response.body}'); // Debug logging
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          print('🔍 Decoded data: $data'); // Debug logging
          print('🔍 Data type: ${data.runtimeType}'); // Debug logging
          print('🔍 Success value: ${data['success']}'); // Debug logging
          print('🔍 Success type: ${data['success'].runtimeType}'); // Debug logging
          
          // Check if this is OTP verification response (new flow)
          if (data['success'] == true && data['verification_id'] != null) {
            print('✅ OTP verification flow detected'); // Debug logging
            // This is OTP verification flow, don't store tokens yet
            final result = {
              'success': true, 
              'verification_id': data['verification_id'], 
              'message': data['message'] ?? 'OTP sent successfully',
              'phone_available': data['phone_available'] ?? false,
              'email_sent': data['email_sent'] ?? false,
              'sms_sent': data['sms_sent'] ?? false,
            };
            print('🔍 Returning result: $result'); // Debug logging
            return result;
          }
          
          // Check if backend returned success: false
          if (data['success'] == false) {
            print('❌ Backend returned success: false'); // Debug logging
            return {'success': false, 'error': data['error'] ?? data['message'] ?? 'Registration failed'};
          }
          
          // Old flow - store tokens immediately (for backward compatibility)
          if (data['access_token'] != null) {
            print('✅ Old flow with tokens detected'); // Debug logging
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_accessTokenKey, data['access_token']);
            await prefs.setString(_refreshTokenKey, data['refresh_token']);
            await prefs.setString(_userDataKey, jsonEncode(data['user']));
          }
          
          return {'success': true, 'data': data};
        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError'); // Debug logging
          return {'success': false, 'error': 'Failed to parse response: $jsonError'};
        }
      } else {
        print('❌ HTTP error status: ${response.statusCode}'); // Debug logging
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'error': error['error'] ?? 'Registration failed'};
        } catch (e) {
          return {'success': false, 'error': 'Registration failed with status ${response.statusCode}'};
        }
      }
    } catch (e) {
      print('❌ Exception in register: $e'); // Debug logging
      print('❌ Exception type: ${e.runtimeType}'); // Debug logging
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(int verificationId, String otp, String type) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verification_id': verificationId,
          'otp': otp,
          'type': type,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Store tokens after successful verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, data['access_token']);
        await prefs.setString(_refreshTokenKey, data['refresh_token']);
        await prefs.setString(_userDataKey, jsonEncode(data['user']));
        
        return {'success': true, 'data': data, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'OTP verification failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(int verificationId, String type) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verification_id': verificationId,
          'type': type,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to resend OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
  }
  
  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  // Get user data
  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
  
  // Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await http.post(
        Uri.parse(ApiConstants.refresh),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Get current user from API
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'No access token'};
      }
      
      final response = await http.get(
        Uri.parse(ApiConstants.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode(data['user']));
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get user data'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Forgot Password - Request reset OTP
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'],
          'message': data['message'],
          'reset_id': data['reset_id'],
          'phone_available': data['phone_available'],
          'email_sent': data['email_sent'],
          'sms_sent': data['sms_sent'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Verify Password Reset OTP
  Future<Map<String, dynamic>> verifyPasswordResetOTP(int resetId, String otp, String type) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/verify-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reset_id': resetId,
          'otp': otp,
          'type': type,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'],
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to verify OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Resend Password Reset OTP
  Future<Map<String, dynamic>> resendPasswordResetOTP(int resetId, String type) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/resend-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reset_id': resetId,
          'type': type,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'],
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to resend OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Reset Password - Reset password with verified OTP
  Future<Map<String, dynamic>> resetPassword(int resetId, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reset_id': resetId,
          'new_password': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': data['success'], 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Change Password - Change password while logged in
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
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
}
