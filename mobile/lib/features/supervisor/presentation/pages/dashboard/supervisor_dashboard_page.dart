import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_technician_main_page.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/stat_grid_card.dart';

import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard page for Supervisor (tab 0 in shell)
/// This page contains the main dashboard content WITHOUT bottom navigation bar
class SupervisorDashboardPage extends ConsumerStatefulWidget {
  const SupervisorDashboardPage({super.key});

  @override
  ConsumerState<SupervisorDashboardPage> createState() =>
      _SupervisorDashboardPageState();
}

class _SupervisorDashboardPageState
    extends ConsumerState<SupervisorDashboardPage> {
  bool _isLoading = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _dashboardStats = {
    'pending': 0,
    'terverifikasi': 0,
    'diproses': 0,
    'penanganan': 0,
    'onHold': 0,
    'selesai': 0,
    'recalled': 0,
    'approved': 0,
    'ditolak': 0,
    'emergency': 0,
    'nonGedungPending': 0,
    'todayReports': 0,
    'weekReports': 0,
    'monthReports': 0,
  };

  List<Report> _nonGedungReports = [];
  List<Report> _readyToProcessReports = [];
  List<Report> _pendingReviewReports = [];

  Map<String, dynamic> get _stats => _dashboardStats;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final user = await authService.getCurrentUser();
      debugPrint('[DASHBOARD] User: $user');
      if (user != null) {
        final staffId = user['id'];
        debugPrint('[DASHBOARD] StaffId: $staffId');

        // Fetch stats and lists
        final results = await Future.wait([
          reportService.getSupervisorDashboardStats(staffId),
          reportService.getNonGedungReports(limit: 20), // Non-gedung pending
          reportService.getStaffReports(
            role: 'supervisor',
            status: 'terverifikasi', // Only terverifikasi for "Siap Diproses"
          ),
          reportService.getStaffReports(role: 'supervisor', status: 'selesai'),
        ]);

        debugPrint('[DASHBOARD] Results received');

        if (mounted) {
          setState(() {
            if (results[0] != null) {
              final rawStats = results[0] as Map<String, dynamic>;
              _dashboardStats = {
                'pending': rawStats['pending'] ?? 0,
                'terverifikasi': rawStats['terverifikasi'] ?? 0,
                'diproses': rawStats['diproses'] ?? 0,
                'penanganan': rawStats['penanganan'] ?? 0,
                'onHold': rawStats['onHold'] ?? 0,
                'selesai': rawStats['selesai'] ?? 0,
                'recalled': rawStats['recalled'] ?? 0,
                'approved': rawStats['approved'] ?? 0,
                'ditolak': rawStats['ditolak'] ?? 0,
                'emergency': rawStats['emergency'] ?? 0,
                'nonGedungPending': rawStats['nonGedungPending'] ?? 0,
                'todayReports': rawStats['todayReports'] ?? 0,
                'weekReports': rawStats['weekReports'] ?? 0,
                'monthReports': rawStats['monthReports'] ?? 0,
              };
            }

            // Non-Gedung Reports
            try {
              final response = results[1] as Map<String, dynamic>;
              final List<Map<String, dynamic>> data =
                  List<Map<String, dynamic>>.from(response['data'] ?? []);
              _nonGedungReports = data
                  .map((json) => Report.fromJson(json))
                  .toList();
            } catch (e) {
              debugPrint('[DASHBOARD] Error converting non-gedung reports: $e');
              _nonGedungReports = [];
            }

            // Ready to Process (Terverifikasi only)
            try {
              final response = results[2] as Map<String, dynamic>;
              final List<Map<String, dynamic>> data =
                  List<Map<String, dynamic>>.from(response['data'] ?? []);
              _readyToProcessReports = data
                  .map((json) => Report.fromJson(json))
                  .toList();
            } catch (e) {
              debugPrint('[DASHBOARD] Error converting ready reports: $e');
              _readyToProcessReports = [];
            }

            // Pending Review (Selesai)
            try {
              final response = results[3] as Map<String, dynamic>;
              final List<Map<String, dynamic>> data =
                  List<Map<String, dynamic>>.from(response['data'] ?? []);
              _pendingReviewReports = data
                  .map((json) => Report.fromJson(json))
                  .toList();
            } catch (e) {
              debugPrint('[DASHBOARD] Error converting review reports: $e');
              _pendingReviewReports = [];
            }

            debugPrint(
              '[DASHBOARD] Final counts - Non-Gedung: ${_nonGedungReports.length}, Ready: ${_readyToProcessReports.length}, Review: ${_pendingReviewReports.length}',
            );
            _isLoading = false;
          });
        }
      } else {
        debugPrint('[DASHBOARD] User is null!');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading Supervisor dashboard data: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: const NotificationFab(
        backgroundColor: AppTheme.supervisorColor,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: supervisorColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.supervisorColor,
                            AppTheme.supervisorColor.withRed(
                              50,
                            ), // Slightly different shade
                          ],
                        ),
                      ),
                    ),
                    // 2. Decorative Circles (Pattern)
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Gradient Overlay for text readability (optional, but keeps style)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(
                              alpha: 0.2,
                            ), // Subtle shadow at bottom
                          ],
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.clipboardCheck,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Dashboard Supervisor',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      'Monitoring & Evaluasi Kinerja',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmergencyAlert(context),
                      const Gap(16),
                      _buildStatsSection(context),
                      const Gap(24),

                      // Section: Non-Gedung (Pending reports from locations without PJ)
                      _buildSectionHeader(
                        context,
                        'Non-Gedung',
                        'Lihat Semua',
                        () => context.push('/supervisor/non-gedung'),
                        count: _stats['nonGedungPending'] ?? 0,
                      ),
                      const Gap(12),
                      _buildNonGedungList(context),
                      const Gap(24),

                      // Section: Siap Diproses (Terverifikasi only)
                      _buildSectionHeader(
                        context,
                        'Siap Diproses',
                        'Lihat Semua',
                        () => context.push(
                          Uri(
                            path: '/supervisor/reports/filter',
                            queryParameters: {'status': 'terverifikasi'},
                          ).toString(),
                        ),
                        count: _stats['terverifikasi'] ?? 0,
                      ),
                      const Gap(12),
                      _buildReadyToProcessList(context),
                      const Gap(24),

                      // Section: Menunggu Approval (Selesai)
                      _buildSectionHeader(
                        context,
                        'Menunggu Approval',
                        'Lihat Semua',
                        () => context.push(
                          Uri(
                            path: '/supervisor/reports/filter',
                            queryParameters: {'status': 'selesai'},
                          ).toString(),
                        ),
                        count: _stats['selesai'] ?? 0,
                      ),
                      const Gap(12),
                      _buildApprovalList(context),
                      const Gap(24),

                      // Section: Aktivitas & Log (no counter)
                      _buildSectionHeader(
                        context,
                        "Aktivitas & Log",
                        "Lihat Semua",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SupervisorTechnicianMainPage(),
                            ),
                          );
                        },
                      ),
                      const Gap(12),
                      _buildActivityLogStub(context),
                      const Gap(24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Emergency alert banner - clickable
  Widget _buildEmergencyAlert(BuildContext context) {
    final emergencyCount = _stats['emergency'] ?? 0;
    if (emergencyCount == 0) return const SizedBox.shrink();

    return BouncingButton(
      onTap: () => context.push(
        Uri(
          path: '/supervisor/reports/filter',
          queryParameters: {'emergency': 'true'},
        ).toString(),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade800],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Darurat!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$emergencyCount laporan darurat perlu perhatian segera',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      children: [
        // Period Stats (Hari Ini, Minggu Ini, Bulan Ini)
        PeriodStatsRow(
          todayCount: _stats['todayReports'] ?? 0,
          weekCount: _stats['weekReports'] ?? 0,
          monthCount: _stats['monthReports'] ?? 0,
          onTap: (period) => context.push(
            Uri(
              path: '/supervisor/reports/filter',
              queryParameters: {'period': period},
            ).toString(),
          ),
        ),
        const Gap(12),

        // Clickable Stats Header
        BouncingButton(
          onTap: () => context.push('/supervisor/statistics'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.barChart2,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const Gap(8),
                    const Text(
                      'Lihat Statistik Lengkap',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        const Gap(12),

        // Status Stats Grid (9 statuses in 3x3)
        SupervisorStatusStatsRow(
          pendingCount: _stats['pending'] ?? 0,
          terverifikasiCount: _stats['terverifikasi'] ?? 0,
          diprosesCount: _stats['diproses'] ?? 0,
          penangananCount: _stats['penanganan'] ?? 0,
          onHoldCount: _stats['onHold'] ?? 0,
          selesaiCount: _stats['selesai'] ?? 0,
          recalledCount: _stats['recalled'] ?? 0,
          approvedCount: _stats['approved'] ?? 0,
          ditolakCount: _stats['ditolak'] ?? 0,
          onTap: (status) => _navigateToStatus(context, status),
        ),
      ],
    );
  }

  void _navigateToStatus(BuildContext context, String status) {
    context.push(
      Uri(
        path: '/supervisor/reports/filter',
        queryParameters: {'status': status},
      ).toString(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String actionText,
    VoidCallback onTap, {
    int? count,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (count != null && count > 0) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.supervisorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        TextButton(onPressed: onTap, child: Text(actionText)),
      ],
    );
  }

  Widget _buildNonGedungList(BuildContext context) {
    if (_nonGedungReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.mapPin, size: 48, color: Colors.grey.shade300),
              const Gap(8),
              Text(
                'Tidak ada laporan non-gedung pending',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    // Show only first 3 reports
    final displayReports = _nonGedungReports.take(3).toList();

    return Column(
      children: displayReports.map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
            onTap: () {
              context.push(
                '/supervisor/review/${report.id}',
                extra: {'status': report.status},
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApprovalList(BuildContext context) {
    if (_pendingReviewReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.checkCircle2,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const Gap(8),
              Text(
                'Tidak ada laporan menunggu approval',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    // Show max 3 reports in dashboard preview
    final displayReports = _pendingReviewReports.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayReports.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final r = displayReports[index];
        return UniversalReportCard(
          id: r.id,
          title: r.title,
          location: r.location,
          locationDetail: r.locationDetail,
          category: r.category,
          status: r.status,
          isEmergency: r.isEmergency,
          assignedTo: r.assignedTo,
          handledBy: r.handledBy,
          showStatus: true,
          showTimer: false,
          onTap: () => context.push(
            '/supervisor/review/${r.id}',
            extra: {'status': r.status},
          ),
        );
      },
    );
  }

  // MOCK: Ready to Process (Verified by PJ or Direct Non-Location)
  Widget _buildReadyToProcessList(BuildContext context) {
    if (_readyToProcessReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.checkCircle2,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const Gap(8),
              Text(
                'Tidak ada laporan siap diproses',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    // Show max 3 reports in dashboard preview
    final displayReports = _readyToProcessReports.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayReports.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final r = displayReports[index];
        return UniversalReportCard(
          id: r.id,
          title: r.title,
          location: r.location,
          locationDetail: r.locationDetail,
          category: r.category,
          status: r.status,
          isEmergency: r.isEmergency,
          elapsedTime: DateTime.now().difference(r.createdAt),
          showStatus: true,
          onTap: () => context.push(
            '/supervisor/review/${r.id}',
            extra: {'status': r.status},
          ),
        );
      },
    );
  }

  Widget _buildActivityLogStub(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildLogItem(
            'Budi Teknisi',
            'memulai penanganan',
            'AC Lab',
            '5 menit lalu',
          ),
          const Divider(),
          _buildLogItem(
            'PJ Gedung A',
            'memverifikasi laporan',
            'Lampu Koridor',
            '15 menit lalu',
          ),
          const Divider(),
          _buildLogItem(
            'Andi Teknisi',
            'menyelesaikan laporan',
            'Pipa Toilet',
            '30 menit lalu',
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(
    String actor,
    String action,
    String target,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(LucideIcons.user, size: 12, color: Colors.grey),
          ),
          const Gap(12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: actor,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $action '),
                  TextSpan(
                    text: target,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
