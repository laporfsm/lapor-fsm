import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';

/// PJ Gedung theme color
const Color pjGedungColor = Color(0xFF059669); // Emerald green

class PJGedungDashboardPage extends StatefulWidget {
  const PJGedungDashboardPage({super.key});

  @override
  State<PJGedungDashboardPage> createState() => _PJGedungDashboardPageState();
}

class _PJGedungDashboardPageState extends State<PJGedungDashboardPage> {
  bool _isLoading = true;
  Timer? _refreshTimer;

  Map<String, int> _dashboardStats = {
    'todayReports': 0,
    'weekReports': 0,
    'monthReports': 0,
    'pending': 0,
    'verified': 0,
    'rejected': 0,
  };

  List<Report> _pendingReports = [];
  List<Report> _emergencyReports = [];
  List<Report> _verifiedReports = [];

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

        final results = await Future.wait([
          reportService.getPJDashboardStats(staffId),
          reportService.getStaffReports(role: 'pj', status: 'pending'),
          reportService.getStaffReports(role: 'pj', isEmergency: true),
          reportService.getStaffReports(role: 'pj', status: 'terverifikasi'),
        ]);

        if (mounted) {
          setState(() {
            if (results[0] != null) {
              _dashboardStats = Map<String, int>.from(results[0] as Map);
            }
            _pendingReports = (results[1] as List)
                .map((json) => Report.fromJson(json))
                .toList();
            _emergencyReports = (results[2] as List)
                .map((json) => Report.fromJson(json))
                .toList();
            _verifiedReports = (results[3] as List)
                .map((json) => Report.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading PJ dashboard data: $e');
    } finally {
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
              backgroundColor: pjGedungColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.network(
                      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=1000',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: pjGedungColor),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            pjGedungColor.withValues(alpha: 0.85),
                            pjGedungColor.withValues(alpha: 0.95),
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
                                  LucideIcons.building2,
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
                                    'Dashboard PJ Gedung',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Gap(2),
                                  Text(
                                    'Verifikasi & Monitoring Gedung A',
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
                      // Emergency Alert Banner (view-only awareness)
                      if (_emergencyReports.isNotEmpty) ...[
                        _buildEmergencyAlert(context),
                        const Gap(16),
                      ],
                      _buildPeriodStats(context),
                      const Gap(16),
                      // Stats Button
                      GestureDetector(
                        onTap: () => context.push('/pj-gedung/statistics'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pjGedungColor.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: pjGedungColor.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.barChart2,
                                    color: pjGedungColor,
                                    size: 20,
                                  ),
                                  Gap(8),
                                  Text(
                                    'Lihat Statistik Lengkap',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pjGedungColor,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: pjGedungColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(16),
                      _buildStatusStats(context),
                      const Gap(16),
                      _buildQuickActions(context),
                      const Gap(24),
                      _buildSectionHeader(
                        context,
                        'Perlu Verifikasi',
                        'Lihat Semua',
                        () => context.push('/pj-gedung/reports?status=pending'),
                        count: _stats['pending'],
                        badgeColor: pjGedungColor,
                      ),
                      const Gap(12),
                      _buildPendingList(context),
                      const Gap(24),
                      _buildSectionHeader(
                        context,
                        'Menunggu Supervisor',
                        'Lihat Semua',
                        () => context.push(
                          '/pj-gedung/reports?status=terverifikasi',
                        ),
                        count: _stats['verified'],
                        badgeColor: pjGedungColor,
                      ),
                      const Gap(12),
                      _buildVerifiedList(context),
                      const Gap(32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Emergency Alert Banner - Click to view list
  Widget _buildEmergencyAlert(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pj-gedung/reports?emergency=true'),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Darurat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_emergencyReports.length} laporan di gedung Anda (View Only)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStats(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String period,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/pj-gedung/reports?period=$period'),
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

  Widget _buildStatusStats(BuildContext context) {
    return Container(
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
                _stats['pending']!,
                Colors.amber,
                'pending',
              ),
              const Gap(8),
              _buildStatusBadge(
                context,
                'Terverifikasi',
                _stats['verified']!,
                Colors.green,
                'terverifikasi',
              ),
              const Gap(8),
              _buildStatusBadge(
                context,
                'Ditolak',
                _stats['rejected']!,
                Colors.red,
                'ditolak',
              ),
            ],
          ),
        ],
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
      child: GestureDetector(
        onTap: () => context.push('/pj-gedung/reports?status=$status'),
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

  Widget _buildQuickActions(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pj-gedung/reports'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pjGedungColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.layoutList, color: pjGedungColor),
            const Gap(10),
            const Text(
              'Semua Laporan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: pjGedungColor,
                fontSize: 15,
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
    Color? badgeColor,
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
                  color: badgeColor ?? AppTheme.secondaryColor,
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

  Widget _buildPendingList(BuildContext context) {
    if (_pendingReports.isEmpty) {
      return _buildEmptyState('Tidak ada laporan menunggu verifikasi');
    }

    return Column(
      children: _pendingReports.take(3).map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UniversalReportCard(
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
            onTap: () => context.push(
              '/pj-gedung/report/${report.id}',
              extra: {'report': report},
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerifiedList(BuildContext context) {
    if (_verifiedReports.isEmpty) {
      return _buildEmptyState('Belum ada laporan terverifikasi');
    }

    return Column(
      children: _verifiedReports.take(3).map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UniversalReportCard(
            id: report.id,
            title: report.title,
            location: report.building,
            locationDetail: report.locationDetail,
            category: report.category,
            status: report.status,
            elapsedTime: DateTime.now().difference(report.createdAt),
            showStatus: true,
            compact: true,
            onTap: () => context.push(
              '/pj-gedung/report/${report.id}',
              extra: {'report': report},
            ),
          ),
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
