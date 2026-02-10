import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';

/// Active reports page showing penanganan and onHold reports
class TeknisiActivePage extends StatefulWidget {
  const TeknisiActivePage({super.key});

  @override
  State<TeknisiActivePage> createState() => _TeknisiActivePageState();
}

class _TeknisiActivePageState extends State<TeknisiActivePage> {
  bool _isLoading = true;
  List<Report> _activeReports = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final results = await Future.wait([
          reportService.getStaffReports(
            role: 'technician',
            status: 'penanganan',
          ),
          reportService.getStaffReports(role: 'technician', status: 'onHold'),
        ]);

        if (mounted) {
          setState(() {
            final processingData = List<Map<String, dynamic>>.from(
              results[0]['data'] ?? [],
            );
            final processing = processingData
                .map((json) => Report.fromJson(json))
                .toList();

            final onHoldData = List<Map<String, dynamic>>.from(
              results[1]['data'] ?? [],
            );
            final onHold = onHoldData
                .map((json) => Report.fromJson(json))
                .toList();

            _activeReports = [...processing, ...onHold];

            // Sort: penanganan first, then onHold. Same status sorted by date.
            _activeReports.sort((a, b) {
              if (a.status == ReportStatus.penanganan &&
                  b.status == ReportStatus.onHold) {
                return -1;
              } else if (a.status == ReportStatus.onHold &&
                  b.status == ReportStatus.penanganan) {
                return 1;
              }
              return b.createdAt.compareTo(a.createdAt);
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching active reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final penangananCount = _activeReports
        .where((r) => r.status == ReportStatus.penanganan)
        .length;
    final onHoldCount = _activeReports
        .where((r) => r.status == ReportStatus.onHold)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Laporan Aktif',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.teknisiColor,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  'Dikerjakan',
                  penangananCount,
                  Colors.blue,
                  LucideIcons.hammer,
                ),
                const Gap(8),
                _buildFilterChip(
                  'On Hold',
                  onHoldCount,
                  Colors.orange,
                  LucideIcons.pauseCircle,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _activeReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const Gap(16),
                  Text(
                    'Tidak ada laporan aktif',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const Gap(8),
                  Text(
                    'Mulai kerjakan laporan dari tab Masuk',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _activeReports.length,
                itemBuilder: (context, index) {
                  final report = _activeReports[index];
                  final elapsed = DateTime.now().difference(report.createdAt);

                  return UniversalReportCard(
                    id: report.id,
                    title: report.title,
                    location: report.location,
                    locationDetail: report.locationDetail,
                    category: report.category,
                    status: report.status,
                    isEmergency: report.isEmergency,
                    elapsedTime: elapsed,
                    showStatus: true,
                    showTimer: true,
                    onTap: () async {
                      await context.push('/teknisi/report/${report.id}');
                      _fetchData();
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // _buildActionButton removed
}
