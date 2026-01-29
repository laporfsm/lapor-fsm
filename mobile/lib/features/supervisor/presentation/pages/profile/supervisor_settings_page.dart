import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class SupervisorSettingsPage extends StatefulWidget {
  const SupervisorSettingsPage({super.key});

  @override
  State<SupervisorSettingsPage> createState() => _SupervisorSettingsPageState();
}

class _SupervisorSettingsPageState extends State<SupervisorSettingsPage> {
  bool _emailNotification = true;
  bool _pushNotification = true;
  bool _darkMode = false;

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
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Gap(16),
            SettingsSection(
              title: 'Notifikasi',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.mail,
                  title: 'Notifikasi Email',
                  subtitle: 'Terima pembaruan via email',
                  value: _emailNotification,
                  onChanged: (val) => setState(() => _emailNotification = val),
                  activeColor: AppTheme.supervisorColor,
                ),
                SettingsSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Push Notification',
                  subtitle: 'Notifikasi di aplikasi',
                  value: _pushNotification,
                  onChanged: (val) => setState(() => _pushNotification = val),
                  activeColor: AppTheme.supervisorColor,
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Sistem',
              children: [
                SettingsTile(
                  icon: LucideIcons.tags,
                  title: 'Kelola Kategori',
                  onTap: () => context.push('/supervisor/categories'),
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Tampilan',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.moon,
                  title: 'Mode Gelap',
                  subtitle: 'Sesuaikan tema aplikasi',
                  value: _darkMode,
                  onChanged: (val) => setState(() => _darkMode = val),
                  activeColor: AppTheme.supervisorColor,
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Keamanan',
              children: [
                SettingsTile(
                  icon: LucideIcons.lock,
                  title: 'Ubah Password',
                  onTap: () =>
                      _showSnackBar('Fitur Ubah Password belum tersedia'),
                ),
              ],
            ),
            const Gap(24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showSnackBar('Cache berhasil dibersihkan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Hapus Cache Aplikasi'),
                ),
              ),
            ),
            const Gap(16),
            Text(
              'Versi Aplikasi 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
