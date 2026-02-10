import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class TeknisiSettingsPage extends StatefulWidget {
  const TeknisiSettingsPage({super.key});

  @override
  State<TeknisiSettingsPage> createState() => _TeknisiSettingsPageState();
}

class _TeknisiSettingsPageState extends State<TeknisiSettingsPage> {
  bool _pushNotifications = true;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ProfileSection(
                title: 'Notifikasi',
                children: [
                  SettingsSwitchTile(
                    icon: LucideIcons.bell,
                    title: 'Push Notification',
                    subtitle: 'Terima pemberitahuan tugas baru',
                    value: _pushNotifications,
                    onChanged: (val) =>
                        setState(() => _pushNotifications = val),
                    activeColor: AppTheme.teknisiColor,
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
              const Gap(40),
            ],
          ),
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
