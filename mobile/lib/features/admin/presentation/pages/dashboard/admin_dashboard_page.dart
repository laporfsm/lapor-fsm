import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/admin/services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentReports = [];
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
        // Fetch emergency count manually
        apiService.dio.get(
          '/reports',
          queryParameters: {'isEmergency': true, 'limit': 1},
        ),
        // Fetch recent reports
        apiService.dio.get(
          '/reports',
          queryParameters: {
            'limit': 5,
            'sort': 'desc',
          }, // assuming sort param or default is desc
        ),
      ]);

      final dashboardRes = responses[0];
      final recentRes = responses[2];

      if (mounted) {
        setState(() {
          if (dashboardRes.data['status'] == 'success') {
            _stats = dashboardRes.data['data'];
          }
          if (recentRes.data['status'] == 'success') {
            _recentReports = List<Map<String, dynamic>>.from(
              recentRes.data['data'],
            );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 140, // Restored height
                    floating: false,
                    pinned: true,
                    backgroundColor: AppTheme.adminColor,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          Image.network(
                            'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: AppTheme.adminColor);
                            },
                          ),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.adminColor.withValues(alpha: 0.85),
                                  AppTheme.adminColor.withValues(alpha: 0.95),
                                ],
                              ),
                            ),
                          ),
                          // Content
                          SafeArea(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        LucideIcons.shieldCheck,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const Gap(14),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Halo, $_userName',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Gap(2),
                                          const Text(
                                            'Administrator',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
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
              body: RefreshIndicator(
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

                      const Text(
                        'Statistik Ringkas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(16),

                      // Stats Row (Compact Single Line)
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _CompactStatItem(
                              label: 'Laporan',
                              value: _stats?['totalReports']?.toString() ?? '0',
                              icon: LucideIcons.fileText,
                              color: Colors.blue,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200,
                            ),
                            _CompactStatItem(
                              label: 'User',
                              value: _stats?['totalUsers']?.toString() ?? '0',
                              icon: LucideIcons.users,
                              color: Colors.purple,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200,
                            ),
                            _CompactStatItem(
                              label: 'Handling',
                              value: '${_stats?['avgHandlingMinutes'] ?? 0}m',
                              icon: LucideIcons.clock,
                              color: Colors.orange,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200,
                            ),
                            const _CompactStatItem(
                              label: 'Server',
                              value: 'Online',
                              icon: LucideIcons.server,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Full Stats Link
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/admin/statistics'),
                          icon: const Icon(LucideIcons.barChart2, size: 18),
                          label: const Text('Lihat Statistik Lengkap'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.adminColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: AppTheme.adminColor.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing
                        children: [
                          _QuickActionButton(
                            label: 'Verifikasi User',
                            icon: LucideIcons.userCheck,
                            color: Colors.orange,
                            onTap: () => context.go(
                              '/admin/users?tab=1',
                            ),
                          ),
                          _QuickActionButton(
                            label: 'Kelola Staff',
                            icon: LucideIcons.users,
                            color: Colors.green,
                            onTap: () => context.go(
                              '/admin/staff', // Assuming route exists or users?tab=2
                            ), 
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

                      // Periodic Stats (Mock Chart)
                      const Text(
                        'Grafik Mingguan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      Container(
                        height: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tren Laporan (7 Hari Terakhir)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Gap(20),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final trendList = _stats?['weeklyTrend'] as List? ?? [];
                                  if (trendList.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'Belum ada data grafik',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }
                                  
                                  // Find max value safely
                                  int maxVal = 1;
                                  for (var item in trendList) {
                                    if (item is Map && item.containsKey('value')) {
                                      final val = item['value'] as int? ?? 0;
                                      if (val > maxVal) maxVal = val;
                                    }
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: trendList.map((t) {
                                      final val = (t['value'] as int? ?? 0).toDouble();
                                      final day = t['day']?.toString() ?? '';
                                      
                                      return _buildStatBar(
                                        context,
                                        day,
                                        val / maxVal,
                                        // Mocking "Done" ratio as 80% of "In" for visual demo if not provided
                                        // Real implementation should provide 'done' count in API if needed
                                        (val * 0.7) / maxVal, 
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                            const Gap(16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem(AppTheme.adminColor, 'Masuk'),
                                const Gap(16),
                                _buildLegendItem(Colors.green, 'Selesai'),
                              ],
                            ),
                          ],
                        ),
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

                      if (_recentReports.isEmpty)
                        const Center(
                          child: Text(
                            'Belum ada laporan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentReports.length > 3
                              ? 3
                              : _recentReports.length, // Limit to 3
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, index) {
                            final report = _recentReports[index];
                            return _ReportListItem(report: report);
                          },
                        ),
                      const Gap(24),

                      // System Logs (New List)
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _systemLogs.length > 3 ? 3 : _systemLogs.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, index) {
                          final log = _systemLogs[index];
                          IconData icon = LucideIcons.activity;
                          Color color = Colors.grey;

                          if (log['action']?.toString().toLowerCase().contains('created') == true) {
                            icon = LucideIcons.filePlus;
                            color = Colors.blue;
                          } else if (log['action']?.toString().toLowerCase().contains('verify') == true) {
                            icon = LucideIcons.userCheck;
                            color = Colors.green;
                          }

                          return _ActivityItem(
                            text: '${log['user']}: ${log['action']}',
                            time: _formatTimeAgo(log['time']),
                            icon: icon,
                            color: color,
                          );
                        },
                      ),

                      const Gap(80), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatTimeAgo(dynamic time) {
    if (time == null) return '-';
    final DateTime dateTime = time is DateTime ? time : DateTime.parse(time.toString());
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }

  Widget _buildEmergencyAlert(BuildContext context) {
    // Check if 'totalEmergency' is in stats, otherwise assume 0
    final emergencyCount = _stats?['totalEmergency'] ?? 0;

    if (emergencyCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Todo: Navigate to report list filtered by emergency
        // context.push('/admin/reports?isEmergency=true');
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

class _ReportListItem extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportListItem({required this.report});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    String status = report['status'] ?? 'Unknown';

    if (status == 'Menunggu') statusColor = Colors.orange;
    if (status == 'Diproses') statusColor = Colors.blue;
    if (status == 'Selesai') statusColor = Colors.green;
    if (status == 'Ditolak') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(LucideIcons.fileText, color: statusColor, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'] ?? 'Laporan Tanpa Judul',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${report['building']} • $status',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const Gap(8),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String text;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.text,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatBar(
  BuildContext context,
  String label,
  double pct1,
  double pct2,
) {
  // Ensure bars are visible even with 0 or very small counts
  final h1 = (100 * pct1).clamp(2.0, 100.0);
  final h2 = (100 * pct2).clamp(2.0, 100.0);
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 8,
            height: h1,
            decoration: BoxDecoration(
              color: AppTheme.adminColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(4),
          Container(
            width: 8,
            height: h2,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      const Gap(8),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ],
  );
}

Widget _buildLegendItem(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const Gap(6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _CompactStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
      ],
    );
  }
}
