import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                    ),
                    child: const Icon(LucideIcons.user, size: 48, color: AppTheme.primaryColor),
                  ),
                  const Gap(16),
                  const Text(
                    "Sulhan Fuadi",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Gap(4),
                  const Text(
                    "24060123130115",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle, size: 14, color: Colors.green),
                        Gap(4),
                        Text("Akun Terverifikasi", style: TextStyle(color: Colors.green, fontSize: 12)),
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
                  _InfoRow(icon: LucideIcons.mail, label: "Email", value: "sulhan.fuadi@students.undip.ac.id"),
                  const Divider(height: 24),
                  _InfoRow(icon: LucideIcons.hash, label: "NIM/NIP", value: "24060123130115"),
                  const Divider(height: 24),
                  _InfoRow(icon: LucideIcons.phone, label: "Nomor HP", value: "081234567890"),
                  const Divider(height: 24),
                  _InfoRow(icon: LucideIcons.mapPin, label: "Alamat", value: "Tembalang, Semarang"),
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
                      Icon(LucideIcons.alertCircle, color: Colors.red.shade700, size: 18),
                      const Gap(8),
                      Text(
                        'Kontak Darurat',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                  const Gap(12),
                  _InfoRow(icon: LucideIcons.userCircle, label: "Nama", value: "Budi Santoso"),
                  const Divider(height: 20),
                  _InfoRow(icon: LucideIcons.phoneCall, label: "Nomor HP", value: "081298765432"),
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
                  Expanded(child: _StatItem(icon: LucideIcons.fileText, value: "12", label: "Laporan")),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(child: _StatItem(icon: LucideIcons.checkCircle, value: "10", label: "Selesai")),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(child: _StatItem(icon: LucideIcons.clock, value: "2", label: "Proses")),
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
                  _MenuItem(icon: LucideIcons.edit, label: "Edit Profil", onTap: () => context.push('/edit-profile')),
                  _MenuItem(icon: LucideIcons.settings, label: "Pengaturan", onTap: () => context.push('/settings')),
                  _MenuItem(icon: LucideIcons.helpCircle, label: "Bantuan", onTap: () => context.push('/help')),
                  _MenuItem(icon: LucideIcons.logOut, label: "Keluar", onTap: () => context.go('/login'), isDestructive: true),
                ],
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

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
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const Gap(4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey.shade700),
      title: Text(label, style: TextStyle(color: isDestructive ? Colors.red : Colors.black)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: onTap,
    );
  }
}
