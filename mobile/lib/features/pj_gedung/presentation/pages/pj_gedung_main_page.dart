import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/auth/presentation/pages/staff_profile_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_dashboard_page.dart';
import 'package:mobile/theme.dart';

class PJGedungMainPage extends StatefulWidget {
  const PJGedungMainPage({super.key});

  @override
  State<PJGedungMainPage> createState() => _PJGedungMainPageState();
}

class _PJGedungMainPageState extends State<PJGedungMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PJGedungDashboardPage(),
    const Scaffold(
      body: Center(child: Text("Riwayat Verifikasi (Coming Soon)")),
    ), // Placeholder
    const StaffProfilePage(role: 'pjGedung'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(icon: Icon(LucideIcons.user), label: 'Profil'),
        ],
      ),
    );
  }
}
