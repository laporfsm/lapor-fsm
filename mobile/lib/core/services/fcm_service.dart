import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/api_service.dart';

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

  static Future<void> init() async {
    // 1. Initialize Firebase
    // Note: Firebase.initializeApp() is usually called in main.dart,
    // but ensuring it's ready here won't hurt.

    // 2. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 3. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Setup Local Notifications Channel (Android)
    await _setupLocalNotifications();

    // 5. Setup Foreground Handler
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

    // 6. Get Token & Save
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _saveTokenToBackend(token);
    }

    // 7. Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });
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
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);

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

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Determine Channel based on Data payload
      String channelId = 'lapor_fsm_channel_high_v2';
      String? sound;

      if (message.data['type'] == 'emergency') {
        channelId = 'lapor_fsm_channel_emergency_v3';
        sound = 'emergency_alert';
      }

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'lapor_fsm_channel_emergency_v3'
                ? 'Emergency Alerts'
                : 'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: android.smallIcon,
            color: const Color(0xFF0055A5), // Primary Color
            sound: sound != null
                ? RawResourceAndroidNotificationSound(sound)
                : null,
          ),
        ),
      );
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final userId = user['id'];
        final role = user['role'];
        final type = (role == 'pelapor' || role == 'user') ? 'user' : 'staff';

        await apiService.dio.post(
          '/notifications/fcm-token',
          data: {'userId': userId, 'role': type, 'token': token},
        );
        debugPrint('FCM Token synced to backend');
      }
    } catch (e) {
      debugPrint('Failed to save FCM Token: $e');
    }
  }
}
