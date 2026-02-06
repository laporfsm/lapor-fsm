import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/services/auth_service.dart';

class PJGedungProfilePage extends StatefulWidget {
  const PJGedungProfilePage({super.key});

  @override
  State<PJGedungProfilePage> createState() => _PJGedungProfilePageState();
}

class _PJGedungProfilePageState extends State<PJGedungProfilePage> {
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await authService.getCurrentUser();

    // Fetch location from local storage or API if needed,
    // for now we try to get what we have or default to 'Lokasi A' if managedLocation isn't in local storage yet
    // In a real app we might want to refresh profile from API here.

    if (mounted) {
      setState(() {
        _profile = {
          'name': user?['name'] ?? 'Staff',
          'nip': user?['nimNip'] ?? '-',
          'email': user?['email'] ?? '-',
          'phone': user?['phone'] ?? '-',
          'location': user?['managedLocation'] ?? '-',
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                      color: AppTheme.pjLokasiColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.pjLokasiColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 48,
                      color: AppTheme.pjLokasiColor,
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
                      color: AppTheme.pjLokasiColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: AppTheme.pjLokasiColor,
                        ),
                        Gap(4),
                        Text(
                          "PJ Lokasi",
                          style: TextStyle(
                            color: AppTheme.pjLokasiColor,
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
                        if (_profile['location'] != null &&
                            _profile['location'] != 'null')
                          Column(
                            children: [
                              const Divider(height: 24),
                              ProfileInfoRow(
                                icon: LucideIcons.mapPin,
                                label: "Lokasi",
                                value: _profile['location'],
                              ),
                            ],
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
                    icon: LucideIcons.userCog,
                    label: "Ubah Profil",
                    onTap: () => context.push('/pj-gedung/edit-profile'),
                    color: AppTheme.pjLokasiColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
                    onTap: () => context.push('/pj-gedung/settings'),
                    color: AppTheme.pjLokasiColor,
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/pj-gedung/help'),
                    color: AppTheme.pjLokasiColor,
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
