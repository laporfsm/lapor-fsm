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
      final response = await _apiService.dio.get('/supervisor/pj-location');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching PJ Lokasi: $e');
      return [];
    }
  }

  // Get Technician Detail
  Future<Map<String, dynamic>?> getTechnicianDetail(String id) async {
    try {
      final response = await _apiService.dio.get('/supervisor/technicians/$id');
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

  // ===========================================================================
  // PJ GEDUNG CRUD
  // ===========================================================================

  // Get PJ Gedung Detail
  Future<Map<String, dynamic>?> getPJGedungDetail(String id) async {
    try {
      final response = await _apiService.dio.get('/supervisor/pj-location/$id');
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching PJ Lokasi detail: $e');
      return null;
    }
  }

  // Create PJ Gedung
  Future<bool> createPJGedung(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        '/supervisor/pj-location',
        data: data,
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error creating PJ Lokasi: $e');
      return false;
    }
  }

  // Update PJ Gedung
  Future<bool> updatePJGedung(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put(
        '/supervisor/pj-location/$id',
        data: data,
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error updating PJ Lokasi: $e');
      return false;
    }
  }

  // Delete PJ Gedung
  Future<bool> deletePJGedung(String id) async {
    try {
      final response = await _apiService.dio.delete(
        '/supervisor/pj-location/$id',
      );
      return response.data['status'] == 'success';
    } catch (e) {
      debugPrint('Error deleting PJ Lokasi: $e');
      return false;
    }
  }
}
