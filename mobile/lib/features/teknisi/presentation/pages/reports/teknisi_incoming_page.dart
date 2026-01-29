import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/theme.dart';

/// Incoming reports page with tabs for Darurat and Umum
class TeknisiIncomingPage extends StatefulWidget {
  const TeknisiIncomingPage({super.key});

  @override
  State<TeknisiIncomingPage> createState() => _TeknisiIncomingPageState();
}

class _TeknisiIncomingPageState extends State<TeknisiIncomingPage>
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

  // TODO: [BACKEND] Replace with API call
  List<Report> get _emergencyReports => MockReportData.allReports
      .where((r) => r.status == ReportStatus.diproses && r.isEmergency)
      .toList();

  List<Report> get _regularReports => MockReportData.allReports
      .where((r) => r.status == ReportStatus.diproses && !r.isEmergency)
      .toList();

  @override
  Widget build(BuildContext context) {
    final emergencyCount = _emergencyReports.length;
    final regularCount = _regularReports.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Laporan Masuk'),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16),
                  const Gap(6),
                  const Text('Darurat'),
                  if (emergencyCount > 0) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        emergencyCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.inbox, size: 16),
                  const Gap(6),
                  const Text('Umum'),
                  if (regularCount > 0) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        regularCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList(_emergencyReports, isEmergencyTab: true),
          _buildReportsList(_regularReports, isEmergencyTab: false),
        ],
      ),
    );
  }

  Widget _buildReportsList(
    List<Report> reports, {
    required bool isEmergencyTab,
  }) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmergencyTab ? LucideIcons.checkCircle : LucideIcons.inbox,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const Gap(16),
            Text(
              isEmergencyTab
                  ? 'Tidak ada laporan darurat'
                  : 'Tidak ada laporan umum',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: [BACKEND] Refresh data
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          final elapsed = DateTime.now().difference(report.createdAt);

          return UniversalReportCard(
            id: report.id,
            title: report.title,
            location: report.building,
            locationDetail: report.locationDetail,
            category: report.category,
            status: report.status,
            isEmergency: report.isEmergency,
            elapsedTime: elapsed,
            showStatus: true,
            showTimer: true,
            onTap: () => context.push('/teknisi/report/${report.id}'),
            actionButton: ElevatedButton.icon(
              onPressed: () => context.push('/teknisi/report/${report.id}'),
              icon: const Icon(LucideIcons.play, size: 18),
              label: const Text('Mulai Penanganan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmergencyTab
                    ? AppTheme.emergencyColor
                    : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
