import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service for report tracking (Location sharing)
/// Now uses HTTP POST for sending and SSE for receiving (handled in ReportDetailBase)
class WebSocketService {
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Connect to the tracking service (Simulated for compatibility)
  void connect(String reportId) {
    if (_isConnected) return;
    debugPrint('[TRACKING-SERVICE] Initialized for report $reportId');
    _isConnected = true;
  }

  /// Send location update via HTTP POST
  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required String role,
    required String senderName,
    required String reportId,
  }) async {
    final token = ApiService.token;
    final url = Uri.parse('${ApiService.baseUrl}/tracking/$reportId');

    final message = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'role': role,
      'senderName': senderName,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: message,
      );

      if (response.statusCode != 200) {
        debugPrint('[TRACKING-SERVICE] Error sending: ${response.body}');
      }
    } catch (e) {
      debugPrint('[TRACKING-SERVICE] Exception: $e');
    }
  }

  /// Close tracking
  void disconnect() {
    _isConnected = false;
    debugPrint('[TRACKING-SERVICE] Stopped');
  }
}

// Singleton helper
final webSocketService = WebSocketService();
