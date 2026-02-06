import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_dashboard_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/supervisor_setting_main_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_reports_container_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_navigation_provider.dart';

import 'package:mobile/core/theme.dart';

/// Supervisor theme color - Dark Blue-Purple (Indigo 800)
const Color supervisorColor = AppTheme.supervisorColor;

/// Shell page untuk Supervisor dengan persistent bottom navigation bar.
/// Menggunakan IndexedStack untuk mempertahankan state setiap tab.
class SupervisorShellPage extends ConsumerStatefulWidget {
  const SupervisorShellPage({super.key});

  @override
  ConsumerState<SupervisorShellPage> createState() =>
      _SupervisorShellPageState();
}

class _SupervisorShellPageState extends ConsumerState<SupervisorShellPage> {
  // Local state is now managed by provider for the index

  final List<Widget> _pages = const [
    SupervisorDashboardPage(), // Tab 0: Dashboard
    SupervisorReportsContainerPage(), // Tab 1: Laporan
    SupervisorSettingMainPage(), // Tab 2: Setting
  ];

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(supervisorNavigationProvider);
    final currentIndex = navState.bottomNavIndex;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
                _buildNavItem(1, LucideIcons.clipboardList, 'Laporan'),
                _buildNavItem(2, LucideIcons.settings, 'Setting'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final currentIndex = ref.watch(supervisorNavigationProvider).bottomNavIndex;
    final isSelected = currentIndex == index;
    final color = isSelected ? AppTheme.supervisorColor : Colors.grey;

    return GestureDetector(
      onTap: () {
        ref
            .read(supervisorNavigationProvider.notifier)
            .setBottomNavIndex(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.supervisorColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
