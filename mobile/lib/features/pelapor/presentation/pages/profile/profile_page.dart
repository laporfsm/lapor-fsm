import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  Map<String, int> _stats = {'aktif': 0, 'selesai': 0, 'ditolak': 0};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await authService.getCurrentUser();
    if (user != null) {
      final reportsResponse = await reportService.getMyReports(
        user['id'].toString(),
      );
      if (!mounted) return;
      final List<dynamic> reports = reportsResponse['data'] ?? [];

      int aktifCount = 0;
      int selesaiCount = 0;
      int ditolakCount = 0;

      for (var reportJson in reports) {
        final statusStr = reportJson['status'] as String?;
        if (statusStr == null) {
          aktifCount++;
          continue;
        }

        final statusLower = statusStr.toLowerCase();

        // Match Logic in report_history_page.dart
        if (statusLower == 'ditolak') {
          ditolakCount++;
        } else if (['selesai', 'approved', 'archived'].contains(statusLower)) {
          selesaiCount++;
        } else {
          aktifCount++;
        }
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _stats = {
            'aktif': aktifCount,
            'selesai': selesaiCount,
            'ditolak': ditolakCount,
          };
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
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

    // Removed isVerified logic as it's redundant for logged in users

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
            // Header Profile (Clean Style)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _currentUser!['name'] ?? "Nama Tidak Tersedia",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _currentUser!['nimNip'] ?? "-",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const Gap(8),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.user,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const Gap(4),
                        Text(
                          "Pelapor",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
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

            // Statistics Section (Aligned with History Filters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsSectionCard(
                title: "Statistik Laporan Saya",
                child: Row(
                  children: [
                    Expanded(
                      child: StatsBigStatItem(
                        icon: LucideIcons.clock,
                        value: _stats['aktif'].toString(),
                        label: "Aktif",
                        color: Colors.orange,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: StatsBigStatItem(
                        icon: LucideIcons.checkCircle2,
                        value: _stats['selesai'].toString(),
                        label: "Selesai",
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: StatsBigStatItem(
                        icon: LucideIcons.xCircle,
                        value: _stats['ditolak'].toString(),
                        label: "Ditolak",
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Biodata & Kontak Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                title: "Biodata & Kontak",
                children: [
                  ProfileInfoRow(
                    icon: LucideIcons.mail,
                    label: "Email",
                    value: _currentUser!['email'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.hash,
                    label: "NIM/NIP",
                    value: _currentUser!['nimNip'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.building,
                    label: "Fakultas",
                    value: _currentUser!['faculty'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.school,
                    label: "Departemen / Prodi",
                    value: _currentUser!['department'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.phone,
                    label: "Nomor HP",
                    value: _currentUser!['phone'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.mapPin,
                    label: "Alamat",
                    value: _currentUser!['address'] ?? "-",
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Kontak Darurat Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                title: "Kontak Darurat",
                children: [
                  ProfileInfoRow(
                    icon: LucideIcons.userCircle,
                    label: "Nama",
                    value: _currentUser!['emergencyName'] ?? "-",
                  ),
                  ProfileInfoRow(
                    icon: LucideIcons.phoneCall,
                    label: "Nomor HP",
                    value: _currentUser!['emergencyPhone'] ?? "-",
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
                    onTap: () async {
                      await context.push('/edit-profile');
                      _loadUserData();
                    },
                    color: AppTheme.primaryColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.lock,
                    label: "Ubah Password",
                    onTap: () {
                      // Note: Usually uses forgot password flow or dedicated reset page
                      context.push('/forgot-password');
                    },
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Pengaturan & Lainnya Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                title: "Pengaturan & Lainnya",
                children: [
                  ProfileMenuItem(
                    icon: LucideIcons.settings,
                    label: "Preferensi & Notifikasi",
                    onTap: () => context.push('/settings'),
                    color: AppTheme.primaryColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/help'),
                    color: AppTheme.primaryColor,
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
                context.pop(); // Close dialog
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
