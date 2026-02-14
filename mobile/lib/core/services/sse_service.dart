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
  http.Client? _activeClient;
  bool _isManualDisconnect = false;
  final _logsController = StreamController<List<ReportLog>>.broadcast();

  Stream<List<ReportLog>> get logsStream => _logsController.stream;

  bool get isConnected => _sseSubscription != null;

  /// Connect to SSE endpoint for a specific report
  void connect(String reportId) {
    // Reset manual disconnect flag on new connection
    _isManualDisconnect = false;

    if (_sseSubscription != null) {
      disconnect();
    }

    try {
      final url = '$_baseUrl/reports/$reportId/logs/stream';
      debugPrint('[SSE] Connecting to $url');

      _activeClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      _activeClient!
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
                      debugPrint('[SSE] Stream closed by server');
                      _reconnect(reportId);
                    },
                    cancelOnError: true,
                  );
            } else {
              debugPrint(
                '[SSE] Connection failed with status: ${response.statusCode}',
              );
              _reconnect(reportId);
            }
          })
          .catchError((error) {
            debugPrint('[SSE] Connection request error: $error');
            _reconnect(reportId);
          });
    } catch (e) {
      debugPrint('[SSE] Exception in connect: $e');
      _reconnect(reportId);
    }
  }

  void _handleSSELine(String line) {
    if (line.isEmpty) return;

    if (line.startsWith('data: ')) {
      try {
        final dataStr = line.substring(6).trim();
        if (dataStr.isEmpty) return;

        final jsonData = jsonDecode(dataStr);

        if (jsonData['type'] == 'logs' && jsonData['logs'] != null) {
          final logsList = (jsonData['logs'] as List)
              .map((log) => ReportLog.fromJson(log as Map<String, dynamic>))
              .toList();

          _logsController.add(logsList);
        } else if (jsonData['type'] == 'connected') {
          debugPrint(
            '[SSE] Confirmed connected for report: ${jsonData['reportId']}',
          );
        }
      } catch (e) {
        debugPrint('[SSE] Error parsing SSE line: $e. Line: $line');
      }
    }
  }

  void _reconnect(String reportId) {
    if (_isManualDisconnect) {
      debugPrint('[SSE] Skipping reconnect: manual disconnect');
      return;
    }

    debugPrint('[SSE] Scheduling reconnect in 5 seconds...');
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isManualDisconnect) {
        connect(reportId);
      } else {
        debugPrint(
          '[SSE] Reconnect aborted: manual disconnect occurred during wait',
        );
      }
    });
  }

  /// Disconnect from SSE
  void disconnect() {
    _isManualDisconnect = true;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _activeClient?.close();
    _activeClient = null;
    debugPrint('[SSE] Disconnected manually');
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _logsController.close();
  }
}

// Global instance
final sseService = SSEService();
