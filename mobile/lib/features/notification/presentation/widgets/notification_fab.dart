import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_bottom_sheet.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';

class NotificationFab extends StatelessWidget {
  final Color? backgroundColor;

  const NotificationFab({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final unreadCount = NotificationData.unreadCount;

    return BouncingButton(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const NotificationBottomSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(
            16,
          ), // Slightly more square than circle for modern feel
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? AppTheme.primaryColor).withOpacity(
                0.3,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
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
      ),
    );
  }
}
