import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton instance
final authService = AuthService();

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userRoleKey = 'user_role';
  static const String _userNimNipKey = 'user_nim_nip';
  static const String _userDepartmentKey = 'user_department';
  static const String _userFacultyKey = 'user_faculty';
  static const String _userAddressKey = 'user_address';
  static const String _userEmergencyNameKey = 'user_emergency_name';
  static const String _userEmergencyPhoneKey = 'user_emergency_phone';
  static const String _userIsVerifiedKey = 'user_is_verified';
  static const String _userManagedBuildingKey = 'user_managed_building';

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
      debugPrint('LOGIN ERROR: $e');
      return {'success': false, 'message': 'Error: $e'};
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
    String? faculty,
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
          'faculty': faculty,
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
      debugPrint('STAFF LOGIN ERROR: $e');
      return {'success': false, 'message': 'Error: $e'};
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
    if (user['phone'] != null) {
      await prefs.setString(_userPhoneKey, user['phone']);
    }
    if (user['nimNip'] != null) {
      await prefs.setString(_userNimNipKey, user['nimNip']);
    }
    if (user['department'] != null) {
      await prefs.setString(_userDepartmentKey, user['department']);
    }
    if (user['faculty'] != null) {
      await prefs.setString(_userFacultyKey, user['faculty']);
    }
    if (user['address'] != null) {
      await prefs.setString(_userAddressKey, user['address']);
    }
    if (user['emergencyName'] != null) {
      await prefs.setString(_userEmergencyNameKey, user['emergencyName']);
    }
    if (user['emergencyPhone'] != null) {
      await prefs.setString(_userEmergencyPhoneKey, user['emergencyPhone']);
    }
    if (user['isVerified'] != null) {
      await prefs.setBool(_userIsVerifiedKey, user['isVerified']);
    }
    // New: Managed Building
    if (user['managedBuilding'] != null) {
      await prefs.setString(_userManagedBuildingKey, user['managedBuilding']);
    }

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
      'faculty': prefs.getString(_userFacultyKey),
      'address': prefs.getString(_userAddressKey),
      'emergencyName': prefs.getString(_userEmergencyNameKey),
      'emergencyPhone': prefs.getString(_userEmergencyPhoneKey),
      'isVerified': prefs.getBool(_userIsVerifiedKey),
      'managedBuilding': prefs.getString(_userManagedBuildingKey),
    };
  }

  // Update Profile (Pelapor or Staff)
  Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String role,
    String? name,
    String? phone,
    String? department,
    String? faculty,
    String? nimNip,
    String? address,
    String? emergencyName,
    String? emergencyPhone,
  }) async {
    try {
      final String endpoint = role == 'pelapor'
          ? '/auth/profile/$id'
          : '/auth/staff-profile/$id';

      final response = await apiService.dio.patch(
        endpoint,
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (department != null) 'department': department,
          if (faculty != null) 'faculty': faculty,
          if (nimNip != null) 'nimNip': nimNip,
          if (address != null) 'address': address,
          if (emergencyName != null) 'emergencyName': emergencyName,
          if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
        },
      );

      if (response.data['status'] == 'success') {
        final updatedUser = response.data['data'];
        await _updateLocalUserData(updatedUser);
        return {'success': true, 'data': updatedUser};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal memperbarui profil',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Method to update local storage only for specific fields
  Future<void> _updateLocalUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    if (user['name'] != null) await prefs.setString(_userNameKey, user['name']);
    if (user['phone'] != null) {
      await prefs.setString(_userPhoneKey, user['phone']);
    }
    if (user['nimNip'] != null) {
      await prefs.setString(_userNimNipKey, user['nimNip']);
    }
    if (user['department'] != null) {
      await prefs.setString(_userDepartmentKey, user['department']);
    }
    if (user['faculty'] != null) {
      await prefs.setString(_userFacultyKey, user['faculty']);
    }
    if (user['address'] != null) {
      await prefs.setString(_userAddressKey, user['address']);
    }
    if (user['emergencyName'] != null) {
      await prefs.setString(_userEmergencyNameKey, user['emergencyName']);
    }
    if (user['emergencyPhone'] != null) {
      await prefs.setString(_userEmergencyPhoneKey, user['emergencyPhone']);
    }
  }

  // Register phone number / Update Profile (Legacy)
  Future<bool> registerPhone({
    required String userId,
    required String phone,
    String? department,
  }) async {
    return false; // Stub for legacy
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

  // Send Password Reset Link
  Future<Map<String, dynamic>> sendPasswordResetLink({
    required String email,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.data['status'] == 'success') {
        return {
          'success': true,
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mengirim link reset password',
      };
    } catch (e) {
      if (e is DioException && e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Terjadi kesalahan pada request',
        };
      }
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: $e',
      };
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.data['status'] == 'success') {
        return {
          'success': true,
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mereset password',
      };
    } catch (e) {
      if (e is DioException && e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Terjadi kesalahan sistem',
        };
      }
      return {
        'success': false,
        'message': 'Gagal mereset password: $e',
      };
    }
  }
}
