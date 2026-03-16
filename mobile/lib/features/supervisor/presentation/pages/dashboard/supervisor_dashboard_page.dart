import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_activity_log_page.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/stat_grid_card.dart';

import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_reports_provider.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_navigation_provider.dart';

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
  List<Map<String, dynamic>> _activityLogs = [];

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
          reportService.getGlobalLogs(limit: 5), // Global Activity Logs
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

            // Activity Logs
            try {
              _activityLogs = List<Map<String, dynamic>>.from(results[4] as List);
            } catch (e) {
              debugPrint('[DASHBOARD] Error converting activity logs: $e');
              _activityLogs = [];
            }

            debugPrint(
              '[DASHBOARD] Final counts - Non-Gedung: ${_nonGedungReports.length}, Activity: ${_activityLogs.length}',
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
              backgroundColor: AppTheme.supervisorColor,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: innerBoxIsScrolled
                  ? const Text(
                      'Dashboard Supervisor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base Gradient Background (Indigo for Supervisor)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.supervisorColor,
                            AppTheme.supervisorColor
                                .withRed(50)
                                .withBlue(150), // Variation
                          ],
                        ),
                      ),
                    ),
                    // 2. Decorative Slants (Pattern)
                    Positioned(
                      top: -10,
                      left: -20,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 500,
                          height: 80,
                          color: Colors.white.withAlpha(25),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 70,
                      left: -100,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 500,
                          height: 45,
                          color: Colors.white.withAlpha(18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: -50,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 300,
                          height: 40,
                          color: Colors.white.withAlpha(25),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: -40,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 200,
                          height: 20,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Center(
                        child: Opacity(
                          opacity: 1.0 - (innerBoxIsScrolled ? 1.0 : 0.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    LucideIcons.clipboardCheck,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const Gap(14),
                                const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard Supervisor',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Gap(2),
                                    Text(
                                      'Monitoring & Evaluasi Kinerja',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                        () => _navigateToStatus(context, 'terverifikasi'),
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
                        () => _navigateToStatus(context, 'selesai'),
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
                                  const SupervisorActivityLogPage(
                                isEmbedded: false,
                              ),
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
      onTap: () {
        // Since "Active" page already shows emergency status or filters, 
        // we set the emergency filter on the Active Reports provider
        ref.read(supervisorReportsProvider('pending,terverifikasi,diproses,penanganan,onHold,selesai,recalled').notifier)
           .setFilters(isEmergency: true);
        ref.read(supervisorNavigationProvider.notifier).setBottomNavIndex(1); // Go to Active Reports
      },
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
    // Map status to tab and filter group
    int tabIndex = 1; // Default to Active
    String groupStatus = 'pending,terverifikasi,verifikasi,diproses,penanganan,onHold,selesai,recalled';
    
    if (status == 'approved' || status == 'ditolak') {
      tabIndex = 2; // History
      groupStatus = 'approved,ditolak';
    }

    // 1. Set the status filter in the corresponding provider
    ref.read(supervisorReportsProvider(groupStatus).notifier).setSelectedStatus(status);
    
    // 2. Switch the bottom navigation tab
    ref.read(supervisorNavigationProvider.notifier).setBottomNavIndex(tabIndex);
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
    if (_activityLogs.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Belum ada aktivitas terbaru'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activityLogs.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final log = _activityLogs[index];
          
          // Map backend action to human readable string
          String actionText = log['action'] ?? '';
          if (actionText == 'verified') actionText = 'memverifikasi';
          if (actionText == 'handling') actionText = 'menugaskan';
          if (actionText == 'accepted') actionText = 'menerima tugas';
          if (actionText == 'completed') actionText = 'menyelesaikan';
          if (actionText == 'approved') actionText = 'menyetujui';
          if (actionText == 'rejected') actionText = 'menolak';
          if (actionText == 'created') actionText = 'membuat';
          if (actionText == 'recalled') actionText = 'menarik kembali';
          if (actionText == 'paused') actionText = 'menunda';
          if (actionText == 'resumed') actionText = 'melanjutkan';
          
          // Format time
          String timeStr = 'Baru saja';
          if (log['timestamp'] != null) {
            try {
              final date = DateTime.parse(log['timestamp']);
              final diff = DateTime.now().difference(date);
              if (diff.inDays > 0) {
                timeStr = '${diff.inDays} hari lalu';
              } else if (diff.inHours > 0) {
                timeStr = '${diff.inHours} jam lalu';
              } else if (diff.inMinutes > 0) {
                timeStr = '${diff.inMinutes} menit lalu';
              }
            } catch (e) {
              timeStr = '-';
            }
          }

          return _buildLogItem(
            log['actorName'] ?? 'Sistem',
            actionText,
            log['reportTitle'] ?? 'laporan',
            timeStr,
          );
        },
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
