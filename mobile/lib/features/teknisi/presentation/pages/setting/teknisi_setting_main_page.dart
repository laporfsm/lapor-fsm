import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';

class TeknisiSettingMainPage extends StatefulWidget {
  const TeknisiSettingMainPage({super.key});

  @override
  State<TeknisiSettingMainPage> createState() => _TeknisiSettingMainPageState();
}

class _TeknisiSettingMainPageState extends State<TeknisiSettingMainPage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  Map<String, int> _stats = {'menunggu': 0, 'ditangani': 0, 'disetujui': 0};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await authService.getCurrentUser();
    if (user != null) {
      final statsData = await reportService.getTechnicianDashboardStats(
        user['id'].toString(),
      );
      if (!mounted) return;
      setState(() {
        _profile = user;
        if (statsData != null) {
          _stats = {
            'menunggu': statsData['diproses'] ?? 0,
            'ditangani': statsData['penanganan'] ?? 0,
            'disetujui': statsData['approved'] ?? 0,
          };
        }
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToReports(String status) {
    final staffId = _profile?['id']?.toString();
    context.push(
      Uri(
        path: '/teknisi/all-reports',
        queryParameters: {
          'status': status,
          if (staffId != null) 'assignedTo': staffId,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Silakan Login Kembali'),
              const Gap(16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

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
      body: SingleChildScrollView(
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
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      border: Border.all(
                        color: AppTheme.secondaryColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.wrench,
                      size: 50,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _profile!['name'] ?? "Nama Tidak Tersedia",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _profile!['nimNip'] ?? "-",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.wrench,
                          size: 14,
                          color: AppTheme.secondaryColor,
                        ),
                        const Gap(4),
                        const Text(
                          "Teknisi",
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
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
                title: "Statistik Progres",
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToReports('diproses'),
                        child: StatsBigStatItem(
                          icon: LucideIcons.inbox,
                          value: _stats['menunggu'].toString(),
                          label: "Masuk",
                          color: AppTheme.getStatusColor('diproses'),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToReports(
                          'penanganan,onHold,selesai,recalled',
                        ),
                        child: StatsBigStatItem(
                          icon: LucideIcons.hammer,
                          value: _stats['ditangani'].toString(),
                          label: "Ditangani",
                          color: AppTheme.getStatusColor('penanganan'),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToReports('approved'),
                        child: StatsBigStatItem(
                          icon: LucideIcons.checkCircle2,
                          value: _stats['disetujui'].toString(),
                          label: "Disetujui",
                          color: AppTheme.getStatusColor('approved'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Bio Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                title: "Biodata & Kontak",
                children: [
                  ProfileInfoRow(
                    icon: LucideIcons.mail,
                    label: "Email",
                    value: _profile!['email'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.phone,
                    label: "Telepon",
                    value: _profile!['phone'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.mapPin,
                    label: "Lokasi",
                    value: _profile!['address'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.wrench,
                    label: "Spesialisasi",
                    value: _profile!['specialization'] ?? "-",
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Akun Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                title: "Akun",
                children: [
                  ProfileMenuItem(
                    icon: LucideIcons.userCog,
                    label: "Edit Profil",
                    onTap: () => context.push('/teknisi/edit-profile'),
                    color: AppTheme.secondaryColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.lock,
                    label: "Ubah Password",
                    onTap: () => context.push('/teknisi/settings'),
                    color: AppTheme.secondaryColor,
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                title: "Pengaturan & Lainnya",
                children: [
                  ProfileMenuItem(
                    icon: LucideIcons.settings,
                    label: "Preferensi & Notifikasi",
                    onTap: () => context.push('/teknisi/settings'),
                    color: AppTheme.secondaryColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/teknisi/help'),
                    color: AppTheme.secondaryColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.logOut,
                    label: "Keluar",
                    onTap: () => _showLogoutConfirmation(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const Gap(32),
          ],
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
