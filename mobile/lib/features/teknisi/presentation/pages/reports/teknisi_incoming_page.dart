import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

/// Incoming reports page with tabs for Darurat and Umum
class TeknisiIncomingPage extends StatefulWidget {
  const TeknisiIncomingPage({super.key});

  @override
  State<TeknisiIncomingPage> createState() => _TeknisiIncomingPageState();
}

class _TeknisiIncomingPageState extends State<TeknisiIncomingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Report> _emergencyReports = [];
  List<Report> _regularReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final results = await Future.wait([
          // Fetch Emergency Dispatched
          reportService.getStaffReports(
            role: 'technician',
            status: 'diproses',
            isEmergency: true,
          ),
          // Fetch Regular Dispatched
          reportService.getStaffReports(
            role: 'technician',
            status: 'diproses',
            isEmergency: false,
            assignedTo: int.tryParse(
              user['id'].toString(),
            ), // Fetch assigned tasks
          ),
        ]);

        if (mounted) {
          setState(() {
            final emergencyData = List<Map<String, dynamic>>.from(
              results[0]['data'] ?? [],
            );
            _emergencyReports = emergencyData
                .map((json) => Report.fromJson(json))
                .toList();

            final regularData = List<Map<String, dynamic>>.from(
              results[1]['data'] ?? [],
            );
            _regularReports = regularData
                .map((json) => Report.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching incoming reports: $e');
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

    final emergencyCount = _emergencyReports.length;
    final regularCount = _regularReports.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Laporan Masuk',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.teknisiColor,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
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
                        color:
                            AppTheme.teknisiColor, // Changed from primaryColor
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
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
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
    );
  }
}
