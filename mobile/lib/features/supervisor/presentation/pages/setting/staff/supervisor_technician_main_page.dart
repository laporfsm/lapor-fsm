import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_activity_log_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_staff_management_page.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_navigation_provider.dart';

class SupervisorTechnicianMainPage extends ConsumerStatefulWidget {
  const SupervisorTechnicianMainPage({super.key});

  @override
  ConsumerState<SupervisorTechnicianMainPage> createState() =>
      _SupervisorTechnicianMainPageState();
}

class _SupervisorTechnicianMainPageState
    extends ConsumerState<SupervisorTechnicianMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync tab index when provider changes
    // However, avoid calling setState during build, so we listen in build or use ref.listen
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(supervisorNavigationProvider, (previous, next) {
      if (next.staffTabIndex != _tabController.index) {
        _tabController.animateTo(next.staffTabIndex);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Menu Staff'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
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
          SupervisorActivityLogPage(isEmbedded: true),
          SupervisorStaffManagementPage(),
        ],
      ),
    );
  }
}
