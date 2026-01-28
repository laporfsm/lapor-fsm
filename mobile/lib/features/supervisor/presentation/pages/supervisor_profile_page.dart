import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';

/// Profile page for Supervisor (tab 3 in shell)
/// This page shows supervisor profile info WITHOUT bottom navigation bar
class SupervisorProfilePage extends StatelessWidget {
  const SupervisorProfilePage({super.key});

  // TODO: [BACKEND] Fetch supervisor profile from API
  Map<String, dynamic> get _profile => {
    'name': 'Dr. Ahmad Supervisor',
    'nip': '197001012000011001',
    'email': 'ahmad.supervisor@undip.ac.id',
    'phone': '08123456789',
    'department': 'UP2TI FSM Undip',
    'position': 'Kepala Unit',
  };

  // TODO: [BACKEND] Fetch supervisor statistics from API
  Map<String, int> get _stats => {
    'reviewed': 150,
    'approved': 145,
    'recalled': 5,
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
                      color: supervisorColor.withOpacity(0.1),
                      border: Border.all(color: supervisorColor, width: 3),
                    ),
                    child: const Icon(
                      LucideIcons.clipboardCheck,
                      size: 48,
                      color: supervisorColor,
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
                      color: supervisorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.shield,
                          size: 14,
                          color: supervisorColor,
                        ),
                        const Gap(4),
                        Text(
                          "Supervisor",
                          style: TextStyle(
                            color: supervisorColor,
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
                    icon: LucideIcons.briefcase,
                    label: "Jabatan",
                    value: _profile['position'],
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
                      icon: LucideIcons.fileCheck,
                      value: _stats['reviewed'].toString(),
                      label: "Di-review",
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _StatItem(
                      icon: LucideIcons.checkCircle,
                      value: _stats['approved'].toString(),
                      label: "Disetujui",
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _StatItem(
                      icon: LucideIcons.refreshCw,
                      value: _stats['recalled'].toString(),
                      label: "Ditolak",
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
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
                    onTap: () {
                      context.push('/supervisor/settings');
                    },
                  ),
                  _MenuItem(
                    icon: LucideIcons.helpCircle,
                    label: "Bantuan",
                    onTap: () {
                      context.push('/supervisor/help');
                    },
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
        Icon(icon, color: supervisorColor),
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
