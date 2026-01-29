import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Gap(16),
            SettingsSection(
              title: 'Akun',
              children: [
                SettingsTile(
                  icon: LucideIcons.user,
                  title: 'Edit Profil',
                  onTap: () =>
                      _showSnackBar('Fitur Edit Profil akan segera hadir!'),
                ),
                SettingsTile(
                  icon: LucideIcons.lock,
                  title: 'Ubah Password',
                  onTap: () =>
                      _showSnackBar('Fitur Ubah Password akan segera hadir!'),
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Sistem',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Notifikasi',
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                  activeColor: AppTheme.adminColor,
                ),
                SettingsTile(
                  icon: LucideIcons.monitor,
                  title: 'Tampilan (Dark Mode)',
                  subtitle: 'Fitur belum tersedia',
                  onTap: () =>
                      _showSnackBar('Mode gelap sedang dalam pengembangan'),
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Tentang',
              children: [
                const SettingsTile(
                  icon: LucideIcons.info,
                  title: 'Versi Aplikasi',
                  subtitle: '1.0.0 (Build 100)',
                  trailing: SizedBox.shrink(),
                ),
                SettingsTile(
                  icon: LucideIcons.fileText,
                  title: 'Ketentuan Layanan',
                  onTap: () => _showSnackBar('Membuka Ketentuan Layanan...'),
                ),
              ],
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
