import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_activity_log_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_technician_list_page.dart';

class SupervisorTechnicianMainPage extends StatefulWidget {
  const SupervisorTechnicianMainPage({super.key});

  @override
  State<SupervisorTechnicianMainPage> createState() =>
      _SupervisorTechnicianMainPageState();
}

class _SupervisorTechnicianMainPageState
    extends State<SupervisorTechnicianMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Menu Teknisi'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.supervisorColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.supervisorColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Log Aktivitas', icon: Icon(LucideIcons.activity)),
            Tab(text: 'Manajemen Staff', icon: Icon(LucideIcons.users)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SupervisorActivityLogPage(),
          // Note: SupervisorTechnicianListPage has its own Scaffold.
          // Ideally should be refactored, but nested Scaffold works.
          SupervisorTechnicianListPage(),
        ],
      ),
    );
  }
}
