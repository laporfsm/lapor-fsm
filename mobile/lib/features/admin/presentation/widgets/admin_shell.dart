import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Admin Shell - Persistent Bottom Navigation for Admin Pages
class AdminShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  int _getIndex() {
    if (currentLocation.startsWith('/admin/verifikasi')) return 1;
    if (currentLocation.startsWith('/admin/notifikasi')) return 2;
    if (currentLocation.startsWith('/admin/profil')) return 3;
    return 0; // Beranda
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndex();

    return Scaffold(
      body: child,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.layoutDashboard,
                  label: 'Beranda',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/admin'),
                ),
                _NavItem(
                  icon: LucideIcons.userCheck,
                  label: 'Verifikasi',
                  isSelected: currentIndex == 1,
                  badge: 3, // Pending count
                  onTap: () => context.go('/admin/verifikasi'),
                ),
                _NavItem(
                  icon: LucideIcons.bell,
                  label: 'Notifikasi',
                  isSelected: currentIndex == 2,
                  badge: 2, // Unread count
                  onTap: () => context.go('/admin/notifikasi'),
                ),
                _NavItem(
                  icon: LucideIcons.user,
                  label: 'Profil',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/admin/profil'),
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
    const selectedColor = Color(0xFF059669);
    final unselectedColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          horizontal: 5, vertical: 2),
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
                fontSize: 11,
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
