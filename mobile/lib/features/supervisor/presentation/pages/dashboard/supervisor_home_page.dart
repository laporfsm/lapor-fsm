import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';

// Supervisor theme color - differentiated from Pelapor (blue) and Teknisi (orange)
const Color _supervisorColor = Color(0xFF3730A3); // Emerald green

class SupervisorHomePage extends StatefulWidget {
  const SupervisorHomePage({super.key});

  @override
  State<SupervisorHomePage> createState() => _SupervisorHomePageState();
}

class _SupervisorHomePageState extends State<SupervisorHomePage> {
  int _currentIndex = 0;

  // Mock data - akan diganti dengan API
  final Map<String, dynamic> _stats = {
    'pending': 5,
    'verifikasi': 2,
    'penanganan': 3,
    'selesai': 45,
    'todayReports': 8,
    'weekReports': 32,
    'monthReports': 45,
  };

  final List<Map<String, dynamic>> _pendingReview = [
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

  final List<Map<String, dynamic>> _technicians = [
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
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: _supervisorColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _supervisorColor,
                        Color(0xFF10B981), // Lighter emerald
                      ],
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
                                  color: Colors.white.withValues(alpha: 0.2),
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
                              IconButton(
                                onPressed: () =>
                                    context.push('/supervisor/profile'),
                                icon: const Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
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
              // Stats Cards
              _buildStatsSection(),
              const Gap(24),

              // Quick Actions
              _buildQuickActions(),
              const Gap(24),

              // Pending Review
              _buildSectionHeader('Menunggu Review', 'Lihat Semua', () {
                context.push('/supervisor/reports');
              }),
              const Gap(12),
              _buildPendingReviewList(),
              const Gap(24),

              // Technician Performance
              _buildSectionHeader('Kinerja Teknisi', 'Detail', () {
                context.push('/supervisor/performance');
              }),
              const Gap(12),
              _buildTechnicianPerformance(),
              const Gap(24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _supervisorColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              break; // Already on home
            case 1:
              context.push('/supervisor/reports');
              break;
            case 2:
              context.push('/supervisor/archive');
              break;
            case 3:
              context.push('/supervisor/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.fileText),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.archive),
            label: 'Arsip',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        // Period stats
        Row(
          children: [
            _buildStatCard(
              'Hari Ini',
              _stats['todayReports'].toString(),
              LucideIcons.calendar,
              Colors.blue,
            ),
            const Gap(12),
            _buildStatCard(
              'Minggu Ini',
              _stats['weekReports'].toString(),
              LucideIcons.calendarDays,
              Colors.green,
            ),
            const Gap(12),
            _buildStatCard(
              'Bulan Ini',
              _stats['monthReports'].toString(),
              LucideIcons.calendarRange,
              Colors.orange,
            ),
          ],
        ),
        const Gap(12),
        // Status breakdown
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
                  _buildStatusBadge('Pending', _stats['pending'], Colors.grey),
                  const Gap(8),
                  _buildStatusBadge(
                    'Verifikasi',
                    _stats['verifikasi'],
                    Colors.blue,
                  ),
                  const Gap(8),
                  _buildStatusBadge(
                    'Penanganan',
                    _stats['penanganan'],
                    Colors.orange,
                  ),
                  const Gap(8),
                  _buildStatusBadge('Selesai', _stats['selesai'], Colors.green),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
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
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Expanded(
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
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Lihat Laporan',
            LucideIcons.fileText,
            Colors.blue,
            () => context.push('/supervisor/reports'),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildActionButton(
            'Export Data',
            LucideIcons.download,
            Colors.green,
            () => context.push('/supervisor/export'),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildActionButton(
            'Arsip',
            LucideIcons.archive,
            Colors.orange,
            () => context.push('/supervisor/archive'),
          ),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildPendingReviewList() {
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                    color: Colors.green.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _technicians.map((tech) {
          final completionRate = tech['handled'] > 0
              ? (tech['completed'] / tech['handled'] * 100).toInt()
              : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _supervisorColor.withValues(alpha: 0.1),
                  child: Text(
                    tech['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      color: _supervisorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tech['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Gap(4),
                      LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionRate >= 90
                              ? Colors.green
                              : completionRate >= 70
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tech['completed']}/${tech['handled']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$completionRate%',
                      style: TextStyle(
                        fontSize: 12,
                        color: completionRate >= 90
                            ? Colors.green
                            : completionRate >= 70
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
