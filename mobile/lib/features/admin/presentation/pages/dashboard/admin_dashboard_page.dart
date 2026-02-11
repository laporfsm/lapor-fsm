import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  Map<String, dynamic>? _stats;
  List<Report> _recentReports = [];
  List<Map<String, dynamic>> _systemLogs = [];
  bool _isLoading = true;
  String _userName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStats(), _loadUserProfile(), _loadLogs()]);
  }

  Future<void> _loadLogs() async {
    final logs = await adminService.getLogs();
    if (mounted) {
      setState(() {
        _systemLogs = logs;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final user = await authService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _userName = user['name'] ?? 'Admin';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final responses = await Future.wait([
        apiService.dio.get('/admin/dashboard'),
        apiService.dio.get(
          '/reports',
          queryParameters: {'limit': 5, 'sort': 'desc'},
        ),
      ]);

      final dashboardRes = responses[0];
      final recentRes = responses[1];

      if (mounted) {
        setState(() {
          if (dashboardRes.data['status'] == 'success') {
            _stats = dashboardRes.data['data'];
          }
          if (recentRes.data['status'] == 'success') {
            final data = List<Map<String, dynamic>>.from(
              recentRes.data['data'],
            );
            _recentReports = data.map((json) => Report.fromJson(json)).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: const NotificationFab(
        backgroundColor: AppTheme.adminColor,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.adminColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.adminColor,
                            AppTheme.adminColor.withRed(
                              ((AppTheme.adminColor.r * 255).round() + 30)
                                  .clamp(0, 255),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Decorative Circles (Pattern)
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
                    // Gradient Overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
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
                                  LucideIcons.shieldCheck,
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
                                    Text(
                                      'Halo, $_userName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Gap(4),
                                    Text(
                                      'Administrator',
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmergencyAlert(context),
                      if (_stats?['totalEmergency'] != null &&
                          _stats!['totalEmergency'] > 0)
                        const Gap(16),

                      // Statistics Section
                      _buildStatsSection(context),
                      const Gap(24),

                      // Quick Actions
                      const Text(
                        'Akses Cepat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickActionButton(
                            label: 'Verifikasi User',
                            icon: LucideIcons.userCheck,
                            color: Colors.orange,
                            onTap: () => context.go('/admin/users?tab=1'),
                          ),
                          _QuickActionButton(
                            label: 'Kelola Staff',
                            icon: LucideIcons.users,
                            color: Colors.green,
                            onTap: () => context.go('/admin/users?tab=2'),
                          ),
                          _QuickActionButton(
                            label: 'Semua Laporan',
                            icon: LucideIcons.fileText,
                            color: Colors.blue,
                            onTap: () => context.go('/admin/reports'),
                          ),
                        ],
                      ),
                      const Gap(24),

                      // Recent Reports
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Laporan Terkini',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/admin/reports'),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const Gap(12),

                      if (_recentReports.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.fileText,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const Gap(8),
                                Text(
                                  'Belum ada laporan',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentReports.length > 3
                              ? 3
                              : _recentReports.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, index) {
                            final report = _recentReports[index];
                            return UniversalReportCard(
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
                                context.push('/admin/reports/${report.id}');
                              },
                            );
                          },
                        ),
                      const Gap(24),

                      // System Logs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Log Sistem',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/admin/logs'),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const Gap(12),
                      _buildSystemLogsSection(),

                      const Gap(80), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Ringkas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Gap(16),

        // Stats Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatCard(
                label: 'Total Laporan',
                value: _stats?['totalReports']?.toString() ?? '0',
                icon: LucideIcons.fileText,
                color: Colors.blue,
              ),
              _StatCard(
                label: 'Total User',
                value: _stats?['totalUsers']?.toString() ?? '0',
                icon: LucideIcons.users,
                color: Colors.purple,
              ),
              _StatCard(
                label: 'Rata-rata Penanganan',
                value: '${_stats?['avgHandlingMinutes'] ?? 0}m',
                icon: LucideIcons.clock,
                color: Colors.orange,
              ),
              _StatCard(
                label: 'Status Server',
                value: 'Online',
                icon: LucideIcons.server,
                color: Colors.green,
              ),
            ],
          ),
        ),
        const Gap(12),

        // Full Stats Link with BouncingButton
        BouncingButton(
          onTap: () => context.push('/admin/statistics'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.adminColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.adminColor.withValues(alpha: 0.05),
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
                      color: AppTheme.adminColor,
                      size: 20,
                    ),
                    const Gap(8),
                    Text(
                      'Lihat Statistik Lengkap',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.adminColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppTheme.adminColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemLogsSection() {
    if (_systemLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.activity, size: 48, color: Colors.grey.shade300),
              const Gap(8),
              Text(
                'Belum ada log sistem',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _systemLogs.length > 3 ? 3 : _systemLogs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = _systemLogs[index];
          IconData icon = LucideIcons.activity;
          Color color = Colors.grey;

          final action = log['action']?.toString().toLowerCase() ?? '';
          if (action.contains('created') || action.contains('create')) {
            icon = LucideIcons.filePlus;
            color = Colors.blue;
          } else if (action.contains('verify')) {
            icon = LucideIcons.userCheck;
            color = Colors.green;
          } else if (action.contains('delete')) {
            icon = LucideIcons.trash2;
            color = Colors.red;
          } else if (action.contains('update')) {
            icon = LucideIcons.edit;
            color = Colors.orange;
          }

          return _LogListTile(
            title: '${log['user'] ?? 'System'}',
            subtitle: log['action'] ?? 'Unknown action',
            time: _formatTimeAgo(log['time']),
            icon: icon,
            color: color,
          );
        },
      ),
    );
  }

  String _formatTimeAgo(dynamic time) {
    if (time == null) return '-';
    final DateTime dateTime = time is DateTime
        ? time
        : DateTime.parse(time.toString());
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }

  Widget _buildEmergencyAlert(BuildContext context) {
    final emergencyCount = _stats?['totalEmergency'] ?? 0;

    if (emergencyCount == 0) return const SizedBox.shrink();

    return BouncingButton(
      onTap: () {
        // Navigate to reports filtered by emergency
        context.go('/admin/reports');
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
                    '$emergencyCount laporan darurat perlu perhatian!',
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LogListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _LogListTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Gap(8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
