import 'package:flutter/material.dart';
import 'package:mobile/core/services/api_service.dart';

class SupervisorStaffService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      final response = await _apiService.dio.get('/supervisor/technicians');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching technicians: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPJGedung() async {
    try {
      final response = await _apiService.dio.get('/supervisor/pj-gedung');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching PJ Gedung: $e');
      return [];
    }
  }

  // Helper to toggle active status (assuming an update endpoint exists or will be created)
  // For now, we might just need to display data.
  // If editing is needed, we'll add update methods.
}
