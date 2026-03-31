import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /* =========================
     AUTH & LOGIN
     ========================= */

  Future<Map<String, dynamic>> checkUserRoles(
    String loginId,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/check-roles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_id': loginId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Failed to check roles'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> loginWithRole(
    String loginId,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_id': loginId,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, data['access_token']);
        await prefs.setString(_refreshTokenKey, data['refresh_token']);
        await prefs.setString(_userDataKey, jsonEncode(data['user']));
        return {'success': true, 'data': data};
      }

      return {'success': false, 'error': 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return loginWithRole(email, password, 'patient');
  }

  /* =========================
     PASSWORD RESET FLOW
     ========================= */

  /// Step 1: Request reset OTP
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'],
          'reset_id': data['reset_id'],
          'message': data['message'],
          'email_sent': data['email_sent'],
          'sms_sent': data['sms_sent'],
        };
      }

      return {'success': false, 'error': 'Failed to request reset'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Step 2: Verify OTP
  Future<Map<String, dynamic>> verifyPasswordResetOTP(
    int resetId,
    String otp, {
    String channel = 'email',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/verify-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reset_id': resetId,
          'otp': otp,
          'type': channel,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {'success': false, 'error': 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// ✅ Step 3: Reset password (FIXED SIGNATURE)
  Future<Map<String, dynamic>> resetPassword(
    int resetId,
    String newPassword, {
    String channel = 'email',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reset_id': resetId,
          'new_password': newPassword,
          'type': channel,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {'success': false, 'error': 'Password reset failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /* =========================
     SESSION MANAGEMENT
     ========================= */

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userDataKey);
    if (data != null) {
      return User.fromJson(jsonDecode(data));
    }
    return null;
  }
}
