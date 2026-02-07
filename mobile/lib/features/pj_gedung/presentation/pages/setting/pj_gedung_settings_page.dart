import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';

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
        backgroundColor: AppTheme.pjGedungColor,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Gap(16),
            ProfileSection(
              title: 'Notifikasi',
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Notifikasi Laporan',
                  subtitle: 'Terima info laporan baru di lokasi Anda',
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                  activeColor: AppTheme.pjGedungColor,
                ),
              ],
            ),
            const Gap(24),
            ProfileSection(
              title: 'Aplikasi',
              children: [
                SettingsTile(
                  icon: LucideIcons.trash2,
                  title: 'Hapus Cache Aplikasi',
                  subtitle: 'Selesaikan masalah sinkronisasi data',
                  onTap: () => _showSnackBar('Cache berhasil dibersihkan'),
                  iconColor: Colors.red,
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
