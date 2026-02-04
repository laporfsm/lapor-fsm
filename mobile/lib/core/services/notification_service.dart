import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String message,
    bool isEmergency = false,
    String? payload,
  }) async {
    debugPrint('NotificationService: showNotification ($title: $message)');

    if (kIsWeb) return;

    final String channelId = isEmergency
        ? 'lapor_fsm_channel_emergency_v3'
        : 'lapor_fsm_channel_high_v2';
    final String channelName = isEmergency
        ? 'Emergency Alerts'
        : 'High Importance Notifications';
    final String channelDescription = isEmergency
        ? 'Critical alerts requiring immediate attention.'
        : 'This channel is used for important notifications.';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          color: isEmergency
              ? const Color(0xFFFF0000)
              : const Color(0xFF0055A5),
          sound: isEmergency
              ? const RawResourceAndroidNotificationSound('emergency_alert')
              : null,
          playSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: isEmergency
            ? 'emergency_alert.wav'
            : null, // Fallback placeholder for iOS
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      message,
      notificationDetails,
      payload: payload,
    );
  }
}
