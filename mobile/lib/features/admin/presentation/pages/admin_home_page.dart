import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  // Mock data
  static const Map<String, dynamic> _stats = {
    'totalReports': 156,
    'totalUsers': 1234,
    'totalStaff': 12,
    'pendingRegistrations': 3,
    'recentReports': 23,
    'avgHandlingMinutes': 45,
    'reportsByStatus': {
      'pending': 8,
      'verifikasi': 3,
      'penanganan': 5,
      'selesai': 140,
    },
    'staffByRole': {'teknisi': 8, 'supervisor': 3, 'admin': 1},
    'emergencyStats': {'emergency': 12, 'nonEmergency': 144},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.shield,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const Gap(12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Panel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Selamat datang, Admin',
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overview Stats
                _buildOverviewSection(),
                const Gap(20),

                // Menu Section
                _buildMenuSection(context),
                const Gap(20),

                // Reports Overview
                _buildReportsOverview(),
                const Gap(100), // Space for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Row(
      children: [
        _buildStatCard(
          'Laporan',
          _stats['totalReports'].toString(),
          LucideIcons.fileText,
          const Color(0xFF3B82F6),
        ),
        const Gap(10),
        _buildStatCard(
          'Pengguna',
          _stats['totalUsers'].toString(),
          LucideIcons.users,
          const Color(0xFF22C55E),
        ),
        const Gap(10),
        _buildStatCard(
          'Staff',
          _stats['totalStaff'].toString(),
          LucideIcons.userCog,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'MENU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Row 1: Staff & Users
        Row(
          children: [
            _buildMenuCard(
              icon: LucideIcons.users,
              label: 'Manajemen Staff',
              color: const Color(0xFF3B82F6),
              onTap: () => context.push('/admin/staff'),
            ),
            const Gap(10),
            _buildMenuCard(
              icon: LucideIcons.userCircle,
              label: 'Data Pengguna',
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push('/admin/users'),
            ),
          ],
        ),
        const Gap(10),
        // Row 2: Kategori & Export
        Row(
          children: [
            _buildMenuCard(
              icon: LucideIcons.tag,
              label: 'Kelola Kategori',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/admin/categories'),
            ),
            const Gap(10),
            _buildMenuCard(
              icon: LucideIcons.download,
              label: 'Export Data',
              color: const Color(0xFF22C55E),
              onTap: () => _showExportSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Gap(10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(6),
              Text(
                'Pilih data yang ingin di-export',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const Gap(16),
              _ExportOption(
                icon: LucideIcons.fileSpreadsheet,
                label: 'Laporan',
                color: const Color(0xFF22C55E),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting laporan...'),
                      backgroundColor: Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Gap(8),
              _ExportOption(
                icon: LucideIcons.users,
                label: 'Pengguna',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting pengguna...'),
                      backgroundColor: Color(0xFF3B82F6),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Gap(8),
              _ExportOption(
                icon: LucideIcons.userCog,
                label: 'Staff',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting staff...'),
                      backgroundColor: Color(0xFFF59E0B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsOverview() {
    final statusData = _stats['reportsByStatus'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.pieChart, size: 18, color: Color(0xFF059669)),
              const Gap(8),
              const Text(
                'Statistik Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Minggu ini: ${_stats['recentReports']}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildStatusBadge('Pending', statusData['pending'] ?? 0, Colors.grey),
              _buildStatusBadge('Verifikasi', statusData['verifikasi'] ?? 0, const Color(0xFF3B82F6)),
              _buildStatusBadge('Proses', statusData['penanganan'] ?? 0, const Color(0xFFF59E0B)),
              _buildStatusBadge('Selesai', statusData['selesai'] ?? 0, const Color(0xFF22C55E)),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric('Avg. Penanganan', '${_stats['avgHandlingMinutes']} menit'),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildMetric('Darurat', '${_stats['emergencyStats']['emergency']} laporan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const Gap(2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(LucideIcons.download, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
