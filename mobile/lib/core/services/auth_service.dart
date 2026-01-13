import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';

  // Login with SSO (mock)
  Future<Map<String, dynamic>> login({
    required String email,
    required String name,
    String? ssoId,
  }) async {
    try {
      final response = await apiService.dio.post('/auth/login', data: {
        'email': email,
        'name': name,
        'ssoId': ssoId,
      });

      if (response.data['status'] == 'success') {
        final user = response.data['data']['user'];
        final token = response.data['data']['token'];
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userIdKey, user['id']);
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userNameKey, user['name']);
        await prefs.setString(_userEmailKey, user['email']);
        if (user['phone'] != null) {
          await prefs.setString(_userPhoneKey, user['phone']);
        }
        
        // Set token in API service
        apiService.setAuthToken(token);
        
        return {
          'success': true,
          'needsPhone': response.data['data']['needsPhone'],
          'user': user,
        };
      }
      
      return {'success': false, 'message': 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Register phone number
  Future<bool> registerPhone({
    required int userId,
    required String phone,
    String? department,
  }) async {
    try {
      final response = await apiService.dio.post('/auth/register-phone', data: {
        'userId': userId,
        'phone': phone,
        'department': department,
      });

      if (response.data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userPhoneKey, phone);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get current user from local storage
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    
    if (userId == null) return null;
    
    return {
      'id': userId,
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
      'phone': prefs.getString(_userPhoneKey),
    };
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userIdKey);
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    apiService.clearAuthToken();
  }
}

// Singleton instance
final authService = AuthService();
