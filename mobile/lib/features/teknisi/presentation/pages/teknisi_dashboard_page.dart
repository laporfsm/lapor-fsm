import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/widgets/stat_grid_card.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'dart:async';
import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';

/// Dashboard page for Teknisi
class TeknisiDashboardPage extends StatefulWidget {
  const TeknisiDashboardPage({super.key});

  @override
  State<TeknisiDashboardPage> createState() => _TeknisiDashboardPageState();
}

class _TeknisiDashboardPageState extends State<TeknisiDashboardPage> {
  bool _isLoading = true;
  Timer? _refreshTimer;

  Map<String, int> _dashboardStats = {
    'diproses': 0,
    'penanganan': 0,
    'onHold': 0,
    'selesai': 0,
    'todayReports': 0,
    'weekReports': 0,
    'monthReports': 0,
    'emergency': 0,
  };

  List<Report> _readyReports = [];
  List<Report> _activeReports = [];

  Map<String, int> get _stats => _dashboardStats;

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
          reportService.getTechnicianDashboardStats(staffId),
          reportService.getStaffReports(role: 'technician', status: 'diproses'),
          reportService.getStaffReports(role: 'technician', status: 'penanganan'),
        ]);

        if (mounted) {
          setState(() {
            if (results[0] != null) {
              _dashboardStats = Map<String, int>.from(results[0] as Map);
            }
            _readyReports = (results[1] as List).map((json) => Report.fromJson(json)).toList();
            _activeReports = (results[2] as List).map((json) => Report.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading Technician dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: const NotificationFab(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.secondaryColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.network(
                      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppTheme.secondaryColor);
                      },
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.secondaryColor.withValues(alpha: 0.85),
                            AppTheme.secondaryColor.withValues(alpha: 0.95),
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
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  LucideIcons.wrench,
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
                                    'Dashboard Teknisi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Gap(2),
                                  Text(
                                    'Kelola & Selesaikan Laporan',
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
                    // Emergency Alert
                    _buildEmergencyAlert(context),

                    // Quick Actions
                    const Gap(16),
                    _buildQuickActions(context),

                    // Period Stats
                    const Gap(16),
                    PeriodStatsRow(
                      todayCount: _stats['todayReports'] ?? 0,
                      weekCount: _stats['weekReports'] ?? 0,
                      monthCount: _stats['monthReports'] ?? 0,
                      onTap: (period) => context.push(
                        Uri(
                          path: '/teknisi/all-reports',
                          queryParameters: {'period': period},
                        ).toString(),
                      ),
                    ),

                    // Status Stats
                    const Gap(12),
                    StatusStatsRow(
                      diprosesCount: _stats['diproses'] ?? 0,
                      penangananCount: _stats['penanganan'] ?? 0,
                      onHoldCount: _stats['onHold'] ?? 0,
                      selesaiCount: _stats['selesai'] ?? 0,
                      onTap: (status) => context.push(
                        Uri(
                          path: '/teknisi/all-reports',
                          queryParameters: {'status': status},
                        ).toString(),
                      ),
                    ),

                    // Ready to Start Section
                    const Gap(24),
                    _buildSectionHeader(
                      context,
                      'Siap Dimulai',
                      'Lihat Semua',
                      () => context.push('/teknisi/all-reports?status=diproses'),
                      count: _stats['diproses'],
                    ),
                    const Gap(12),
                    _buildReadyReportsList(context),

                    // Active Reports Section
                    const Gap(24),
                    _buildSectionHeader(
                      context,
                      'Sedang Dikerjakan',
                      'Lihat Semua',
                      () => context.push('/teknisi/all-reports?status=penanganan'),
                      count: _stats['penanganan'],
                    ),
                    const Gap(12),
                    _buildActiveReportsList(context),

                    const Gap(32),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildEmergencyAlert(BuildContext context) {
    final emergencyCount = _stats['emergency'] ?? 0;
    if (emergencyCount == 0) return const SizedBox.shrink();

    return BouncingButton(
      onTap: () =>
          context.push('/teknisi/all-reports?status=diproses&emergency=true'),
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
                    '$emergencyCount laporan darurat perlu ditangani segera',
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BouncingButton(
            onTap: () => context.push('/teknisi/all-reports'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.layoutList, color: AppTheme.primaryColor),
                  const Gap(8),
                  const Text(
                    'Semua Laporan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: BouncingButton(
            onTap: () => context.push('/teknisi/search'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.search, color: Colors.grey.shade600),
                  const Gap(8),
                  Text(
                    'Cari Laporan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                  color: AppTheme.secondaryColor,
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

  Widget _buildReadyReportsList(BuildContext context) {
    if (_readyReports.isEmpty) {
      return _buildEmptyState('Tidak ada laporan menunggu');
    }

    return Column(
      children: _readyReports.map((report) {
        return UniversalReportCard(
          id: report.id,
          title: report.title,
          location: report.building,
          locationDetail: report.locationDetail,
          category: report.category,
          status: report.status,
          isEmergency: report.isEmergency,
          elapsedTime: DateTime.now().difference(report.createdAt),
          showStatus: true,
          showTimer: true,
          compact: true,
          onTap: () => context.push('/teknisi/report/${report.id}'),
        );
      }).toList(),
    );
  }

  Widget _buildActiveReportsList(BuildContext context) {
    if (_activeReports.isEmpty) {
      return _buildEmptyState('Tidak ada laporan aktif');
    }

    return Column(
      children: _activeReports.map((report) {
        return UniversalReportCard(
          id: report.id,
          title: report.title,
          location: report.building,
          locationDetail: report.locationDetail,
          category: report.category,
          status: report.status,
          elapsedTime: DateTime.now().difference(report.createdAt),
          showStatus: true,
          showTimer: true,
          compact: true,
          onTap: () => context.push('/teknisi/report/${report.id}'),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 40, color: Colors.grey.shade300),
            const Gap(8),
            Text(message, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
