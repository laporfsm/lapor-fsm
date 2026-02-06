import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

/// Page to display all non-gedung pending reports
/// (Reports from locations that don't have a PJ Lokasi)
class SupervisorNonLokasiPage extends StatefulWidget {
  const SupervisorNonLokasiPage({super.key});

  @override
  State<SupervisorNonLokasiPage> createState() =>
      _SupervisorNonLokasiPageState();
}

class _SupervisorNonLokasiPageState extends State<SupervisorNonLokasiPage> {
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await reportService.getNonLokasiReports(limit: 100);
      setState(() {
        _reports = data.map((json) => Report.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Laporan Non-Lokasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade300),
            const Gap(16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const Gap(16),
            ElevatedButton(
              onPressed: _loadReports,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPin, size: 64, color: Colors.grey.shade300),
            const Gap(16),
            Text(
              'Tidak ada laporan non-lokasi',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const Gap(8),
            Text(
              'Laporan dari lokasi tanpa PJ\nakan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.supervisorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.supervisorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 20,
                      color: AppTheme.supervisorColor,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        '${_reports.length} laporan dari lokasi tanpa PJ Lokasi',
                        style: TextStyle(
                          color: AppTheme.supervisorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final report = _reports[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UniversalReportCard(
              id: report.id,
              title: report.title,
              location: report.location,
              locationDetail: report.locationDetail,
              category: report.category,
              status: report.status,
              isEmergency: report.isEmergency,
              reporterName: report.reporterName,
              showStatus: true,
              elapsedTime: DateTime.now().difference(report.createdAt),
              onTap: () {
                context.push('/supervisor/review/${report.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
