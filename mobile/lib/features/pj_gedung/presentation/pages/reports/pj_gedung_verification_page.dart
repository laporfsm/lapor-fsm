import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/services/report_service.dart';

class PJGedungVerificationPage extends StatefulWidget {
  const PJGedungVerificationPage({super.key});

  @override
  State<PJGedungVerificationPage> createState() =>
      _PJGedungVerificationPageState();
}

class _PJGedungVerificationPageState extends State<PJGedungVerificationPage> {
  bool _isLoading = true;
  List<Report> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch only pending reports
      final result = await reportService.getStaffReports(
        role: 'pj',
        status: 'pending',
      );

      if (mounted) {
        setState(() {
          final data = result['data'] as List<dynamic>;
          _reports = data.map((json) => Report.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Perlu Verifikasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.pjGedungColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return UniversalReportCard(
                    id: report.id,
                    title: report.title,
                    location: report.location,
                    locationDetail: report.locationDetail,
                    category: report.category,
                    status: report.status,
                    isEmergency: report.isEmergency,
                    elapsedTime: DateTime.now().difference(report.createdAt),
                    showStatus: true,
                    showTimer: true,
                    onTap: () => context
                        .push(
                          '/pj-gedung/report/${report.id}',
                          extra: {'report': report},
                        )
                        .then((_) => _loadData()), // Refresh on return
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Semua Aman!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada laporan yang perlu diverifikasi saat ini.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
