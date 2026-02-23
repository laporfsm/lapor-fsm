import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/profile_widgets.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class SupervisorAccountSettingsPage extends StatefulWidget {
  const SupervisorAccountSettingsPage({super.key});

  @override
  State<SupervisorAccountSettingsPage> createState() =>
      _SupervisorAccountSettingsPageState();
}

class _SupervisorAccountSettingsPageState
    extends State<SupervisorAccountSettingsPage> {
  bool _pushNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Preferensi & Notifikasi'),
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
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
                    subtitle: 'Notifikasi di aplikasi',
                    value: _pushNotification,
                    onChanged: (val) => setState(() => _pushNotification = val),
                    activeColor: AppTheme.supervisorColor,
                  ),
                ],
              ),
              const Gap(24),
              ProfileSection(
                title: 'Privasi & Keamanan',
                children: [
                  SettingsTile(
                    icon: LucideIcons.shield,
                    title: 'Kebijakan Privasi',
                    onTap: () => _showInfoDialog(
                      'Kebijakan Privasi',
                      'Data Anda dilindungi sesuai dengan kebijakan privasi Universitas Diponegoro. Informasi yang Anda berikan hanya digunakan untuk keperluan pelaporan fasilitas.',
                    ),
                  ),
                  SettingsTile(
                    icon: LucideIcons.fileText,
                    title: 'Syarat & Ketentuan',
                    onTap: () => _showInfoDialog(
                      'Syarat & Ketentuan',
                      'Dengan menggunakan aplikasi ini, Anda setuju untuk menggunakan layanan secara bertanggung jawab. Laporan palsu dapat dikenakan sanksi sesuai peraturan universitas.',
                    ),
                  ),
                ],
              ),
              const Gap(24),
              ProfileSection(
                title: 'Tentang',
                children: [
                  const SettingsTile(
                    icon: LucideIcons.info,
                    title: 'Versi Aplikasi',
                    subtitle: '1.0.0 (Build 1)',
                    trailing: SizedBox.shrink(),
                  ),
                  const SettingsTile(
                    icon: LucideIcons.code,
                    title: 'Pengembang',
                    subtitle: 'Tim Lapor FSM - FSM Undip',
                    trailing: SizedBox.shrink(),
                  ),
                ],
              ),
              const Gap(24),
              ProfileSection(
                title: 'Zona Berbahaya',
                children: [
                  SettingsTile(
                    icon: LucideIcons.trash2,
                    title: 'Hapus Akun',
                    iconColor: Colors.red,
                    onTap: () => _showDeleteAccountDialog(),
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

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text(
          'Tindakan ini akan menghapus semua data akun Anda secara permanen. Laporan yang sudah dibuat tidak akan dapat dikembalikan.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
