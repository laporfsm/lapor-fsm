import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/dashboard/pj_gedung_dashboard_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/reports/pj_gedung_history_page.dart';
// Placeholders - will be created/renamed in subsequent steps
import 'package:mobile/features/pj_gedung/presentation/pages/reports/pj_gedung_verification_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/setting/pj_gedung_setting_main_page.dart';

/// PJ Gedung Shell Page with bottom navigation (Standardized with Technician)
class PJGedungHomePage extends StatefulWidget {
  const PJGedungHomePage({super.key});

  @override
  State<PJGedungHomePage> createState() => _PJGedungHomePageState();
}

class _PJGedungHomePageState extends State<PJGedungHomePage> {
  int _currentIndex = 0;

  // Pages corresponding to tabs
  final List<Widget> _pages = const [
    PJGedungDashboardPage(),
    PJGedungVerificationPage(),
    PJGedungHistoryPage(),
    PJGedungSettingMainPage(),
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
                _buildNavItem(1, LucideIcons.clipboardCheck, 'Verifikasi'),
                _buildNavItem(2, LucideIcons.history, 'Riwayat'),
                _buildNavItem(3, LucideIcons.settings, 'Setting'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    // PJ Gedung theme color is Emerald Green usually, or we can use generic secondary if matched
    // Technician uses AppTheme.secondaryColor (Orange).
    // PJ Gedung should probably use its own color scheme for active state?
    // Supervisor Home uses _supervisorColor.
    // PJ Gedung Dashboard uses pjGedungColor = Color(0xFF059669);
    // Let's use pjGedungColor if defined in theme or locally.
    const activeColor = Color(0xFF059669); // pjGedungColor

    final isSelected = _currentIndex == index;
    final color = isSelected ? activeColor : Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
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
