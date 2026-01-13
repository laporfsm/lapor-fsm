import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class ReportService {
  // Get all public reports
  Future<List<Map<String, dynamic>>> getPublicReports({
    String? category,
    String? building,
    String? status,
  }) async {
    try {
      final response = await apiService.dio.get('/reports', queryParameters: {
        if (category != null) 'category': category,
        if (building != null) 'building': building,
        if (status != null) 'status': status,
      });

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  // Get user's own reports
  Future<List<Map<String, dynamic>>> getMyReports(int userId) async {
    try {
      final response = await apiService.dio.get('/reports/my/$userId');

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print('Error fetching my reports: $e');
      return [];
    }
  }

  // Get single report detail
  Future<Map<String, dynamic>?> getReportDetail(int reportId) async {
    try {
      final response = await apiService.dio.get('/reports/$reportId');

      if (response.data['status'] == 'success') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching report detail: $e');
      return null;
    }
  }

  // Create new report
  Future<Map<String, dynamic>?> createReport({
    int? userId,
    int? categoryId,
    required String title,
    required String description,
    required String building,
    double? latitude,
    double? longitude,
    String? imageUrl,
    bool isEmergency = false,
    String? notes,
  }) async {
    try {
      final response = await apiService.dio.post('/reports', data: {
        'userId': userId,
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'building': building,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'isEmergency': isEmergency,
        'notes': notes,
      });

      if (response.data['status'] == 'created') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error creating report: $e');
      return null;
    }
  }

  // Upload image
  Future<String?> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });

      final response = await apiService.dio.post('/upload', data: formData);

      if (response.data['status'] == 'success') {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await apiService.dio.get('/reports/categories');

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}

// Singleton instance
final reportService = ReportService();
