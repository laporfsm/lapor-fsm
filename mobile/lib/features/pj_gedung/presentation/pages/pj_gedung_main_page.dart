import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_profile_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_dashboard_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_history_page.dart';

class PJGedungMainPage extends StatefulWidget {
  const PJGedungMainPage({super.key});

  @override
  State<PJGedungMainPage> createState() => _PJGedungMainPageState();
}

class _PJGedungMainPageState extends State<PJGedungMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PJGedungDashboardPage(),
    const PJGedungHistoryPage(),
    const PJGedungProfilePage(),
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
