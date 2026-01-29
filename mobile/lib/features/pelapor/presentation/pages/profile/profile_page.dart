import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _currentUser;
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
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      // Should not happen if guarded by auth, but just in case
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Silakan Login'),
          ),
        ),
      );
    }

    final isVerified = _currentUser!['isVerified'] == true;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
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
                      size: 48,
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
                    textAlign: TextAlign.center,
                  ),
                  const Gap(4),
                  Text(
                    _currentUser!['nimNip'] ?? "-",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Gap(8),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified
                              ? LucideIcons.checkCircle
                              : LucideIcons.clock,
                          size: 14,
                          color: isVerified ? Colors.green : Colors.orange,
                        ),
                        const Gap(4),
                        Text(
                          isVerified
                              ? "Akun Terverifikasi"
                              : "Menunggu Verifikasi",
                          style: TextStyle(
                            color: isVerified ? Colors.green : Colors.orange,
                            fontSize: 12,
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.mail,
                    label: "Email",
                    value: _currentUser!['email'] ?? "-",
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.hash,
                    label: "NIM/NIP",
                    value: _currentUser!['nimNip'] ?? "-",
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.phone,
                    label: "Nomor HP",
                    value: _currentUser!['phone'] ?? "-",
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.mapPin,
                    label: "Alamat",
                    value: _currentUser!['address'] ?? "-",
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Emergency Contact Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: Colors.red.shade700,
                        size: 18,
                      ),
                      const Gap(8),
                      Text(
                        'Kontak Darurat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  _InfoRow(
                    icon: LucideIcons.userCircle,
                    label: "Nama",
                    value: _currentUser!['emergencyName'] ?? "-",
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: LucideIcons.phoneCall,
                    label: "Nomor HP",
                    value: _currentUser!['emergencyPhone'] ?? "-",
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Menu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: LucideIcons.edit,
                    label: "Edit Profil",
                    onTap: () async {
                      // Reload data when returning from edit profile
                      await context.push('/edit-profile');
                      _loadUserData();
                    },
                  ),
                  _MenuItem(
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/help'),
                  ),
                  _MenuItem(
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
              context.pop(); // Close dialog
              context.go('/login');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey.shade700,
              size: 24,
            ),
            const Gap(16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
