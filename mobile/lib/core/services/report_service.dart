import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class ReportService {
  // Get all public reports
  Future<List<Map<String, dynamic>>> getPublicReports({
    String? category,
    String? building,
    String? status,
    String? search,
    bool? isEmergency,
    String? period,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await apiService.dio.get(
        '/reports',
        queryParameters: {
          if (category != null) 'category': category,
          if (building != null) 'building': building,
          if (status != null) 'status': status,
          if (search != null) 'search': search,
          if (isEmergency != null) 'isEmergency': isEmergency.toString(),
          if (period != null) 'period': period,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  // Get user's own reports
  Future<List<Map<String, dynamic>>> getMyReports(
    String userId, {
    String? role,
  }) async {
    try {
      final response = await apiService.dio.get(
        '/reports/my/$userId',
        queryParameters: {if (role != null) 'role': role},
      );

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my reports: $e');
      return [];
    }
  }

  // Get single report detail
  Future<Map<String, dynamic>?> getReportDetail(String reportId) async {
    try {
      final response = await apiService.dio.get('/reports/$reportId');

      if (response.data['status'] == 'success') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching report detail: $e');
      return null;
    }
  }

  // Create new report
  Future<Map<String, dynamic>?> createReport({
    String? userId,
    String? staffId,
    String? categoryId,
    required String title,
    required String description,
    required String building,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? mediaUrls,
    bool isEmergency = false,
    String? notes,
    String? locationDetail,
  }) async {
    try {
      final requestBody = {
        'userId': userId != null ? int.tryParse(userId) : null,
        'staffId': staffId != null ? int.tryParse(staffId) : null,
        'categoryId': categoryId != null ? int.tryParse(categoryId) : null,
        'title': title,
        'description': description,
        'building': building,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'mediaUrls': mediaUrls,
        'isEmergency': isEmergency,
        'notes': notes,
        'locationDetail': locationDetail,
      };

      // Remove null values to avoid backend validation errors (422)
      requestBody.removeWhere((key, value) => value == null);

      final response = await apiService.dio.post('/reports', data: requestBody);

      if (response.data['status'] == 'created') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error creating report: $e');
      return null;
    }
  }

  // Upload image
  Future<String?> uploadImage(XFile xfile) async {
    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        final bytes = await xfile.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: xfile.name);
      } else {
        multipartFile = await MultipartFile.fromFile(
          xfile.path,
          filename: xfile.path.split('/').last,
        );
      }

      final formData = FormData.fromMap({'file': multipartFile});

      final response = await apiService.dio.post('/upload', data: formData);

      if (response.data['status'] == 'success') {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await apiService.dio.get('/reports/categories');

      if (response.data['status'] == 'success') {
        final allCats = List<Map<String, dynamic>>.from(response.data['data']);
        // Optional: Filter 'Darurat' if needed globally, but better to filter in UI
        return allCats;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  // Create Category
  Future<bool> createCategory(String name, String icon) async {
    try {
      final response = await apiService.dio.post(
        '/categories',
        data: {'name': name, 'icon': icon},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error creating category: $e');
      return false;
    }
  }

  // Update Category
  Future<bool> updateCategory(int id, String name, String icon) async {
    try {
      final response = await apiService.dio.put(
        '/categories/$id',
        data: {'name': name, 'icon': icon},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  // Delete Category
  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await apiService.dio.delete('/categories/$id');
      if (response.data['status'] == 'success') {
        return {'success': true};
      } else {
        return {'success': false, 'message': response.data['message']};
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      // Extract error message if available
      String msg = 'Gagal menghapus kategori.';
      if (e is DioException && e.response?.data != null) {
        msg = e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    }
  }

  // STAFF ENDPOINTS

  // Get PJ Gedung Dashboard Stats
  Future<Map<String, dynamic>?> getPJDashboardStats(String staffId) async {
    try {
      final response = await apiService.dio.get('/pj-gedung/dashboard');
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching PJ dashboard stats: $e');
      return null;
    }
  }

  // Get Supervisor Dashboard Stats
  Future<Map<String, dynamic>?> getSupervisorDashboardStats(
    String staffId,
  ) async {
    try {
      final response = await apiService.dio.get(
        '/supervisor/dashboard/$staffId',
      );
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching Supervisor dashboard stats: $e');
      return null;
    }
  }

  // Get Technician Dashboard Stats
  Future<Map<String, dynamic>?> getTechnicianDashboardStats(
    String staffId,
  ) async {
    try {
      final response = await apiService.dio.get(
        '/technician/dashboard/$staffId',
      );
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching Technician dashboard stats: $e');
      return null;
    }
  }

  // Get Reports for Staff (with filtering)
  Future<List<Map<String, dynamic>>> getStaffReports({
    required String role, // 'pj', 'supervisor', 'technician'
    String? status,
    bool? isEmergency,
    String? period,
  }) async {
    try {
      final prefix = role == 'pj' ? 'pj-gedung' : role;
      final response = await apiService.dio.get(
        '/$prefix/reports',
        queryParameters: {
          if (status != null) 'status': status,
          if (isEmergency != null) 'isEmergency': isEmergency.toString(),
          if (period != null) 'period': period,
        },
      );

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching staff reports ($role): $e');
      return [];
    }
  }

  // --- Report Actions ---

  Future<bool> verifyReport(
    String reportId,
    String staffId, {
    String? notes,
    String? role,
  }) async {
    try {
      final prefix = role == 'pj' ? 'pj-gedung' : 'supervisor';
      final response = await apiService.dio.post(
        '/$prefix/reports/$reportId/verify',
        data: {'staffId': int.parse(staffId), 'notes': notes},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error verifying report: $e');
      return false;
    }
  }

  Future<bool> assignTechnician(
    String reportId,
    String supervisorId,
    String technicianId,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/assign',
        data: {
          'supervisorId': int.parse(supervisorId),
          'technicianId': int.parse(technicianId),
        },
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error assigning technician: $e');
      return false;
    }
  }

  Future<bool> recallReport(
    String reportId,
    String staffId,
    String reason,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/recall',
        data: {'staffId': int.parse(staffId), 'reason': reason},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error recalling report: $e');
      return false;
    }
  }

  Future<bool> approveReport(
    String reportId,
    String staffId, {
    String? notes,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/approve',
        data: {'staffId': int.parse(staffId), 'notes': notes},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error approving report: $e');
      return false;
    }
  }

  Future<bool> rejectReport(
    String reportId,
    String staffId,
    String reason,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/reject',
        data: {'staffId': int.parse(staffId), 'reason': reason},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error rejecting report: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      final response = await apiService.dio.get('/supervisor/technicians');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching technicians: $e');
      return [];
    }
  }

  // --- Technician Actions ---

  Future<bool> acceptReport(String reportId, String staffId) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/accept',
        data: {'staffId': int.parse(staffId)},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error accepting report: $e');
      return false;
    }
  }

  Future<bool> pauseReport(
    String reportId,
    String staffId,
    String reason, {
    String? photoUrl,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/pause',
        data: {
          'staffId': int.parse(staffId),
          'reason': reason,
          'photoUrl': photoUrl,
        },
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error pausing report: $e');
      return false;
    }
  }

  Future<bool> resumeReport(String reportId, String staffId) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/resume',
        data: {'staffId': int.parse(staffId)},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error resuming report: $e');
      return false;
    }
  }

  Future<bool> completeReport(
    String reportId,
    String staffId, {
    String? notes,
    List<String>? mediaUrls,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/complete',
        data: {
          'staffId': int.parse(staffId),
          'notes': notes,
          'mediaUrls': mediaUrls ?? [],
        },
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error completing report: $e');
      return false;
    }
  }
}

// Singleton instance
final reportService = ReportService();
