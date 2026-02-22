import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';
import '../../features/report_common/domain/entities/report.dart';

class ReportService {
  // Get all public reports
  Future<Map<String, dynamic>> getPublicReports({
    String? category,
    String? location,
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
          if (location != null) 'location': location,
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
        return {
          'data': List<Map<String, dynamic>>.from(response.data['data']),
          'total': response.data['total'] ?? 0,
        };
      }
      return {'data': [], 'total': 0};
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return {'data': [], 'total': 0};
    }
  }

  // Get user's own reports
  Future<Map<String, dynamic>> getMyReports(
    String userId, {
    String? role,
  }) async {
    try {
      final response = await apiService.dio.get(
        '/reports/my/$userId',
        queryParameters: {if (role != null) 'role': role},
      );

      if (response.data['status'] == 'success') {
        return {
          'data': List<Map<String, dynamic>>.from(response.data['data']),
          'total': response.data['total'] ?? 0,
        };
      }
      return {'data': [], 'total': 0};
    } catch (e) {
      debugPrint('Error fetching my reports: $e');
      return {'data': [], 'total': 0};
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
    required String location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? mediaUrls,
    bool isEmergency = false,
    String? notes,
    String? locationDetail,
    String? status,
  }) async {
    try {
      final requestBody = {
        'userId': userId != null ? int.tryParse(userId) : null,
        'staffId': staffId != null ? int.tryParse(staffId) : null,
        'categoryId': categoryId != null ? int.tryParse(categoryId) : null,
        'title': title,
        'description': description,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'mediaUrls': mediaUrls,
        'isEmergency': isEmergency,
        'notes': notes,
        'locationDetail': locationDetail,
        'status': status,
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

  // Upload media (image or video)
  Future<String?> uploadMedia(XFile xfile) async {
    try {
      final fileName = xfile.name;
      final fileExtension = fileName.split('.').last.toLowerCase();

      String mimeType = 'image/jpeg';
      if (fileExtension == 'png')
        mimeType = 'image/png';
      else if (fileExtension == 'webp')
        mimeType = 'image/webp';
      else if (fileExtension == 'gif')
        mimeType = 'image/gif';
      else if (fileExtension == 'mp4')
        mimeType = 'video/mp4';
      else if (fileExtension == 'mov' || fileExtension == 'quicktime')
        mimeType = 'video/quicktime';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await xfile.readAsBytes(),
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      debugPrint(
        'Uploading file: $fileName ($mimeType) to ${apiService.dio.options.baseUrl}/upload',
      );

      final response = await apiService.dio.post(
        '/upload',
        data: formData,
        options: Options(
          // Important: ensure Content-Type is NOT application/json for this request
          contentType: 'multipart/form-data',
          // Increase timeout for uploads
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      debugPrint('Upload Response: ${response.data}');

      if (response.data['status'] == 'success') {
        return response.data['data']['url'];
      } else {
        debugPrint('Upload failed with message: ${response.data['message']}');
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      if (e is DioException) {
        debugPrint('Dio Error Details: ${e.response?.data}');
      }
      return null;
    }
  }

  // Deprecated: Use uploadMedia instead
  Future<String?> uploadImage(XFile xfile) async {
    return uploadMedia(xfile);
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

  // ===========================================================================
  // BUILDING MANAGEMENT
  // ===========================================================================

  // Get Locations
  Future<List<Map<String, dynamic>>> getLocations({String? search}) async {
    try {
      final response = await apiService.dio.get(
        '/locations',
        queryParameters: {if (search != null) 'search': search},
      );
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }

  // Create Location
  Future<bool> createLocation(String name) async {
    try {
      final response = await apiService.dio.post(
        '/locations',
        data: {'name': name},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error creating location: $e');
      return false;
    }
  }

  // Update Location
  Future<bool> updateLocation(int id, String name) async {
    try {
      final response = await apiService.dio.put(
        '/locations/$id',
        data: {'name': name},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error updating location: $e');
      return false;
    }
  }

  // Delete Location
  Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final response = await apiService.dio.delete('/locations/$id');
      if (response.data['status'] == 'success') {
        return {'success': true};
      } else {
        return {'success': false, 'message': response.data['message']};
      }
    } catch (e) {
      debugPrint('Error deleting location: $e');
      String msg = 'Gagal menghapus lokasi.';
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

  // Get PJ Gedung Statistics
  Future<Map<String, dynamic>?> getPJStatistics({String? locationName}) async {
    try {
      final response = await apiService.dio.get(
        '/pj-gedung/statistics',
        queryParameters: {if (locationName != null) 'location': locationName},
      );
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching PJ statistics: $e');
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

  // Get Supervisor Detailed Statistics
  Future<Map<String, dynamic>?> getSupervisorStatistics() async {
    try {
      final response = await apiService.dio.get('/supervisor/statistics');
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching supervisor statistics: $e');
      return null;
    }
  }

  // Get Supervisor Locations with report counts
  Future<List<Map<String, dynamic>>?> getSupervisorLocations() async {
    try {
      final response = await apiService.dio.get('/supervisor/locations');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching supervisor locations: $e');
      return null;
    }
  }

  // Get Non-Gedung Pending Reports (locations without PJ Gedung)
  Future<Map<String, dynamic>> getNonGedungReports({int limit = 20}) async {
    try {
      final response = await apiService.dio.get(
        '/supervisor/reports/non-gedung',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.data['status'] == 'success') {
        return {
          'data': List<Map<String, dynamic>>.from(response.data['data']),
          'total': response.data['total'] ?? 0,
        };
      }
      return {'data': [], 'total': 0};
    } catch (e) {
      debugPrint('Error fetching non-gedung reports: $e');
      return {'data': [], 'total': 0};
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
  Future<Map<String, dynamic>> getStaffReports({
    required String role, // 'pj', 'supervisor', 'technician'
    String? status,
    bool? isEmergency,
    String? period,
    String? search,
    String? category,
    String? location,
    int? assignedTo,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final prefix = role == 'pj' ? 'pj-gedung' : role;
      final response = await apiService.dio.get(
        '/$prefix/reports',
        queryParameters: {
          if (status != null) 'status': status,
          if (isEmergency != null) 'isEmergency': isEmergency.toString(),
          if (period != null) 'period': period,
          if (search != null) 'search': search,
          if (category != null) 'category': category,
          if (location != null) 'location': location,
          if (assignedTo != null) 'assignedTo': assignedTo.toString(),
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (page != null) 'page': page.toString(),
          if (limit != null) 'limit': limit.toString(),
        },
      );

      if (response.data['status'] == 'success') {
        return {
          'data': List<Map<String, dynamic>>.from(response.data['data']),
          'total': response.data['total'] ?? 0,
        };
      }
      return {'data': [], 'total': 0};
    } catch (e) {
      debugPrint('Error fetching staff reports ($role): $e');
      return {'data': [], 'total': 0};
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

  // ===========================================================================
  // LIFECYCLE MANAGEMENT (PJ & Supervisor)
  // ===========================================================================

  /// Verify a report (PJ Gedung or Supervisor)
  Future<Report> verifyReport(
    String reportId,
    int staffId, {
    String? notes,
    String role = 'pj_gedung', // 'pj_gedung' or 'supervisor'
  }) async {
    try {
      final prefix = role == 'supervisor' ? 'supervisor' : 'pj-gedung';
      final response = await apiService.dio.post(
        '/$prefix/reports/$reportId/verify',
        data: {'staffId': staffId, if (notes != null) 'notes': notes},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal memverifikasi laporan: $e');
    }
  }

  /// Assign report to technician (Supervisor)
  Future<Report> assignTechnician(
    String reportId,
    int supervisorId,
    int technicianId,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/assign',
        data: {'supervisorId': supervisorId, 'technicianId': technicianId},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menugaskan teknisi: $e');
    }
  }

  /// Reject a report (Supervisor)
  Future<Report> rejectReport(
    String reportId,
    int staffId,
    String reason,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/reject',
        data: {'staffId': staffId, 'reason': reason},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menolak laporan: $e');
    }
  }

  /// Reject a report (PJ Gedung)
  Future<Report> rejectReportPJGedung(
    String reportId,
    int staffId,
    String reason,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/pj-gedung/reports/$reportId/reject',
        data: {'staffId': staffId, 'reason': reason},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menolak laporan: $e');
    }
  }

  /// Group multiple reports (Supervisor)
  Future<Report> groupReports(
    List<String> reportIds,
    int staffId, {
    String? notes,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/group',
        data: {
          'reportIds': reportIds.map((id) => int.parse(id)).toList(),
          'staffId': staffId,
          if (notes != null) 'notes': notes,
        },
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menggabungkan laporan: $e');
    }
  }

  /// Recall a report (Supervisor)
  Future<Report> recallReport(
    String reportId,
    int staffId,
    String reason,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/recall',
        data: {'staffId': staffId, 'reason': reason},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal recall laporan: $e');
    }
  }

  /// Approve result (Supervisor)
  Future<Report> approveResult(
    String reportId,
    int staffId, {
    String? notes,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/approve',
        data: {'staffId': staffId, if (notes != null) 'notes': notes},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menyetujui hasil: $e');
    }
  }

  // ===========================================================================
  // TECHNICIAN ACTIONS
  // ===========================================================================

  /// Accept task (Teknisi)
  Future<Report> acceptTask(String reportId, int staffId) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/accept',
        data: {'staffId': staffId},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menerima tugas: $e');
    }
  }

  /// Pause task (Teknisi)
  Future<Report> pauseTask(
    String reportId,
    int staffId,
    String reason, {
    String? photoUrl,
  }) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/pause',
        data: {
          'staffId': staffId,
          'reason': reason,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menunda tugas: $e');
    }
  }

  /// Resume task (Teknisi)
  Future<Report> resumeTask(String reportId, int staffId) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/resume',
        data: {'staffId': staffId},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal melanjutkan tugas: $e');
    }
  }

  /// Complete task (Teknisi)
  Future<Report> completeTask(
    String reportId,
    int staffId,
    String notes,
    List<String> mediaUrls,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/technician/reports/$reportId/complete',
        data: {'staffId': staffId, 'notes': notes, 'mediaUrls': mediaUrls},
      );
      if (response.data['status'] == 'success') {
        return Report.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Gagal menyelesaikan tugas: $e');
    }
  }

  // ===========================================================================
  // REJECTED REPORTS MANAGEMENT

  /// Archive rejected report (Supervisor)
  Future<bool> archiveRejectedReport(String reportId, int staffId) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/archive',
        data: {'staffId': staffId},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error archiving report: $e');
      return false;
    }
  }

  /// Return rejected report to queue (Supervisor)
  Future<bool> returnReportToQueue(String reportId, int staffId) async {
    try {
      final response = await apiService.dio.post(
        '/supervisor/reports/$reportId/return-to-queue',
        data: {'staffId': staffId},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error returning report to queue: $e');
      return false;
    }
  }

  // Export reports (Returns bytes)
  Future<List<int>?> exportReports({String? status, String? location}) async {
    try {
      final response = await apiService.dio.get(
        '/supervisor/reports/export',
        queryParameters: {
          if (status != null) 'status': status,
          if (location != null) 'location': location,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      debugPrint('Error exporting reports: $e');
      return null;
    }
  }

  // ===========================================================================
  // SPECIALIZATION MANAGEMENT
  // ===========================================================================

  // Get Specializations
  Future<List<Map<String, dynamic>>> getSpecializations({
    String? search,
  }) async {
    try {
      final response = await apiService.dio.get(
        '/specializations',
        queryParameters: {if (search != null) 'search': search},
      );
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching specializations: $e');
      return [];
    }
  }

  // Create Specialization
  Future<bool> createSpecialization(
    String name,
    String icon,
    String? description,
  ) async {
    try {
      final response = await apiService.dio.post(
        '/specializations',
        data: {'name': name, 'icon': icon, 'description': description},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error creating specialization: $e');
      return false;
    }
  }

  // Update Specialization
  Future<bool> updateSpecialization(
    int id,
    String name,
    String icon,
    String? description,
  ) async {
    try {
      final response = await apiService.dio.put(
        '/specializations/$id',
        data: {'name': name, 'icon': icon, 'description': description},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error updating specialization: $e');
      return false;
    }
  }

  // Delete Specialization
  Future<Map<String, dynamic>> deleteSpecialization(int id) async {
    try {
      final response = await apiService.dio.delete('/specializations/$id');
      if (response.data['status'] == 'success') {
        return {'success': true};
      } else {
        return {'success': false, 'message': response.data['message']};
      }
    } catch (e) {
      debugPrint('Error deleting specialization: $e');
      String msg = 'Gagal menghapus spesialisasi.';
      if (e is DioException && e.response?.data != null) {
        msg = e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    }
  }
}

// Singleton instance
final reportService = ReportService();
