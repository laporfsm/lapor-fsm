import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class PJGedungSettingsPage extends StatefulWidget {
  const PJGedungSettingsPage({super.key});

  @override
  State<PJGedungSettingsPage> createState() => _PJGedungSettingsPageState();
}

class _PJGedungSettingsPageState extends State<PJGedungSettingsPage> {
  bool _notificationsEnabled = true;

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
              title: 'Notifikasi',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Notifikasi Laporan',
                  subtitle: 'Terima info laporan baru di gedung Anda',
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                  activeColor: AppTheme.pjGedungColor,
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Aplikasi',
              children: [
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
                  title: 'Versi Aplikasi',
                  subtitle: '1.0.0',
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
