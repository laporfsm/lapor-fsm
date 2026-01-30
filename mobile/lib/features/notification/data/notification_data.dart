import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

// Simple Notification Model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String type; // 'info', 'warning', 'success', 'emergency'

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      time: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'info',
    );
  }
}

class NotificationData {
  static List<NotificationItem> get notifications => [
    NotificationItem(
      id: '1',
      title: 'Laporan Darurat Baru',
      message:
          'Ada laporan darurat di Gedung A, Toilet Pria yang perlu segera ditangani.',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      type: 'emergency',
    ),
    NotificationItem(
      id: '2',
      title: 'Laporan Selesai',
      message: 'Teknisi Budi telah menyelesaikan perbaikan AC di Ruang 101.',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      type: 'success',
    ),
    NotificationItem(
      id: '3',
      title: 'Verifikasi Diperlukan',
      message: 'Laporan baru menunggu verifikasi Anda.',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
      type: 'info',
    ),
    NotificationItem(
      id: '4',
      title: 'Jadwal Maintenance',
      message: 'Maintenance server dijadwalkan nanti malam pukul 00:00.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: 'warning',
    ),
  ];

  static int get unreadCount => notifications.where((n) => !n.isRead).length;

  static Color getIconColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case 'emergency':
        return LucideIcons.alertTriangle;
      case 'success':
        return LucideIcons.checkCircle2;
      case 'warning':
        return LucideIcons.alertCircle;
      default:
        return LucideIcons.info;
    }
  }

  static Color getBgColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red.withValues(alpha: 0.1);
      case 'success':
        return Colors.green.withValues(alpha: 0.1);
      case 'warning':
        return Colors.orange.withValues(alpha: 0.1);
      default:
        return AppTheme.primaryColor.withValues(alpha: 0.1);
    }
  }
}
