import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:mobile/features/notification/presentation/providers/notification_provider.dart';
import 'package:mobile/core/theme.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  void _markAsRead(WidgetRef ref, String id) {
    ref.read(notificationProvider.notifier).markAsRead(id);
  }

  void _markAllAsRead(WidgetRef ref, BuildContext context) {
    ref.read(notificationProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sudah dibaca'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteNotification(WidgetRef ref, String id) {
    ref.read(notificationProvider.notifier).delete(id);
  }

  void _deleteAll(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua notifikasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).deleteAll();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.items;
    final unreadCount = notificationState.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              IconButton(
                onPressed: () => _markAllAsRead(ref, context),
                icon: const Icon(
                  LucideIcons.checkCheck,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Tandai semua dibaca',
              ),
            IconButton(
              onPressed: () => _deleteAll(ref, context),
              icon: const Icon(LucideIcons.trash2, color: Colors.grey),
              tooltip: 'Hapus semua',
            ),
            const Gap(8),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bellOff,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const Gap(16),
                  Text(
                    'Tidak ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationItem(context, ref, item);
              },
            ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(LucideIcons.trash2, color: Colors.red.shade700),
      ),
      onDismissed: (_) => _deleteNotification(ref, item.id),
      child: GestureDetector(
        onTap: () {
          if (!item.isRead) {
            _markAsRead(ref, item.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NotificationData.getBgColor(item.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  NotificationData.getIcon(item.type),
                  size: 20,
                  color: NotificationData.getIconColor(item.type),
                ),
              ),
              const Gap(16),
              // Content
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
                            fontSize: 14,
                            color: item.isRead
                                ? Colors.black87
                                : Colors.blue.shade900,
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
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
                    const Gap(8),
                    Text(
                      _formatTime(item.time),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} hari yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }
}
