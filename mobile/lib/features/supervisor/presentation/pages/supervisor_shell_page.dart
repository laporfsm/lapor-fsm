import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_dashboard_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_reports_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_archive_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_profile_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_technician_main_page.dart';

/// Supervisor theme color - Dark Blue-Purple (Indigo 800) (differentiated from Pelapor blue & Teknisi orange)
const Color supervisorColor = Color(0xFF3730A3);

/// Shell page untuk Supervisor dengan persistent bottom navigation bar.
/// Menggunakan IndexedStack untuk mempertahankan state setiap tab.
class SupervisorShellPage extends StatefulWidget {
  const SupervisorShellPage({super.key});

  @override
  State<SupervisorShellPage> createState() => _SupervisorShellPageState();
}

class _SupervisorShellPageState extends State<SupervisorShellPage> {
  int _currentIndex = 0;

  // List of pages for each tab
  // NOTE: Each page should NOT have its own Scaffold with bottom nav
  final List<Widget> _pages = const [
    SupervisorDashboardPage(), // Tab 0: Dashboard
    SupervisorTechnicianMainPage(), // Tab 1: Teknisi (NEW)
    SupervisorReportsListPage(), // Tab 2: Laporan
    SupervisorArchivePage(), // Tab 3: Arsip
    SupervisorProfilePage(), // Tab 4: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: supervisorColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
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
            icon: Icon(LucideIcons.archive),
            label: 'Arsip',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
