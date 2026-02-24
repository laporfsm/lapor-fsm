import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/master_data/supervisor_master_data_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_technician_main_page.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';

class SupervisorSettingMainPage extends StatefulWidget {
  const SupervisorSettingMainPage({super.key});

  @override
  State<SupervisorSettingMainPage> createState() =>
      _SupervisorSettingMainPageState();
}

class _SupervisorSettingMainPageState extends State<SupervisorSettingMainPage> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _stats = {
    'approved': 0,
    'recalled': 0,
    'terverifikasi': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        setState(() => _profile = user);

        // Fetch stats from dashboard
        final response = await apiService.dio.get(
          '/supervisor/dashboard/${user['id']}',
        );
        if (response.data['status'] == 'success') {
          setState(() {
            _stats = response.data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading supervisor setting data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Setting'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Profile
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.supervisorColor.withValues(
                                alpha: 0.1,
                              ),
                              border: Border.all(
                                color: AppTheme.supervisorColor,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.shieldCheck,
                              size: 50,
                              color: AppTheme.supervisorColor,
                            ),
                          ),
                          const Gap(16),
                          Text(
                            _profile?['name'] ?? 'Supervisor',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            _profile?['nimNip'] ?? "-",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.supervisorColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.shield,
                                  size: 14,
                                  color: AppTheme.supervisorColor,
                                ),
                                Gap(4),
                                Text(
                                  "Supervisor",
                                  style: TextStyle(
                                    color: AppTheme.supervisorColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // Stats Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StatsSectionCard(
                        title: "Statistik Kinerja",
                        child: Row(
                          children: [
                            Expanded(
                              child: StatsBigStatItem(
                                icon: LucideIcons.fileCheck,
                                value: (_stats['terverifikasi'] ?? 0)
                                    .toString(),
                                label: "Di-review",
                                color: AppTheme.getStatusColor('terverifikasi'),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade100,
                            ),
                            Expanded(
                              child: StatsBigStatItem(
                                icon: LucideIcons.checkCircle,
                                value: (_stats['approved'] ?? 0).toString(),
                                label: "Disetujui",
                                color: AppTheme.getStatusColor('approved'),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade100,
                            ),
                            Expanded(
                              child: StatsBigStatItem(
                                icon: LucideIcons.xCircle,
                                value: (_stats['ditolak'] ?? 0).toString(),
                                label: "Ditolak",
                                color: AppTheme.getStatusColor('ditolak'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(24),

                    // Menu Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ProfileSection(
                            title: "Biodata & Kontak",
                            children: [
                              ProfileInfoRow(
                                icon: LucideIcons.mail,
                                label: "Email",
                                value: _profile?['email'] ?? '-',
                              ),
                              ProfileInfoRow(
                                icon: LucideIcons.phone,
                                label: "Telepon",
                                value: _profile?['phone'] ?? '-',
                              ),
                              ProfileInfoRow(
                                icon: LucideIcons.mapPin,
                                label: "Lokasi",
                                value: _profile?['address'] ?? '-',
                              ),
                            ],
                          ),
                          const Gap(24),
                          ProfileSection(
                            title: "Akun",
                            children: [
                              ProfileMenuItem(
                                icon: LucideIcons.userCog,
                                label: "Edit Profil",
                                onTap: () =>
                                    context.push('/supervisor/edit-profile'),
                                color: AppTheme.supervisorColor,
                              ),
                              ProfileMenuItem(
                                icon: LucideIcons.lock,
                                label: "Ubah Password",
                                onTap: () =>
                                    context.push('/supervisor/settings'),
                                color: AppTheme.supervisorColor,
                              ),
                            ],
                          ),
                          const Gap(24),
                          ProfileSection(
                            title: "Manajemen Sistem",
                            children: [
                              ProfileMenuItem(
                                icon: LucideIcons.database,
                                label: "Master Data",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SupervisorMasterDataPage(),
                                  ),
                                ),
                                color: AppTheme.supervisorColor,
                              ),
                              ProfileMenuItem(
                                icon: LucideIcons.users,
                                label: "Menu Staff",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SupervisorTechnicianMainPage(),
                                  ),
                                ),
                                color: AppTheme.supervisorColor,
                              ),
                              ProfileMenuItem(
                                icon: LucideIcons.barChart2,
                                label: "Statistik Lengkap",
                                onTap: () =>
                                    context.push('/supervisor/statistics'),
                                color: AppTheme.supervisorColor,
                              ),
                            ],
                          ),
                          const Gap(24),
                          ProfileSection(
                            title: "Pengaturan & Lainnya",
                            children: [
                              ProfileMenuItem(
                                icon: LucideIcons.settings,
                                label: "Preferensi & Notifikasi",
                                onTap: () =>
                                    context.push('/supervisor/settings'),
                                color: AppTheme.supervisorColor,
                              ),
                              ProfileMenuItem(
                                icon: LucideIcons.helpCircle,
                                label: "Bantuan",
                                onTap: () => context.push('/supervisor/help'),
                                color: AppTheme.supervisorColor,
                              ),
                              ProfileMenuItem(
                                icon: LucideIcons.logOut,
                                label: "Keluar",
                                isDestructive: true,
                                onTap: () => _showLogoutConfirmation(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.pop();
                context.go('/login');
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// _StatItem removed in favor of statistics_widgets.dart
