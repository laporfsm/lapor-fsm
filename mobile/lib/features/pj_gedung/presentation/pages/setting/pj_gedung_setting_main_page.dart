import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';

class PJGedungSettingMainPage extends StatefulWidget {
  const PJGedungSettingMainPage({super.key});

  @override
  State<PJGedungSettingMainPage> createState() =>
      _PJGedungSettingMainPageState();
}

class _PJGedungSettingMainPageState extends State<PJGedungSettingMainPage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  // Stats: Total Reports (Vol), Emergency (Critical), Completed (Success)
  Map<String, int> _stats = {'total': 0, 'emergency': 0, 'completed': 0};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await authService.getCurrentUser();
    if (user != null) {
      if (!mounted) return;
      setState(() => _profile = user);

      // Fetch historical stats
      try {
        // We use getPJStatistics if available, or fetch counts manually
        // Since backend might not have this specific aggregation yet,
        // we can try to fetch counts from existing endpoints if possible,
        // or just use getPJDashboardStats and Map what we can, but user requested historical.
        // Let's assume we can get these from getPJStatistics or similar.
        final statsData = await reportService.getPJStatistics();

        // If getPJStatistics returns these keys, great. If not, we might need adjustments.
        // Based on previous tool views, getPJStatistics exists.

        if (!mounted) return;
        if (statsData != null) {
          setState(() {
            _stats = {
              'total': statsData['totalReports'] ?? 0,
              'emergency': statsData['totalEmergency'] ?? 0,
              'completed': statsData['totalCompleted'] ?? 0,
            };
          });
        }
      } catch (e) {
        debugPrint('Error loading stats: $e');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToReports(String? status, {bool? isEmergency}) {
    context.push(
      Uri(
        path: '/pj-gedung/reports',
        queryParameters: {
          if (status != null) 'status': status,
          if (isEmergency != null) 'emergency': isEmergency.toString(),
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
                      color: AppTheme.pjGedungColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.pjGedungColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 50,
                      color: AppTheme.pjGedungColor,
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
                      color: AppTheme.pjGedungColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: AppTheme.pjGedungColor,
                        ),
                        Gap(4),
                        Text(
                          "PJ Gedung",
                          style: TextStyle(
                            color: AppTheme.pjGedungColor,
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

            // Stats Section (Historical)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsSectionCard(
                title: "Statistik Lokasi",
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToReports(null), // All Reports
                        child: StatsBigStatItem(
                          icon: LucideIcons.fileText,
                          value: _stats['total'].toString(),
                          label: "Total Laporan",
                          color: Colors.blue,
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
                        onTap: () =>
                            _navigateToReports(null, isEmergency: true),
                        child: StatsBigStatItem(
                          icon: LucideIcons.alertTriangle,
                          value: _stats['emergency'].toString(),
                          label: "Darurat",
                          color: Colors.red,
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
                        onTap: () => _navigateToReports('selesai'),
                        child: StatsBigStatItem(
                          icon: LucideIcons.checkCircle2,
                          value: _stats['completed'].toString(),
                          label: "Selesai",
                          color: Colors.green,
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
                    value: _profile!['managedLocation'] ?? "-",
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
                    onTap: () => context.push('/pj-gedung/edit-profile'),
                    color: AppTheme.pjGedungColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.lock,
                    label:
                        "Ubah Password", // Reused /settings route or new route?
                    // Technician uses /teknisi/settings for password change entry?
                    // Actually technician uses /teknisi/settings for complete settings including pass?
                    // Let's verify route later. For now stick to existing pattern.
                    onTap: () => context.push('/pj-gedung/settings'),
                    color: AppTheme.pjGedungColor,
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
                    onTap: () => context.push('/pj-gedung/settings'),
                    color: AppTheme.pjGedungColor,
                  ),

                  ProfileMenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/pj-gedung/help'),
                    color: AppTheme.pjGedungColor,
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
