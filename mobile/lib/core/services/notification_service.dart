import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelIdDefault = 'lapor_fsm_default';
  static const String _channelNameDefault = 'General Notifications';
  static const String _channelDescDefault = 'Notifications for general updates';

  static const String _channelIdEmergency = 'lapor_fsm_emergency';
  static const String _channelNameEmergency = 'Emergency Alerts';
  static const String _channelDescEmergency =
      'High priority alerts for emergency reports';

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings (minimal for now)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Create Channels (Android)
    final AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
          _channelIdDefault,
          _channelNameDefault,
          description: _channelDescDefault,
          importance: Importance.max, // High to show popup
          playSound: true,
        );

    final AndroidNotificationChannel emergencyChannel =
        AndroidNotificationChannel(
          _channelIdEmergency,
          _channelNameEmergency,
          description: _channelDescEmergency,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(
            'emergency_alert',
          ), // Custom Sound
          enableVibration: true,
        );

    final platform = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (platform != null) {
      await platform.createNotificationChannel(defaultChannel);
      await platform.createNotificationChannel(emergencyChannel);
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String message,
    bool isEmergency = false,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          isEmergency ? _channelIdEmergency : _channelIdDefault,
          isEmergency ? _channelNameEmergency : _channelNameDefault,
          channelDescription: isEmergency
              ? _channelDescEmergency
              : _channelDescDefault,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          sound: isEmergency
              ? const RawResourceAndroidNotificationSound('emergency_alert')
              : null,
          color: isEmergency
              ? const Color(0xFFEF4444)
              : null, // Red for emergency
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      message,
      platformDetails,
      payload: payload,
    );
  }
}
