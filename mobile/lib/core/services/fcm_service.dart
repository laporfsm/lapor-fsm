import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/router/app_router.dart';

// Setup background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Pending notification data to process after router is ready
  static Map<String, dynamic>? _pendingNotificationData;

  static Future<void> init() async {
    try {
      // 1. Request Permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // 2. Setup Background Handler (Mobile only usually, but handled by package)
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 3. Setup Local Notifications Channel (Android)
      await _setupLocalNotifications();

      // 4. Setup Foreground Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification}',
          );
          _showLocalNotification(message);
        }
      });

      // 4b. Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification tapped (background): ${message.data}');
        _handleMessageTap(message.data);
      });

      // 4c. Handle notification tap when app was terminated
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'App opened from terminated via notification: ${initialMessage.data}',
        );
        // Store as pending — will be processed after router is ready
        _pendingNotificationData = Map<String, dynamic>.from(initialMessage.data);
      }

      // 5. Setup token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _syncTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('FCM Initialization Error: $e');
    }
  }

  /// Process any pending notification that was received while app was terminated.
  /// Call this from main after the router and app are fully initialized.
  static void processPendingNotification() {
    if (_pendingNotificationData != null) {
      debugPrint('[FCM] Processing pending notification: $_pendingNotificationData');
      // Delay slightly to ensure navigation stack is fully ready
      Future.delayed(const Duration(milliseconds: 1500), () {
        _handleMessageTap(_pendingNotificationData!);
        _pendingNotificationData = null;
      });
    }
  }

  /// Explicitly fetch and sync token to backend
  static Future<void> syncToken() async {
    try {
      // On Web, this might fail with AbortError if push service is unavailable
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _syncTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM Token Error: $e');
    }
  }

  static Future<void> _setupLocalNotifications() async {
    // 1. Normal Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'lapor_fsm_channel_high_v2',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    // 2. Emergency Channel (Custom Sound)
    const AndroidNotificationChannel emergencyChannel =
        AndroidNotificationChannel(
          'lapor_fsm_channel_emergency_v3', // FORCE UPDATE V3
          'Emergency Alerts',
          description: 'Critical alerts requiring immediate attention.',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('emergency_alert'),
          playSound: true,
        );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await platform?.createNotificationChannel(channel);
    await platform?.createNotificationChannel(emergencyChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notif_small');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[FCM] Local notification tapped, payload: ${response.payload}');
        _onLocalNotificationTapped(response.payload);
      },
    );

    // DEBUG: Print Channels
    final List<AndroidNotificationChannel>? channels = await platform
        ?.getNotificationChannels();
    if (channels != null) {
      for (var c in channels) {
        debugPrint(
          'CHANNEL: ${c.id}, Name: ${c.name}, Sound: ${c.sound?.sound}, Importance: ${c.importance}',
        );
      }
    }
  }

  /// Handle tap on local notification (foreground notifications).
  /// The payload is a JSON string containing the data map from the FCM message.
  static void _onLocalNotificationTapped(String? payload) {
    if (payload == null || payload.isEmpty) {
      debugPrint('[FCM] No payload in local notification tap');
      return;
    }

    try {
      // Try parsing as JSON first (new format)
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('[FCM] Parsed notification payload: $data');
      _handleMessageTap(data);
    } catch (_) {
      // Fallback: payload is just a reportId string (old format)
      debugPrint('[FCM] Payload is plain reportId: $payload');
      _handleMessageTap({'reportId': payload});
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Determine Channel based on Data payload
      String channelId = 'lapor_fsm_channel_high_v2';
      String? sound;
      final bool isEmergency = message.data['type'] == 'emergency';

      if (isEmergency) {
        channelId = 'lapor_fsm_channel_emergency_v3';
        sound = 'emergency_alert';
      }

      // Encode the entire data map as JSON for the payload
      // so we can recover all fields (reportId, type, etc.) on tap
      final String payloadJson = jsonEncode(message.data);

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            isEmergency ? 'Emergency Alerts' : 'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: 'ic_notif_small',
            largeIcon: DrawableResourceAndroidBitmap(
              isEmergency ? 'notifikasi_darurat' : 'notifikasi_non_darurat',
            ),
            color: isEmergency
                ? const Color(0xFFFF0000)
                : const Color(0xFF0055A5),
            sound: sound != null
                ? RawResourceAndroidNotificationSound(sound)
                : null,
          ),
        ),
        payload: payloadJson,
      );
    }
  }

  /// Handle notification tap — navigate to report detail based on user role
  static void _handleMessageTap(Map<String, dynamic> data) async {
    final reportId = data['reportId'];
    debugPrint('[FCM] _handleMessageTap called with data: $data');

    if (reportId == null) {
      debugPrint('[FCM] No reportId in notification data, skipping navigation');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final role = prefs.getString('user_role');

      debugPrint('[FCM] User: $userId, Role: $role, ReportId: $reportId');

      if (userId != null && role != null) {
        String route;
        switch (role) {
          case 'teknisi':
            route = '/teknisi/report/$reportId';
          case 'supervisor':
            route = '/supervisor/review/$reportId';
          case 'pj_gedung':
            route = '/pj-gedung/report/$reportId';
          case 'admin':
            route = '/admin/reports/$reportId';
          default:
            route = '/report-detail/$reportId';
        }

        debugPrint('[FCM] Navigating to: $route');
        
        // Use appRouter.push with a small delay to ensure the router is ready
        await Future.delayed(const Duration(milliseconds: 300));
        appRouter.push(route);
        debugPrint('[FCM] Navigation push completed for: $route');
      } else {
        debugPrint('[FCM] No user/role found, cannot navigate');
      }
    } catch (e) {
      debugPrint('[FCM] Error handling notification tap: $e');
    }
  }

  static Future<void> _syncTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final role = prefs.getString('user_role');

      if (userId != null && role != null) {
        final type = (role == 'pelapor' || role == 'user') ? 'user' : 'staff';

        await apiService.dio.post(
          '/notifications/fcm-token',
          data: {'userId': userId, 'role': type, 'token': token},
        );
        debugPrint('FCM Token synced to backend for $type $userId');
      }
    } catch (e) {
      debugPrint('Failed to save FCM Token: $e');
    }
  }
}

