import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/report.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/theme.dart';

class ReportHistoryPage extends StatelessWidget {
  const ReportHistoryPage({super.key});

  // Use centralized mock data for consistency
  List<Report> get _myReports => [
    MockReportData.getReportOrDefault('101'),
    MockReportData.getReportOrDefault('102'),
    MockReportData.getReportOrDefault('103'),
    MockReportData.getReportOrDefault('104'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Laporan Saya'),
        backgroundColor: Colors.white,
      ),
      body: _myReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.inbox,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const Gap(16),
                  const Text(
                    'Belum ada laporan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myReports.length,
              itemBuilder: (context, index) {
                final report = _myReports[index];
                return ReportCard(
                  report: report,
                  viewerRole: UserRole.pelapor,
                  showTimer: false,
                  onTap: () => context.push('/report-detail/${report.id}'),
                );
              },
            ),
    );
  }
}
