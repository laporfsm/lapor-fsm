import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/pelapor/presentation/pages/home_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/feed/public_feed_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/history/report_history_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/profile_page.dart';

/// Pelapor Shell Page with bottom navigation (IndexedStack pattern)
class PelaporHomePage extends StatefulWidget {
  const PelaporHomePage({super.key});

  @override
  State<PelaporHomePage> createState() => _PelaporHomePageState();
}

class _PelaporHomePageState extends State<PelaporHomePage> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _pages => [
    HomePage(onTabSwitch: _switchTab),
    const PublicFeedPage(),
    const ReportHistoryPage(),
    const ProfilePage(),
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
                _buildNavItem(0, LucideIcons.home, 'Beranda'),
                _buildNavItem(1, LucideIcons.newspaper, 'Feed'),
                _buildNavItem(2, LucideIcons.fileText, 'Riwayat'),
                _buildNavItem(3, LucideIcons.settings, 'Setting'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
