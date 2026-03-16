import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return;
    // NOTE: Local notification initialization is handled by FCMService._setupLocalNotifications()
    // to avoid duplicate plugin instances that conflict with tap handlers.
    // This method is kept for backward compatibility but does nothing on mobile.
    debugPrint('[NotificationService] init() skipped — handled by FCMService');
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
          icon: 'ic_notif_small',
          largeIcon: DrawableResourceAndroidBitmap(
            isEmergency ? 'notifikasi_darurat' : 'notifikasi_non_darurat',
          ),
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
