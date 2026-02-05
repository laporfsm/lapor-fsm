import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_categories_view.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_buildings_view.dart';

import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_specializations_view.dart';

class SupervisorMasterDataPage extends StatelessWidget {
  const SupervisorMasterDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.supervisorColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Master Data',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Kategori', icon: Icon(LucideIcons.tag)),
              Tab(text: 'Lokasi', icon: Icon(LucideIcons.building)),
              Tab(text: 'Spesialis', icon: Icon(LucideIcons.wrench)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SupervisorCategoriesView(),
            SupervisorBuildingsView(),
            SupervisorSpecializationsView(),
          ],
        ),
      ),
    );
  }
}
