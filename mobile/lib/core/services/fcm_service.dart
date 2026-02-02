import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'lapor_fsm_channel_high', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'lapor_fsm_channel_high',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: android.smallIcon,
            color: const Color(0xFF0055A5), // Primary Color
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
