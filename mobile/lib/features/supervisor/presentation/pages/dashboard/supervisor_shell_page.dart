import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_dashboard_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/profile/supervisor_profile_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_technician_main_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_reports_container_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_navigation_provider.dart';

/// Supervisor theme color - Dark Blue-Purple (Indigo 800) (differentiated from Pelapor blue & Teknisi orange)
const Color supervisorColor = Color(0xFF3730A3);

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
    SupervisorTechnicianMainPage(), // Tab 1: Staff
    SupervisorReportsContainerPage(), // Tab 2: Laporan
    SupervisorProfilePage(), // Tab 3: Setting (was Profil)
  ];

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(supervisorNavigationProvider);
    final currentIndex = navState.bottomNavIndex;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: supervisorColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          ref
              .read(supervisorNavigationProvider.notifier)
              .setBottomNavIndex(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.fileText),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings), // Changed to Settings
            label: 'Setting', // Renamed from Profil
          ),
        ],
      ),
    );
  }
}
