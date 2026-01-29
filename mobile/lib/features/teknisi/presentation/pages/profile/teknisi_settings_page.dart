import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class TeknisiSettingsPage extends StatefulWidget {
  const TeknisiSettingsPage({super.key});

  @override
  State<TeknisiSettingsPage> createState() => _TeknisiSettingsPageState();
}

class _TeknisiSettingsPageState extends State<TeknisiSettingsPage> {
  bool _pushNotifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
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
                  title: 'Profil Saya',
                  onTap: () => context.push('/teknisi/edit-profile'),
                ),
                SettingsTile(
                  icon: LucideIcons.lock,
                  title: 'Ubah Kata Sandi',
                  onTap: () =>
                      _showSnackBar('Fitur ubah kata sandi akan segera hadir!'),
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Notifikasi',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Push Notification',
                  subtitle: 'Terima pemberitahuan tugas baru',
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                  activeColor: AppTheme.teknisiColor,
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Aplikasi',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.moon,
                  title: 'Mode Gelap',
                  value: _darkMode,
                  onChanged: (val) => setState(() => _darkMode = val),
                  activeColor: AppTheme.teknisiColor,
                ),
                SettingsTile(
                  icon: LucideIcons.languages,
                  title: 'Bahasa',
                  subtitle: 'Indonesia',
                  onTap: () => _showSnackBar(
                    'Pilihan bahasa lainnya akan segera hadir!',
                  ),
                ),
                const SettingsTile(
                  icon: LucideIcons.info,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Versi 1.0.0',
                  trailing: SizedBox.shrink(),
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
