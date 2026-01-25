import 'package:flutter/material.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_reports_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_archive_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart'; // for supervisorColor

class SupervisorReportsContainerPage extends StatelessWidget {
  const SupervisorReportsContainerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          backgroundColor: supervisorColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Aktif
            // Passing status filters for Active tab
            SupervisorReportsListPage(
              isTabMode: true,
              filterStatuses: [
                'pending',
                'terverifikasi',
                'diproses',
                'penanganan',
                'onHold',
                'selesai',
              ],
            ),

            // Tab 2: Riwayat
            // Using the specialized Archive/History view
            SupervisorArchivePage(),
          ],
        ),
      ),
    );
  }
}
