import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/teknisi/presentation/pages/dashboard/teknisi_dashboard_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_incoming_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_active_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_history_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/profile/teknisi_profile_page.dart';

/// Teknisi Shell Page with bottom navigation
class TeknisiHomePage extends StatefulWidget {
  const TeknisiHomePage({super.key});

  @override
  State<TeknisiHomePage> createState() => _TeknisiHomePageState();
}

class _TeknisiHomePageState extends State<TeknisiHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TeknisiDashboardPage(),
    TeknisiIncomingPage(),
    TeknisiActivePage(),
    TeknisiHistoryPage(),
    TeknisiProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
                _buildNavItem(1, LucideIcons.inbox, 'Masuk'),
                _buildNavItem(2, LucideIcons.hammer, 'Aktif'),
                _buildNavItem(3, LucideIcons.history, 'Riwayat'),
                _buildNavItem(4, LucideIcons.user, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.secondaryColor : Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
