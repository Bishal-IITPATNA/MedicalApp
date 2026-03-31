import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

class ApiService {
  final AuthService _authService = AuthService();
  
  // Build full URL from relative path
  String _buildUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.baseUrl}$path';
  }
  
  // Generic GET request
  Future<Map<String, dynamic>> get(String url) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'No access token'};
      }
      
      final fullUrl = _buildUrl(url);
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        // Try refreshing token
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return get(url); // Retry request
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Request failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Generic POST request
  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'No access token'};
      }
      
      final fullUrl = _buildUrl(url);
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return post(url, data); // Retry request
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Validation errors or not found
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'error': error['error'] ?? 'Request failed'};
        } catch (e) {
          return {'success': false, 'error': 'Request failed with status ${response.statusCode}'};
        }
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Request failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Generic PUT request
  Future<Map<String, dynamic>> put(String url, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'No access token'};
      }
      
      final fullUrl = _buildUrl(url);
      final response = await http.put(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return put(url, data); // Retry request
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Request failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String url) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'No access token'};
      }
      
      final fullUrl = _buildUrl(url);
      final response = await http.delete(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return delete(url); // Retry request
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Request failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
