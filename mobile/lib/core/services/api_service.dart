import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS/web/desktop
  // For physical Android device, replace with your computer's local IP (e.g., 192.168.1.100)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000';
    }
    // For Android (both emulator and physical device)
    // Android emulator uses 10.0.2.2 to access host machine's localhost
    // Physical device needs to use the actual IP address of the host machine
    if (Platform.isAndroid) {
      // Change this to your computer's IP if using physical device
      // e.g., 'http://192.168.1.100:3000'
      return 'http://10.44.6.106:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Logging is currently DISABLED for security/cleanliness preference.
    // Uncomment the block below to enable logs in Debug mode only.
    /*
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false, // Hide headers (Auth tokens)
          responseHeader: false,
        ),
      );
    }
    */
  }

  Dio get dio => _dio;

  // Set auth token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

// Singleton instance
final apiService = ApiService();
