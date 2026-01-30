import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/services/auth_service.dart';

class TeknisiProfilePage extends StatefulWidget {
  const TeknisiProfilePage({super.key});

  @override
  State<TeknisiProfilePage> createState() => _TeknisiProfilePageState();
}

class _TeknisiProfilePageState extends State<TeknisiProfilePage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _profile = user;
        _isLoading = false;
      });
    }
  }

  Map<String, int> get _stats => {
    'handled': 0, // In real app, these should also come from API
    'completed': 0,
    'inProgress': 0,
  };

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Silakan Login'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
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
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.secondaryColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.wrench,
                      size: 48,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _profile!['name'] ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _profile!['nimNip'] ?? "-",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.wrench,
                          size: 14,
                          color: AppTheme.secondaryColor,
                        ),
                        const Gap(4),
                        Text(
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

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ProfileInfoRow(
                          icon: LucideIcons.mail,
                          label: "Email",
                          value: _profile!['email'] ?? "-",
                        ),
                        const Divider(height: 24),
                        ProfileInfoRow(
                          icon: LucideIcons.phone,
                          label: "Telepon",
                          value: _profile!['phone'] ?? "-",
                        ),
                        const Divider(height: 24),
                        ProfileInfoRow(
                          icon: LucideIcons.building,
                          label: "Departemen",
                          value: _profile!['department'] ?? "Unit Pemeliharaan",
                        ),
                        const Divider(height: 24),
                        ProfileInfoRow(
                          icon: LucideIcons.wrench,
                          label: "Spesialisasi",
                          value: _profile!['specialization'] ?? "-",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: LucideIcons.fileText,
                      value: _stats['handled'].toString(),
                      label: "Ditangani",
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _StatItem(
                      icon: LucideIcons.checkCircle,
                      value: _stats['completed'].toString(),
                      label: "Selesai",
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _StatItem(
                      icon: LucideIcons.clock,
                      value: _stats['inProgress'].toString(),
                      label: "Proses",
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                children: [
                  ProfileMenuItem(
                    icon: LucideIcons.user,
                    label: "Edit Profil",
                    onTap: () async {
                      await context.push('/teknisi/edit-profile');
                      _loadUserData();
                    },
                    color: AppTheme.secondaryColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
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
            onPressed: () {
              context.pop();
              context.go('/login');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryColor),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
