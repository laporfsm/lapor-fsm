import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:mobile/features/notification/presentation/providers/notification_provider.dart';

/// Admin Notifications Page - using unified provider
class AdminNotificationsPage extends ConsumerWidget {
  const AdminNotificationsPage({super.key});

  void _markAsRead(WidgetRef ref, String id) {
    ref.read(notificationProvider.notifier).markAsRead(id);
  }

  void _markAllAsRead(WidgetRef ref, BuildContext context) {
    ref.read(notificationProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua ditandai sudah dibaca'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteNotification(WidgetRef ref, String id) {
    ref.read(notificationProvider.notifier).delete(id);
  }

  void _deleteAllNotifications(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua notifikasi?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).deleteAll();
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi dihapus'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    WidgetRef ref,
    BuildContext context,
    String id,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi?'),
        content: const Text('Notifikasi ini akan dihapus permanen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteNotification(ref, id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState
        .items; // For Admin, we might filter specific types if needed
    final unreadCount = notificationState.unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              IconButton(
                onPressed: () => _markAllAsRead(ref, context),
                icon: const Icon(LucideIcons.checkCheck, color: Colors.white),
                tooltip: 'Baca Semua',
              ),
            IconButton(
              onPressed: () => _deleteAllNotifications(ref, context),
              icon: const Icon(LucideIcons.trash2, color: Colors.white),
              tooltip: 'Hapus Semua',
            ),
            const Gap(8),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) =>
                  _buildNotificationCard(context, ref, notifications[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 48, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const Gap(4),
          Text(
            'Notifikasi baru akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationItem notification,
  ) {
    final bool isRead = notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Notifikasi?'),
            content: const Text('Notifikasi ini akan dihapus permanen.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(ref, notification.id);
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(ref, notification.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isRead
                ? null
                : Border.all(
                    color: const Color(
                      0xFF3B82F6,
                    ).withValues(alpha: 0.39), // aprox 100/255
                    width: 1.5,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isRead ? 0.03 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: NotificationData.getBgColor(notification.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    NotificationData.getIcon(notification.type),
                    color: NotificationData.getIconColor(notification.type),
                    size: 20,
                  ),
                ),
                const Gap(12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          // Explicit delete button on card
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () =>
                                _confirmDelete(ref, context, notification.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _formatTime(notification.time),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }
}
