import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart';
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
                        supervisorColor.withOpacity(0.4),
                        supervisorColor.withOpacity(0.7),
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
            // Filtered to show all strictly active statuses + Selesai (waiting approval)
            SharedAllReportsPage(
              showAppBar: false, // Hide inner AppBar
              onReportTap: (reportId, status) =>
                  context.push('/supervisor/review/$reportId'),
              initialStatuses: const [
                ReportStatus.pending,
                ReportStatus.terverifikasi,
                ReportStatus.verifikasi,
                ReportStatus.diproses,
                ReportStatus.penanganan,
                ReportStatus.onHold,
                ReportStatus.selesai,
                ReportStatus.recalled, // Added Recalled to initial
              ],
              allowedStatuses: const [
                // Only show relevant active statuses in filter
                ReportStatus.pending,
                ReportStatus.terverifikasi,
                ReportStatus.verifikasi,
                ReportStatus.diproses,
                ReportStatus.penanganan,
                ReportStatus.onHold,
                ReportStatus.selesai,
                ReportStatus
                    .recalled, // Optional: keep recycled here if supervisor needs to filter it, otherwise remove
              ],
              showBackButton: false, // It's a tab
              appBarColor: supervisorColor, // Pass supervisor theme
            ),

            // Tab 2: Riwayat
            // Filtered to Approved & Ditolak
            SharedAllReportsPage(
              showAppBar: false, // Hide inner AppBar
              onReportTap: (reportId, status) =>
                  context.push('/supervisor/review/$reportId'),
              initialStatuses: const [
                ReportStatus.approved,
                ReportStatus.ditolak,
              ],
              allowedStatuses: const [
                // Only show Approved & Ditolak in filter
                ReportStatus.approved,
                ReportStatus.ditolak,
                // Removed Arsip as requested
              ],
              showBackButton: false,
              appBarColor: supervisorColor, // Pass supervisor theme
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showExportOptions(context),
          backgroundColor: Colors.white,
          child: const Icon(LucideIcons.download, color: Colors.green),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Laporan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Unduh data laporan yang sedang ditampilkan.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  LucideIcons.fileSpreadsheet,
                  color: Colors.green,
                ),
                title: const Text('Export ke Excel (.xlsx)'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh Excel... (Mock)')),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: Colors.red),
                title: const Text('Export ke PDF (.pdf)'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh PDF... (Mock)')),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
