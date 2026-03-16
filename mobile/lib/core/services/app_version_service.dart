import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/models/app_version_info.dart';
import 'package:mobile/core/services/api_service.dart';

class AppVersionService {
  Future<AppVersionInfo?> fetchVersionInfo() async {
    try {
      final response = await apiService.dio.get(
        '/app/version',
        options: Options(
          headers: const {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );

      if (response.data is Map &&
          response.data['status'] == 'success' &&
          response.data['data'] is Map<String, dynamic>) {
        return AppVersionInfo.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('[APP VERSION] Fetch failed: $e');
    }
    return null;
  }
}
