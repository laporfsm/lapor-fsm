import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart';

/// Dashboard page for Supervisor (tab 0 in shell)
/// This page contains the main dashboard content WITHOUT bottom navigation bar
class SupervisorDashboardPage extends StatelessWidget {
  const SupervisorDashboardPage({super.key});

  // TODO: [BACKEND] Replace with API call to fetch stats
  Map<String, dynamic> get _stats => {
    'pending': 5,
    'verifikasi': 2,
    'penanganan': 3,
    'selesai': 45,
    'emergency': 2, // Laporan darurat yang perlu perhatian
    'todayReports': 8,
    'weekReports': 32,
    'monthReports': 45,
  };

  // TODO: [BACKEND] Replace with API call to fetch pending reviews
  List<Map<String, dynamic>> get _pendingReview => [
    {
      'id': 1,
      'title': 'AC Mati di Lab Komputer',
      'teknisi': 'Budi Teknisi',
      'completedAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'duration': '45 menit',
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'teknisi': 'Andi Teknisi',
      'completedAt': DateTime.now().subtract(const Duration(hours: 1)),
      'duration': '1 jam 20 menit',
    },
  ];

  // TODO: [BACKEND] Replace with API call to fetch technicians
  List<Map<String, dynamic>> get _technicians => [
    {'id': 1, 'name': 'Budi Teknisi', 'handled': 15, 'completed': 14},
    {'id': 2, 'name': 'Andi Teknisi', 'handled': 12, 'completed': 12},
    {'id': 3, 'name': 'Citra Teknisi', 'handled': 8, 'completed': 7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [supervisorColor, Color(0xFF4338CA)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.clipboardCheck,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const Gap(12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard Supervisor',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Monitoring & Evaluasi',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmergencyAlert(context),
              const Gap(16),
              _buildStatsSection(context),
              const Gap(24),
              _buildQuickActions(context),
              const Gap(24),
              _buildSectionHeader(
                context,
                'Menunggu Review',
                'Lihat Semua',
                // Navigate to finished reports (assuming pending review usually means finished)
                () => context.push(
                  Uri(
                    path: '/supervisor/reports/filter',
                    queryParameters: {'status': 'selesai'},
                  ).toString(),
                ),
              ),
              const Gap(12),
              _buildPendingReviewList(context),
              const Gap(24),
              _buildSectionHeader(
                context,
                'Log Aktivitas Teknisi',
                'Lihat Semua',
                // Navigate to technician list
                () => context.push('/supervisor/technicians'),
              ),
              const Gap(12),
              _buildTechnicianPerformance(),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  /// Emergency alert banner - clickable
  Widget _buildEmergencyAlert(BuildContext context) {
    final emergencyCount = _stats['emergency'] ?? 0;
    if (emergencyCount == 0) return const SizedBox.shrink();

    return GestureDetector(
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
              color: Colors.red.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.9),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
      child: GestureDetector(
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
                color: Colors.black.withOpacity(0.05),
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
      child: GestureDetector(
        onTap: () => context.push(
          Uri(
            path: '/supervisor/reports/filter',
            queryParameters: {'status': status},
          ).toString(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Review Penolakan',
                LucideIcons.xCircle,
                Colors.red,
                () => context.push('/supervisor/rejected'),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildActionButton(
                'Export',
                LucideIcons.download,
                Colors.green,
                () => context.push('/supervisor/export'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
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
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        TextButton(onPressed: onTap, child: Text(actionText)),
      ],
    );
  }

  Widget _buildPendingReviewList(BuildContext context) {
    if (_pendingReview.isEmpty) {
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
                'Tidak ada laporan menunggu review',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _pendingReview.map((report) {
        return GestureDetector(
          onTap: () => context.push('/supervisor/review/${report['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.clipboardCheck,
                    color: Colors.green,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const Gap(4),
                          Text(
                            report['teknisi'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Gap(12),
                          Icon(
                            LucideIcons.timer,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const Gap(4),
                          Text(
                            report['duration'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.grey),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTechnicianPerformance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _technicians.map((tech) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: supervisorColor.withOpacity(0.1),
                  child: Text(
                    tech['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      color: supervisorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(12),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tech['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Teknisi ${tech['status'] == 'online' ? '• Online' : '• Offline'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: tech['status'] == 'online'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Simple Stats: Done / Total
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle2,
                        size: 14,
                        color: Colors.green,
                      ),
                      const Gap(4),
                      Text(
                        '${tech['completed']}/${tech['handled']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
