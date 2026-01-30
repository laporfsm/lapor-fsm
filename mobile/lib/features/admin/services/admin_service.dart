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
    try {
      final response = await apiService.dio.get('/admin/statistics');
      if (response.data['status'] == 'success') {
        return response.data['data'];
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Get System Logs
  Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final response = await apiService.dio.get('/admin/logs');
      if (response.data['status'] == 'success') {
        final List data = response.data['data'];
        return data.map((l) {
          // Convert ISO string to DateTime
          if (l['time'] is String) {
            l['time'] = DateTime.parse(l['time']);
          }
          return Map<String, dynamic>.from(l);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final adminService = AdminService();
