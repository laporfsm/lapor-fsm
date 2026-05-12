import 'package:dio/dio.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS/web/desktop
  // For physical Android device, replace with your computer's local IP (e.g., 192.168.1.100)
  static String get baseUrl {
    // Production / Testing server Tim 7 (UP2TI)
    // Adjusted for Public Access via Reverse Proxy
    return 'https://apps-fsm.undip.ac.id/lapor-fsm-api/';
  }

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptor to strip leading slash from paths when using subpath baseUrl
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.startsWith('/')) {
            options.path = options.path.substring(1);
          }
          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Get auth token
  static String? get token {
    final auth = apiService.dio.options.headers['Authorization'] as String?;
    if (auth != null && auth.startsWith('Bearer ')) {
      return auth.substring(7);
    }
    return null;
  }

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
