import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';
import 'package:go_router/go_router.dart';

class SupervisorReportsContainerPage extends StatelessWidget {
  const SupervisorReportsContainerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1581094794329-cd675335442b?auto=format&fit=crop&q=80&w=1000',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: supervisorColor),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        supervisorColor.withValues(alpha: 0.4),
                        supervisorColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [],
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
        body: TabBarView(
          children: [
            // Tab 1: Aktif
            SharedAllReportsPage(
              showAppBar: false, // Hide inner AppBar
              onReportTap: (reportId, status) =>
                  context.push('/supervisor/review/$reportId'),
              initialStatuses: const [
                ReportStatus.pending,
                ReportStatus.terverifikasi,
                // ReportStatus.verifikasi, // REMOVED
                ReportStatus.diproses,
                ReportStatus.penanganan,
                ReportStatus.onHold,
                ReportStatus.selesai,
                ReportStatus.recalled,
              ],
              allowedStatuses: const [
                // Only show relevant active statuses in filter
                ReportStatus.pending,
                ReportStatus.terverifikasi,
                ReportStatus.diproses,
                ReportStatus.penanganan,
                ReportStatus.onHold,
                ReportStatus.selesai,
                ReportStatus.recalled,
              ],
              showBackButton: false, // It's a tab
              appBarColor: supervisorColor, // Pass supervisor theme
              role:
                  'supervisor', // Added: use supervisor endpoint for proper data fetching
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.push('/supervisor/export'),
                backgroundColor: Colors.white,
                child: const Icon(LucideIcons.download, color: Colors.green),
              ),
            ),

            // Tab 2: Riwayat
            SharedAllReportsPage(
              showAppBar: false, // Hide inner AppBar
              onReportTap: (reportId, status) =>
                  context.push('/supervisor/review/$reportId'),
              initialStatuses: const [
                ReportStatus.approved,
                ReportStatus.ditolak,
              ],
              allowedStatuses: const [
                ReportStatus.approved,
                ReportStatus.ditolak,
              ],
              showBackButton: false,
              appBarColor: supervisorColor, // Pass supervisor theme
              role: 'supervisor',
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.push('/supervisor/export'),
                backgroundColor: Colors.white,
                child: const Icon(LucideIcons.download, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
