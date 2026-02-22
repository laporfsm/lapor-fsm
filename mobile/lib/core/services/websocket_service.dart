import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  String get _wsBaseUrl {
    final httpUrl = ApiService.baseUrl;
    return httpUrl.replaceFirst('http', 'ws');
  }

  /// Connect to the tracking websocket for a specific report
  void connect(String reportId) {
    if (_isConnected) return;

    final token = ApiService.token;
    final url =
        '$_wsBaseUrl/ws/tracking/$reportId${token != null ? "?token=$token" : ""}';
    debugPrint('[WS-SERVICE] Connecting to $url');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
    } catch (e) {
      debugPrint('[WS-SERVICE] Connection error: $e');
      _isConnected = false;
    }
  }

  Stream<dynamic>? _broadcastStream;

  /// Stream of incoming tracking messages (broadcast)
  Stream<dynamic>? get stream {
    if (_broadcastStream == null && _channel != null) {
      _broadcastStream = _channel!.stream.asBroadcastStream();
    }
    return _broadcastStream;
  }

  /// Send location update
  void sendLocation({
    required double latitude,
    required double longitude,
    required String role,
    required String senderName,
  }) {
    if (!_isConnected || _channel == null) {
      debugPrint('[WS-SERVICE] Cannot send: Not connected');
      return;
    }

    final message = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'role': role,
      'senderName': senderName,
    });

    try {
      _channel!.sink.add(message);
    } catch (e) {
      debugPrint('[WS-SERVICE] Error sending message: $e');
    }
  }

  /// Close connection
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _broadcastStream = null;
    _isConnected = false;
    debugPrint('[WS-SERVICE] Disconnected');
  }
}

// Singleton helper
final webSocketService = WebSocketService();
