import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

/// A scaffold wrapper that includes persistent BottomNavigationBar for Pelapor role.
class PelaporScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const PelaporScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/feed');
              break;
            case 2:
              context.go('/history');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.newspaper), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: "Aktivitas"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: "Profil"),
        ],
      ),
    );
  }
}
