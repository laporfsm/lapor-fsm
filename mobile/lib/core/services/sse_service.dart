import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/report_common/domain/entities/report_log.dart';
import 'package:mobile/core/services/api_service.dart';

/// Service for Server-Sent Events (SSE) to receive real-time updates
/// Supports multiple streams: Report Logs and Global Notifications
class SSEService {
  static final SSEService _instance = SSEService._internal();
  factory SSEService() => _instance;
  SSEService._internal();

  String get _baseUrl => ApiService.baseUrl;

  // Report Logs Stream
  StreamSubscription? _reportSubscription;
  http.Client? _reportClient;
  bool _isReportManualDisconnect = false;
  final _reportController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _reportController.stream;

  final _logsController = StreamController<List<ReportLog>>.broadcast();
  Stream<List<ReportLog>> get logsStream => _logsController.stream;

  // Notification Stream
  StreamSubscription? _notificationSubscription;
  http.Client? _notificationClient;
  bool _isNotificationManualDisconnect = false;
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  // Connection State
  final _connectionState = StreamController<String>.broadcast();
  Stream<String> get connectionState => _connectionState.stream;

  /// Connect to Report Logs SSE
  void connectToReport(String reportId) {
    _isReportManualDisconnect = false;
    _startSSEConnection(
      url: '$_baseUrl/reports/$reportId/logs/stream',
      clientField: 'report',
      onData: (data) {
        // Push to global event stream
        _reportController.add(data);

        if (data['type'] == 'logs' && data['logs'] != null) {
          try {
            final logsList = (data['logs'] as List)
                .map((log) => ReportLog.fromJson(log as Map<String, dynamic>))
                .toList();
            _logsController.add(logsList);
          } catch (e) {
            debugPrint('[SSE-LOGS] Parse error: $e');
          }
        }
      },
      onReconnect: () => connectToReport(reportId),
    );
  }

  /// Connect to Notifications SSE
  /// [type] is 'user' or 'staff'
  void connectToNotifications(String type, String id) {
    _isNotificationManualDisconnect = false;
    _startSSEConnection(
      url: '$_baseUrl/notifications/stream/$type/$id',
      clientField: 'notification',
      onData: (data) {
        if (data['type'] == 'notification' && data['data'] != null) {
          _notificationController.add(data['data']);
        }
      },
      onReconnect: () => connectToNotifications(type, id),
    );
  }

  /// Legacy method for backward compatibility
  void connect(String reportId) => connectToReport(reportId);

  // Generic internal connection handler
  void _startSSEConnection({
    required String url,
    required String clientField,
    required Function(Map<String, dynamic>) onData,
    required Function() onReconnect,
  }) {
    _disconnectClient(clientField);

    try {
      debugPrint('[SSE-$clientField] Connecting to $url');
      final client = http.Client();
      if (clientField == 'report') {
        _reportClient = client;
      } else {
        _notificationClient = client;
      }

      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      final token = ApiService.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      client
          .send(request)
          .then((response) {
            if (response.statusCode == 200) {
              debugPrint('[SSE-$clientField] Connected');
              final stream = response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter());

              StreamSubscription? sub;
              sub = stream.listen(
                (line) {
                  if (line.startsWith('data: ')) {
                    try {
                      final jsonStr = line.substring(6).trim();
                      if (jsonStr.isNotEmpty) {
                        final data = jsonDecode(jsonStr);
                        if (data['type'] == 'ping') {
                          // Heartbeat, ignore
                        } else if (data['type'] == 'connected') {
                          debugPrint('[SSE-$clientField] Handshake success');
                        } else {
                          onData(data);
                        }
                      }
                    } catch (e) {
                      debugPrint('[SSE-$clientField] JSON Error: $e');
                    }
                  }
                },
                onError: (e) {
                  debugPrint('[SSE-$clientField] Error: $e');
                  _handleReconnect(clientField, onReconnect);
                },
                onDone: () {
                  debugPrint('[SSE-$clientField] Closed by server');
                  _handleReconnect(clientField, onReconnect);
                },
                cancelOnError: true,
              );

              if (clientField == 'report') {
                _reportSubscription = sub;
              } else {
                _notificationSubscription = sub;
              }
            } else {
              debugPrint('[SSE-$clientField] Status ${response.statusCode}');
              _handleReconnect(clientField, onReconnect);
            }
          })
          .catchError((e) {
            debugPrint('[SSE-$clientField] Connection error: $e');
            _handleReconnect(clientField, onReconnect);
          });
    } catch (e) {
      debugPrint('[SSE-$clientField] Exception: $e');
      _handleReconnect(clientField, onReconnect);
    }
  }

  void _handleReconnect(String clientField, Function() onReconnect) {
    bool isManual = clientField == 'report'
        ? _isReportManualDisconnect
        : _isNotificationManualDisconnect;

    if (isManual) return;

    debugPrint('[SSE-$clientField] Reconnecting in 5s...');
    Future.delayed(const Duration(seconds: 5), () {
      bool stillManual = clientField == 'report'
          ? _isReportManualDisconnect
          : _isNotificationManualDisconnect;

      if (!stillManual) {
        onReconnect();
      }
    });
  }

  void _disconnectClient(String clientField) {
    if (clientField == 'report') {
      _reportSubscription?.cancel();
      _reportClient?.close();
      _reportSubscription = null;
      _reportClient = null;
    } else {
      _notificationSubscription?.cancel();
      _notificationClient?.close();
      _notificationSubscription = null;
      _notificationClient = null;
    }
  }

  void disconnectReport() {
    _isReportManualDisconnect = true;
    _disconnectClient('report');
    debugPrint('[SSE-REPORT] Disconnected manually');
  }

  void disconnectNotification() {
    _isNotificationManualDisconnect = true;
    _disconnectClient('notification');
    debugPrint('[SSE-NOTIF] Disconnected manually');
  }

  void disconnect() => disconnectReport(); // Legacy support

  void dispose() {
    disconnectReport();
    disconnectNotification();
    _logsController.close();
    _notificationController.close();
    _connectionState.close();
  }
}

final sseService = SSEService();
