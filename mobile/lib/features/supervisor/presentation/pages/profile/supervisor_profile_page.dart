import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';

class SupervisorProfilePage extends StatelessWidget {
  const SupervisorProfilePage({super.key});

  Map<String, dynamic> get _profile => {
    'name': 'Dr. Ahmad Supervisor',
    'nip': '197001012000011001',
    'email': 'ahmad.supervisor@undip.ac.id',
    'phone': '08123456789',
    'department': 'UP2TI FSM Undip',
    'position': 'Kepala Unit',
  };

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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.supervisorColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.supervisorColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      size: 48,
                      color: AppTheme.supervisorColor,
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
                      color: AppTheme.supervisorColor.withValues(alpha: 0.1),
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
                          icon: LucideIcons.building,
                          label: "Departemen",
                          value: _profile['department'],
                        ),
                        const Divider(height: 24),
                        ProfileInfoRow(
                          icon: LucideIcons.briefcase,
                          label: "Jabatan",
                          value: _profile['position'],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileSection(
                children: [
                  ProfileMenuItem(
                    icon: LucideIcons.settings,
                    label: "Pengaturan",
                    onTap: () => context.push('/supervisor/settings'),
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
        Icon(icon, color: AppTheme.supervisorColor),
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
