import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_bottom_sheet.dart';

class NotificationFab extends StatelessWidget {
  const NotificationFab({super.key});

  @override
  Widget build(BuildContext context) {
    final unreadCount = NotificationData.unreadCount;

    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const NotificationBottomSheet(),
        );
      },
      backgroundColor: AppTheme.primaryColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(LucideIcons.bell, color: Colors.white),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
