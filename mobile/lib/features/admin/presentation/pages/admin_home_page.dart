import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  // Mock data
  final Map<String, dynamic> _stats = {
    'totalReports': 156,
    'totalUsers': 1234,
    'totalStaff': 12,
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
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF059669), // Emerald for Admin
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
                                  LucideIcons.settings,
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
                                      'Admin Panel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Manajemen Sistem',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  LucideIcons.logOut,
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
              // Overview Stats
              _buildOverviewSection(),
              const Gap(24),

              // Quick Actions
              _buildQuickActions(),
              const Gap(24),

              // Reports Overview
              _buildReportsOverview(),
              const Gap(24),

              // Staff Overview
              _buildStaffOverview(),
              const Gap(24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/admin/staff');
              break;
            case 2:
              context.push('/admin/categories');
              break;
            case 3:
              context.push('/admin/users');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.tag),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.userCircle),
            label: 'Users',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Row(
      children: [
        _buildOverviewCard(
          'Total Laporan',
          _stats['totalReports'].toString(),
          LucideIcons.fileText,
          Colors.blue,
        ),
        const Gap(12),
        _buildOverviewCard(
          'Total Pengguna',
          _stats['totalUsers'].toString(),
          LucideIcons.users,
          Colors.green,
        ),
        const Gap(12),
        _buildOverviewCard(
          'Total Staff',
          _stats['totalStaff'].toString(),
          LucideIcons.userCog,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Cepat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Kelola Staff',
                LucideIcons.userPlus,
                const Color(0xFF059669),
                () => context.push('/admin/staff'),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildActionCard(
                'Kelola Kategori',
                LucideIcons.tag,
                Colors.purple,
                () => context.push('/admin/categories'),
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Lihat Pengguna',
                LucideIcons.users,
                Colors.blue,
                () => context.push('/admin/users'),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildActionCard(
                'Export Data',
                LucideIcons.download,
                Colors.orange,
                () => _showExportDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
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
          Row(
            children: [
              const Icon(
                LucideIcons.pieChart,
                size: 18,
                color: Color(0xFF059669),
              ),
              const Gap(8),
              const Text(
                'Laporan per Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Minggu ini: ${_stats['recentReports']}',
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildStatusItem(
                'Pending',
                statusData['pending'] ?? 0,
                Colors.grey,
              ),
              _buildStatusItem(
                'Verifikasi',
                statusData['verifikasi'] ?? 0,
                Colors.blue,
              ),
              _buildStatusItem(
                'Penanganan',
                statusData['penanganan'] ?? 0,
                Colors.orange,
              ),
              _buildStatusItem(
                'Selesai',
                statusData['selesai'] ?? 0,
                Colors.green,
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Penanganan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${_stats['avgHandlingMinutes']} menit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Darurat/Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${_stats['emergencyStats']['emergency']}/${_stats['totalReports']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffOverview() {
    final staffData = _stats['staffByRole'] as Map<String, dynamic>;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.users, size: 18, color: Color(0xFF059669)),
              const Gap(8),
              const Text(
                'Staff Aktif',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/admin/staff'),
                child: const Text('Kelola'),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildStaffItem(
            'Teknisi',
            staffData['teknisi'] ?? 0,
            LucideIcons.wrench,
            Colors.blue,
          ),
          _buildStaffItem(
            'Supervisor',
            staffData['supervisor'] ?? 0,
            LucideIcons.clipboardCheck,
            Colors.purple,
          ),
          _buildStaffItem(
            'Admin',
            staffData['admin'] ?? 0,
            LucideIcons.settings,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffItem(String role, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              role,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            const Text(
              'Export Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.fileSpreadsheet,
                  color: Colors.green,
                ),
              ),
              title: const Text('Export Laporan'),
              subtitle: const Text('Format Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting laporan...')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.users, color: Colors.blue),
              ),
              title: const Text('Export Data Pengguna'),
              subtitle: const Text('Format Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting pengguna...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
