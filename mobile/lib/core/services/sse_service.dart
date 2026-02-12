import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/report_common/domain/entities/report_log.dart';
import 'package:mobile/core/services/api_service.dart';

/// Service for Server-Sent Events (SSE) to receive real-time report logs
class SSEService {
  static final SSEService _instance = SSEService._internal();
  factory SSEService() => _instance;
  SSEService._internal();

  String get _baseUrl => ApiService.baseUrl;

  StreamSubscription? _sseSubscription;
  final _logsController = StreamController<List<ReportLog>>.broadcast();

  Stream<List<ReportLog>> get logsStream => _logsController.stream;

  bool get isConnected => _sseSubscription != null;

  /// Connect to SSE endpoint for a specific report
  void connect(String reportId) {
    if (_sseSubscription != null) {
      disconnect();
    }

    try {
      final url = '$_baseUrl/reports/$reportId/logs/stream';
      debugPrint('[SSE] Connecting to $url');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      client
          .send(request)
          .then((response) {
            if (response.statusCode == 200) {
              debugPrint('[SSE] Connection established');

              _sseSubscription = response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())
                  .listen(
                    (line) => _handleSSELine(line),
                    onError: (error) {
                      debugPrint('[SSE] Stream error: $error');
                      _reconnect(reportId);
                    },
                    onDone: () {
                      debugPrint('[SSE] Stream closed');
                      _reconnect(reportId);
                    },
                  );
            } else {
              debugPrint('[SSE] Connection failed: ${response.statusCode}');
            }
          })
          .catchError((error) {
            debugPrint('[SSE] Connection error: $error');
          });
    } catch (e) {
      debugPrint('[SSE] Error: $e');
    }
  }

  void _handleSSELine(String line) {
    if (line.startsWith('data: ')) {
      try {
        final jsonData = jsonDecode(line.substring(6));

        if (jsonData['type'] == 'logs' && jsonData['logs'] != null) {
          final logsList = (jsonData['logs'] as List)
              .map((log) => ReportLog.fromJson(log as Map<String, dynamic>))
              .toList();

          _logsController.add(logsList);
        }
      } catch (e) {
        debugPrint('[SSE] Error parsing data: $e');
      }
    }
  }

  void _reconnect(String reportId) {
    disconnect();
    // Reconnect after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      connect(reportId);
    });
  }

  /// Disconnect from SSE
  void disconnect() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    debugPrint('[SSE] Disconnected');
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _logsController.close();
  }
}

// Global instance
final sseService = SSEService();
