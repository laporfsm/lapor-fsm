import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

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
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  List<NotificationItem> get _notifications => [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.checkCheck,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              // Mark all as read action
            },
            tooltip: 'Tandai semua dibaca',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Gap(12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return _buildNotificationCard(context, item);
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItem item) {
    Color iconColor;
    IconData icon;
    Color bgColor;

    switch (item.type) {
      case 'emergency':
        iconColor = Colors.red;
        icon = LucideIcons.alertTriangle;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'success':
        iconColor = Colors.green;
        icon = LucideIcons.checkCircle2;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'warning':
        iconColor = Colors.orange;
        icon = LucideIcons.alertCircle;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      default:
        iconColor = AppTheme.primaryColor;
        icon = LucideIcons.info;
        bgColor = AppTheme.primaryColor.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead
              ? Colors.grey.shade200
              : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          if (!item.isRead)
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item.isRead ? Colors.black87 : Colors.black,
                      ),
                    ),
                    Text(
                      _formatTime(item.time),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else {
      return '${difference.inDays}h lalu';
    }
  }
}
