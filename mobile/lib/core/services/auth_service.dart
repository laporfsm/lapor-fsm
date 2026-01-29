import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userRoleKey = 'user_role';
  static const String _userNimNipKey = 'user_nim_nip';
  static const String _userDepartmentKey = 'user_department';
  static const String _userAddressKey = 'user_address';
  static const String _userEmergencyNameKey = 'user_emergency_name';
  static const String _userEmergencyPhoneKey = 'user_emergency_phone';
  static const String _userIsVerifiedKey = 'user_is_verified';

  // Login for Pelapor (Email & Password)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['status'] == 'success') {
        final user = response.data['data']['user'];
        final token = response.data['data']['token'];
        final role = response.data['data']['role'] ?? 'pelapor';

        await _saveAuthData(user, token, role);

        return {'success': true, 'user': user, 'role': role};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Email atau password salah'};
    }
  }

  // Register for Pelapor
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String nimNip,
    String? department,
    String? address,
    String? emergencyName,
    String? emergencyPhone,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'nimNip': nimNip,
          'department': department,
          'address': address,
          'emergencyName': emergencyName,
          'emergencyPhone': emergencyPhone,
        },
      );

      if (response.data['status'] == 'success') {
        return {
          'success': true,
          'needsApproval': response.data['data']['needsApproval'],
          'message': response.data['message'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Registrasi gagal',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login for Staff (Email & Password)
  Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/auth/staff-login',
        data: {'email': email, 'password': password},
      );

      if (response.data['status'] == 'success') {
        final user = response.data['data']['user'];
        final token = response.data['data']['token'];
        final role = response.data['data']['role'];

        await _saveAuthData(user, token, role);

        return {'success': true, 'user': user, 'role': role};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login staff gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Email atau password salah'};
    }
  }

  // Shared method to save auth data
  Future<void> _saveAuthData(
    Map<String, dynamic> user,
    String token,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user['id'].toString());
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, user['name']);
    await prefs.setString(_userEmailKey, user['email']);
    await prefs.setString(_userRoleKey, role);

    // Optional fields
    if (user['phone'] != null)
      await prefs.setString(_userPhoneKey, user['phone']);
    if (user['nimNip'] != null)
      await prefs.setString(
        _userNimNipKey,
        user['nimNip'],
      ); // Check if backend sends camelCase or snake_case. Controller sends spread ...user[0], so it matches DB schema but Drizzle/Elysia might verify.
    // Wait, Drizzle keys are camelCase in the schema definition: `nimNip: text('nim_nip')`. When spread ...user[0], it returns the Drizzle object which uses schema keys (camelCase).
    // So 'nimNip' is correct.
    if (user['department'] != null)
      await prefs.setString(_userDepartmentKey, user['department']);
    if (user['address'] != null)
      await prefs.setString(_userAddressKey, user['address']);
    if (user['emergencyName'] != null)
      await prefs.setString(_userEmergencyNameKey, user['emergencyName']);
    if (user['emergencyPhone'] != null)
      await prefs.setString(_userEmergencyPhoneKey, user['emergencyPhone']);
    if (user['isVerified'] != null)
      await prefs.setBool(_userIsVerifiedKey, user['isVerified']);

    apiService.setAuthToken(token);
  }

  // Get current user from local storage
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);

    if (userId == null) return null;

    return {
      'id': userId,
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
      'phone': prefs.getString(_userPhoneKey),
      'role': prefs.getString(_userRoleKey),
      'nimNip': prefs.getString(_userNimNipKey),
      'department': prefs.getString(_userDepartmentKey),
      'address': prefs.getString(_userAddressKey),
      'emergencyName': prefs.getString(_userEmergencyNameKey),
      'emergencyPhone': prefs.getString(_userEmergencyPhoneKey),
      'isVerified': prefs.getBool(_userIsVerifiedKey),
    };
  }

  // Register phone number / Update Profile
  Future<bool> registerPhone({
    required String userId,
    required String phone,
    String? department,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/auth/register-phone',
        data: {'userId': userId, 'phone': phone, 'department': department},
      );

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
