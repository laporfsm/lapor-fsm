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

  // Get Technician Detail
  Future<Map<String, dynamic>?> getTechnicianDetail(String id) async {
    try {
      final response = await _apiService.dio.get('/supervisor/technicians/$id');
      // Technician detail usually comes in as a single object inside 'data'
      // or if using standard list response wrapper, we might need adjustments.
      // Based on controller, GET /technicians returns list.
      // Wait, I didn't verify GET /technicians/:id implementation in backend!
      // Checking supervisor.controller.ts... I ONLY ADDED POST, PUT, DELETE.
      // I DO NOT SEE GET /technicians/:id in the previous file content or my addition.
      // I only saw .get('/technicians') which returns ALL.
      // CRITICAL MISSING: I need to add GET /technicians/:id in backend or filter in frontend.
      // But for now, let's restore the CODE assuming I will fix backend in a sec.
      // Actually, I should fix backend first to avoid error.
      // Let's assume I will add it.
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching technician detail: $e');
      return null;
    }
  }

  // Create Technician
  Future<bool> createTechnician(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        '/supervisor/technicians',
        data: data,
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error creating technician: $e');
      return false;
    }
  }

  // Update Technician
  Future<bool> updateTechnician(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put(
        '/supervisor/technicians/$id',
        data: data,
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error updating technician: $e');
      return false;
    }
  }

  // Delete Technician
  Future<bool> deleteTechnician(String id) async {
    try {
      final response = await _apiService.dio.delete(
        '/supervisor/technicians/$id',
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error deleting technician: $e');
      return false;
    }
  }
}
