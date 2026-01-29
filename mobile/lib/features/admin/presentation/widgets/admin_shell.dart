import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/theme.dart';

/// Admin Shell - Persistent Bottom Navigation for Admin Pages
class AdminShell extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  void initState() {
    super.initState();
    // Initial fetch
    adminService.fetchPendingUserCount();
  }

  int _getIndex() {
    if (widget.currentLocation.startsWith('/admin/users')) return 1;
    if (widget.currentLocation.startsWith('/admin/verification')) return 1;
    if (widget.currentLocation.startsWith('/admin/staff')) return 1;
    if (widget.currentLocation.startsWith('/admin/reports')) return 2;
    if (widget.currentLocation.startsWith('/admin/logs')) return 3;
    if (widget.currentLocation.startsWith('/admin/profile')) return 4;
    return 0; // Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndex();

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.layoutDashboard,
                  label: 'Dashboard',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/admin/dashboard'),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: adminService.pendingUserCount,
                  builder: (context, count, _) {
                    return _NavItem(
                      icon: LucideIcons.users,
                      label: 'Users',
                      isSelected: currentIndex == 1,
                      badge: count,
                      onTap: () => context.go('/admin/users'),
                    );
                  },
                ),
                _NavItem(
                  icon: LucideIcons.fileText,
                  label: 'Laporan',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/admin/reports'),
                ),
                _NavItem(
                  icon: LucideIcons.history, // or LucideIcons.scrollText
                  label: 'Log',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/admin/logs'),
                ),
                _NavItem(
                  icon: LucideIcons.user,
                  label: 'Profil',
                  isSelected: currentIndex == 4,
                  onTap: () => context.go('/admin/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    // Use the theme color (Purple)
    const selectedColor = AppTheme.adminColor;
    final unselectedColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Squeezing font slightly for 5 items
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
