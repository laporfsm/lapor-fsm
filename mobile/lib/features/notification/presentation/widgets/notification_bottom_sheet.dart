import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:mobile/features/notification/presentation/providers/notification_provider.dart';

class NotificationBottomSheet extends ConsumerWidget {
  const NotificationBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.items;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Gap(12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(notificationProvider.notifier).markAllAsRead();
                  },
                  child: const Text('Tandai semua dibaca'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const Gap(16),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Gap(16),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      // Use InkWell to allow tapping to mark as read
                      return InkWell(
                        onTap: () async {
                          ref
                              .read(notificationProvider.notifier)
                              .markAsRead(item.id);

                          if (item.reportId != null && context.mounted) {
                            // Fetch user info BEFORE popping to ensure context remains mounted during async call
                            final user = await authService.getCurrentUser();
                            final role = user?['role'];

                            if (!context.mounted) return;

                            // Cache router before popping
                            final router = GoRouter.of(context);

                            Navigator.pop(context); // Close bottom sheet

                            if (role == 'pelapor' || role == 'user') {
                              router.push('/report-detail/${item.reportId}');
                            } else if (role == 'teknisi') {
                              router.push('/teknisi/report/${item.reportId}');
                            } else if (role == 'supervisor') {
                              router.push(
                                '/supervisor/review/${item.reportId}',
                              );
                            } else if (role == 'pj_gedung') {
                              router.push('/pj-gedung/report/${item.reportId}');
                            } else if (role == 'admin') {
                              router.push('/admin/reports/${item.reportId}');
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: _buildModalNotificationItem(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalNotificationItem(NotificationItem item) {
    final color = NotificationData.getIconColor(item.type);
    final icon = NotificationData.getIcon(item.type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: item.isRead ? Colors.black87 : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(8),
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
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
