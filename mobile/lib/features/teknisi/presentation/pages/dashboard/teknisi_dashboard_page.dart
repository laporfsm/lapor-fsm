import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:mobile/core/widgets/stat_grid_card.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';

import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/teknisi/presentation/providers/teknisi_dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard page for Teknisi
class TeknisiDashboardPage extends ConsumerStatefulWidget {
  const TeknisiDashboardPage({super.key});

  @override
  ConsumerState<TeknisiDashboardPage> createState() =>
      _TeknisiDashboardPageState();
}

class _TeknisiDashboardPageState extends ConsumerState<TeknisiDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(teknisiDashboardProvider);
    final stats = dashboardState.stats;
    final isLoading = dashboardState.isLoading;
    final currentStaffId = dashboardState.currentStaffId;
    final readyReports = dashboardState.readyReports;
    final activeReports = dashboardState.activeReports;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: const NotificationFab(
        backgroundColor: AppTheme.teknisiColor,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: innerBoxIsScrolled
                  ? const Text(
                      'Dashboard Teknisi',
                      style: TextStyle(
                        color: Colors.black,
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
                    // 1. Base Gradient Background (Amber for Teknisi)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.secondaryColor,
                            AppTheme.secondaryColor.withRed(255).withGreen(180),
                          ],
                        ),
                      ),
                    ),
                    // 2. Decorative Slanted Slants (Pattern)
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
                    Positioned(
                      top: 40,
                      right: -30,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 400,
                          height: 60,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    // 3. Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(76),
                                    width: 1.5,
                                  ),
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(teknisiDashboardProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emergency Alert
                      _buildEmergencyAlert(context, stats),

                      // Period Stats
                      const Gap(16),
                      PeriodStatsRow(
                        todayCount: stats['todayReports'] ?? 0,
                        weekCount: stats['weekReports'] ?? 0,
                        monthCount: stats['monthReports'] ?? 0,
                        onTap: (period) => context.push(
                          Uri(
                            path: '/teknisi/all-reports',
                            queryParameters: {
                              'period': period,
                              if (currentStaffId != null)
                                'assignedTo': currentStaffId.toString(),
                            },
                          ).toString(),
                        ),
                      ),

                      // Status Stats
                      const Gap(12),
                      StatusStatsRow(
                        diprosesCount: stats['diproses'] ?? 0,
                        penangananCount: stats['penanganan'] ?? 0,
                        onHoldCount: stats['onHold'] ?? 0,
                        selesaiCount: stats['selesai'] ?? 0,
                        recalledCount: stats['recalled'] ?? 0,
                        onTap: (status) => context.push(
                          Uri(
                            path: '/teknisi/all-reports',
                            queryParameters: {
                              'status': status,
                              if (currentStaffId != null)
                                'assignedTo': currentStaffId.toString(),
                            },
                          ).toString(),
                        ),
                      ),

                      // Quick Actions (Semua Laporan)
                      const Gap(16),
                      _buildQuickActions(context),

                      // Ready to Start Section
                      const Gap(24),
                      _buildReadyToStartSection(context, stats, readyReports),

                      // Active Reports Section
                      const Gap(24),
                      _buildActiveWorkSection(context, stats, activeReports),

                      const Gap(32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmergencyAlert(BuildContext context, Map<String, int> stats) {
    final emergencyCount = stats['emergency'] ?? 0;
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
    return BouncingButton(
      // Clear filters for "Semua Laporan" to show public feed
      onTap: () => context.push('/teknisi/all-reports'),
      child: Container(
        width: double.infinity,
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

  Widget _buildReadyToStartSection(
    BuildContext context,
    Map<String, int> stats,
    List<Report> readyReports,
  ) {
    // Count is sum of Diproses (Global) + Recalled (Personal)
    final count = (stats['diproses'] ?? 0) + (stats['recalled'] ?? 0);

    return Column(
      children: [
        _buildSectionHeader(
          context,
          'Siap Dimulai',
          'Lihat Semua',
          () => context.push('/teknisi/siap-dimulai'),
          count: count,
        ),
        const Gap(12),
        if (readyReports.isEmpty)
          _buildEmptyState('Belum ada laporan yang perlu ditangani')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readyReports.length > 3 ? 3 : readyReports.length,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) {
              final report = readyReports[index];
              return UniversalReportCard(
                id: report.id,
                title: report.title,
                location: report.location,
                locationDetail: report.locationDetail,
                category: report.category,
                status: report.status,
                isEmergency: report.isEmergency,
                elapsedTime: DateTime.now().difference(report.createdAt),
                reporterName: report.reporterName,
                assignedTo: report.assignedTo,
                handledBy: report.handledBy,
                showStatus: true,
                showTimer: true,
                compact: false, // Set to false to show extra info
                onTap: () => context.push('/teknisi/report/${report.id}'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActiveWorkSection(
    BuildContext context,
    Map<String, int> stats,
    List<Report> activeReports,
  ) {
    final count = stats['penanganan'] ?? 0;

    return Column(
      children: [
        _buildSectionHeader(context, 'Sedang Dikerjakan', 'Lihat Semua', () {
          context.push('/teknisi/sedang-dikerjakan');
        }, count: count),
        const Gap(12),
        if (activeReports.isEmpty)
          _buildEmptyState('Tidak ada laporan yang sedang dikerjakan')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeReports.length > 3 ? 3 : activeReports.length,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) {
              final report = activeReports[index];
              return UniversalReportCard(
                id: report.id,
                title: report.title,
                location: report.location,
                locationDetail: report.locationDetail,
                category: report.category,
                status: report.status,
                isEmergency: report.isEmergency,
                elapsedTime: DateTime.now().difference(report.createdAt),
                reporterName: report.reporterName,
                assignedTo: report.assignedTo,
                handledBy: report.handledBy,
                showStatus: true,
                showTimer: true,
                compact: false, // Set to false to show extra info
                onTap: () =>
                    context.push('/teknisi/report/${report.id}?from=dashboard'),
              );
            },
          ),
      ],
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
