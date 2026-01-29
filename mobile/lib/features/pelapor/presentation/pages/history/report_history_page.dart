import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/theme.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  List<Report> _myReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    
    final user = await authService.getCurrentUser();
    if (user != null) {
      final reportsData = await reportService.getMyReports(
        user['id'].toString(),
        role: user['role'],
      );
      debugPrint('History Page: Received ${reportsData.length} reports for user ${user['id']} (Role: ${user['role']})');
      if (mounted) {
        setState(() {
          _myReports = reportsData.map((json) {
            try {
              final r = Report.fromJson(json);
              debugPrint('Mapping History Report: ${r.id} - ${r.title}');
              return r;
            } catch (e) {
              debugPrint('Error mapping history report: $e. JSON: $json');
              return null;
            }
          }).whereType<Report>().toList();
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReports,
              child: _myReports.isEmpty
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
                        return UniversalReportCard(
                          id: report.id,
                          title: report.title,
                          category: report.category,
                          location: report.building,
                          locationDetail: report.locationDetail,
                          status: report.status,
                          elapsedTime: DateTime.now().difference(report.createdAt),
                          showStatus: true,
                          compact: false,
                          onTap: () => context.push('/report-detail/${report.id}'),
                        );
                      },
                    ),
            ),
    );
  }
}
