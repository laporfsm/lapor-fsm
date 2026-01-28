import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';

class TeknisiProfilePage extends StatelessWidget {
  const TeknisiProfilePage({super.key});

  // TODO: [BACKEND] Fetch technician profile from API
  Map<String, dynamic> get _profile => {
    'name': 'Budi Teknisi',
    'nip': '198501152010011001',
    'email': 'budi.teknisi@undip.ac.id',
    'phone': '08123456789',
    'department': 'Unit Pemeliharaan',
    'specialization': 'Kelistrikan & AC',
  };

  // TODO: [BACKEND] Fetch technician statistics from API
  Map<String, int> get _stats => {
    'handled': 25,
    'completed': 23,
    'inProgress': 2,
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
                  // Avatar
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
                      size: 48,
                      color: AppTheme.secondaryColor,
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
                      color: AppTheme.secondaryColor.withOpacity(0.1),
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
                    value: _profile['email'],
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.phone,
                    label: "Telepon",
                    value: _profile['phone'],
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.building,
                    label: "Departemen",
                    value: _profile['department'],
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.wrench,
                    label: "Spesialisasi",
                    value: _profile['specialization'],
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: LucideIcons.user,
                    label: "Edit Profil",
                    onTap: () => context.push('/teknisi/edit-profile'),
                  ),
                  _MenuItem(
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
                    onTap: () => context.push('/teknisi/settings'),
                  ),
                  _MenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () => context.push('/teknisi/help'),
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
