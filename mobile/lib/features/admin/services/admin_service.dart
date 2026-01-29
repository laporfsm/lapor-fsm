import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/api_service.dart';

class AdminService {
  final ValueNotifier<int> pendingUserCount = ValueNotifier<int>(0);

  // Fetch pending count
  Future<void> fetchPendingUserCount() async {
    try {
      final response = await apiService.dio.get('/admin/users/pending');
      if (response.data['status'] == 'success') {
        final List data = response.data['data'];
        pendingUserCount.value = data.length;
      }
    } catch (_) {
      // Ignore error
    }
  }

  // Get all users (for directory)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await apiService.dio.get('/admin/users');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get pending users (for verification)
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final response = await apiService.dio.get('/admin/users/pending');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Verify User
  Future<bool> verifyUser(String userId) async {
    try {
      final response = await apiService.dio.post('/admin/users/$userId/verify');
      return response.data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Suspend User
  Future<bool> suspendUser(String userId, bool isActive) async {
    try {
      final response = await apiService.dio.put(
        '/admin/users/$userId/suspend',
        data: {'isActive': isActive},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Get User Detail (with reports)
  Future<Map<String, dynamic>?> getUserDetail(String userId) async {
    try {
      final response = await apiService.dio.get('/admin/users/$userId');
      if (response.data['status'] == 'success') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Force Close Report
  Future<bool> forceCloseReport(String reportId, String reason) async {
    try {
      final response = await apiService.dio.put(
        '/admin/reports/$reportId/force-close',
        data: {'reason': reason},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Get Staff List
  Future<List<Map<String, dynamic>>> getStaff() async {
    try {
      final response = await apiService.dio.get('/admin/staff');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Add Staff
  Future<bool> addStaff(Map<String, dynamic> data) async {
    try {
      final response = await apiService.dio.post('/admin/staff', data: data);
      return response.data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Update Staff
  Future<bool> updateStaff(String staffId, Map<String, dynamic> data) async {
    try {
      final response = await apiService.dio.put(
        '/admin/staff/$staffId',
        data: data,
      );
      return response.data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Delete/Deactivate Staff
  Future<bool> deleteStaff(String staffId) async {
    try {
      final response = await apiService.dio.delete('/admin/staff/$staffId');
      return response.data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Get All Reports (for Admin Reports Page)
  Future<List<Map<String, dynamic>>> getAllReports({
    String? query,
    String? status,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (query != null && query.isNotEmpty) params['search'] = query;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (limit != null) params['limit'] = limit;

      final response = await apiService.dio.get(
        '/reports',
        queryParameters: params,
      );
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Statistics Data
  Future<Map<String, dynamic>> getStatistics() async {
    // Simulator delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock Data - In real app, this would come from API
    return {
      'userGrowth': [
        {'date': '1 Jan', 'value': 10},
        {'date': '7 Jan', 'value': 15},
        {'date': '14 Jan', 'value': 25},
        {'date': '21 Jan', 'value': 40},
        {'date': '28 Jan', 'value': 55},
        {'date': '30 Jan', 'value': 58},
      ],
      'activeUsers': 142,
      'totalLogin': 1204,
      'appUsage': [
        {'day': 'S', 'value': 20},
        {'day': 'S', 'value': 35},
        {'day': 'R', 'value': 18},
        {'day': 'K', 'value': 45},
        {'day': 'J', 'value': 28},
        {'day': 'S', 'value': 40},
        {'day': 'M', 'value': 50},
      ],
      'userDistribution': {
        'Pelapor': 65,
        'Teknisi': 20,
        'Supervisor': 10,
        'Admin': 5,
      },
      'reportVolume': [
        {'dept': 'HRD', 'in': 15, 'out': 12},
        {'dept': 'IT', 'in': 25, 'out': 22},
        {'dept': 'GA', 'in': 30, 'out': 28},
        {'dept': 'FIN', 'in': 40, 'out': 38},
        {'dept': 'MKT', 'in': 35, 'out': 32},
      ],
    };
  }
}

final adminService = AdminService();
