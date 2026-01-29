import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';

class PJGedungProfilePage extends StatelessWidget {
  const PJGedungProfilePage({super.key});

  Map<String, dynamic> get _profile => {
    'name': 'Budi PJ Gedung',
    'nip': '198501012010011001',
    'email': 'budi.gedung@undip.ac.id',
    'phone': '08765432109',
    'building': 'Gedung A - Dekanat',
  };

  @override
  Widget build(BuildContext context) {
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _profile['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _profile['nip'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.building,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        Gap(4),
                        Text(
                          "PJ Gedung",
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
                          value: _profile['email'],
                        ),
                        const Divider(height: 24),
                        ProfileInfoRow(
                          icon: LucideIcons.phone,
                          label: "Telepon",
                          value: _profile['phone'],
                        ),
                        const Divider(height: 24),
                        ProfileInfoRow(
                          icon: LucideIcons.building2,
                          label: "Gedung",
                          value: _profile['building'],
                        ),
                      ],
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
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
                    onTap: () => context.push('/pj-gedung/settings'),
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/pj-gedung/help'),
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
