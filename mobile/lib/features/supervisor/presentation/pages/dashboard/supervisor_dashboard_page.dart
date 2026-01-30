import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';

import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'dart:async';

/// Dashboard page for Supervisor (tab 0 in shell)
/// This page contains the main dashboard content WITHOUT bottom navigation bar
class SupervisorDashboardPage extends StatefulWidget {
  const SupervisorDashboardPage({super.key});

  @override
  State<SupervisorDashboardPage> createState() =>
      _SupervisorDashboardPageState();
}

class _SupervisorDashboardPageState extends State<SupervisorDashboardPage> {
  bool _isLoading = true;
  Timer? _refreshTimer;

  Map<String, int> _dashboardStats = {
    'pending': 0,
    'verifikasi': 0,
    'penanganan': 0,
    'selesai': 0,
    'emergency': 0,
    'todayReports': 0,
    'weekReports': 0,
    'monthReports': 0,
  };

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
      if (user != null) {
        final staffId = user['id'];

        // Fetch stats and lists
        final results = await Future.wait([
          reportService.getSupervisorDashboardStats(staffId),
          reportService.getStaffReports(
            role: 'supervisor',
            status: 'pending,terverifikasi',
          ),
          reportService.getStaffReports(role: 'supervisor', status: 'selesai'),
        ]);

        if (mounted) {
          setState(() {
            if (results[0] != null) {
              _dashboardStats = Map<String, int>.from(results[0] as Map);
            }
            _readyToProcessReports = (results[1] as List)
                .map((json) => Report.fromJson(json))
                .toList();
            _pendingReviewReports = (results[2] as List)
                .map((json) => Report.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading Supervisor dashboard data: $e');
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
                      // Section: Siap Diproses (Ready for Assignment)
                      // Includes: Verified Building Reports & Non-Building Reports
                      _buildSectionHeader(
                        context,
                        'Siap Diproses',
                        'Lihat Semua',
                        () => context.push(
                          Uri(
                            path: '/supervisor/reports/filter',
                            queryParameters: {
                              'status': 'pending,terverifikasi',
                            },
                          ).toString(),
                        ),
                        count: _readyToProcessReports.length,
                      ),
                      const Gap(12),
                      _buildReadyToProcessList(context),
                      const Gap(24),

                      // Section: Menunggu Approval (Completed by Technician)
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
                        count: _pendingReviewReports.length,
                      ),
                      const Gap(12),
                      _buildApprovalList(context),
                      const Gap(24),

                      _buildSectionHeader(
                        context,
                        "Aktivitas & Log",
                        "Lihat Semua",
                        () {
                          context.push('/supervisor/activity-log');
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
        Row(
          children: [
            _buildStatCard(
              context,
              'Hari Ini',
              _stats['todayReports'].toString(),
              LucideIcons.calendar,
              Colors.blue,
              'today',
            ),
            const Gap(12),
            _buildStatCard(
              context,
              'Minggu Ini',
              _stats['weekReports'].toString(),
              LucideIcons.calendarDays,
              Colors.green,
              'week',
            ),
            const Gap(12),
            _buildStatCard(
              context,
              'Bulan Ini',
              _stats['monthReports'].toString(),
              LucideIcons.calendarRange,
              Colors.orange,
              'month',
            ),
          ],
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Gap(12),
              Row(
                children: [
                  _buildStatusBadge(
                    context,
                    'Pending',
                    _stats['pending'],
                    Colors.grey,
                    'pending',
                  ),
                  const Gap(8),
                  _buildStatusBadge(
                    context,
                    'Verifikasi',
                    _stats['verifikasi'],
                    Colors.blue,
                    'verifikasi',
                  ),
                  const Gap(8),
                  _buildStatusBadge(
                    context,
                    'Penanganan',
                    _stats['penanganan'],
                    Colors.orange,
                    'penanganan',
                  ),
                  const Gap(8),
                  _buildStatusBadge(
                    context,
                    'Selesai',
                    _stats['selesai'],
                    Colors.green,
                    'selesai',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String filter,
  ) {
    return Expanded(
      child: BouncingButton(
        onTap: () => context.push(
          Uri(
            path: '/supervisor/reports/filter',
            queryParameters: {'period': filter},
          ).toString(),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const Gap(8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String label,
    int count,
    Color color,
    String status,
  ) {
    return Expanded(
      child: BouncingButton(
        onTap: () => context.push(
          Uri(
            path: '/supervisor/reports/filter',
            queryParameters: {'status': status},
          ).toString(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              Text(label, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
      ),
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingReviewReports.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final r = _pendingReviewReports[index];
        return UniversalReportCard(
          id: r.id,
          title: r.title,
          location: r.building,
          locationDetail: r.locationDetail,
          category: r.category,
          status: r.status,
          handledBy: r.handledBy?.join(', '),
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

  // MOCK: Ready to Process (Verified by PJ or Direct Non-Building)
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _readyToProcessReports.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final r = _readyToProcessReports[index];
        return UniversalReportCard(
          id: r.id,
          title: r.title,
          location: r.building,
          locationDetail: r.locationDetail,
          category: r.category,
          status: r.status,
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
