import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _pushNotifications = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
                  title: 'Aktifkan Notifikasi',
                  subtitle: 'Terima pembaruan tentang laporan Anda',
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                  activeColor: AppTheme.primaryColor,
                ),
                SettingsSwitchTile(
                  icon: LucideIcons.smartphone,
                  title: 'Push Notification',
                  subtitle: 'Notifikasi di perangkat',
                  value: _pushNotifications,
                  onChanged: _notificationsEnabled
                      ? (value) => setState(() => _pushNotifications = value)
                      : null,
                  activeColor: AppTheme.primaryColor,
                ),
                SettingsSwitchTile(
                  icon: LucideIcons.volume2,
                  title: 'Suara Notifikasi',
                  subtitle: 'Aktifkan suara saat notifikasi',
                  value: _soundEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) => setState(() => _soundEnabled = value)
                      : null,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
              title: 'Tampilan',
              children: [
                SettingsTile(
                  icon: LucideIcons.globe,
                  title: 'Bahasa',
                  subtitle: 'Indonesia',
                  trailing: _buildLabel('Segera Hadir', Colors.orange),
                  onTap: () =>
                      _showSnackBar('Fitur multi-bahasa akan segera hadir!'),
                ),
                SettingsTile(
                  icon: LucideIcons.palette,
                  title: 'Tema',
                  subtitle: 'Terang',
                  onTap: () => _showSnackBar('Tema lainnya akan segera hadir!'),
                ),
              ],
            ),
            const Gap(24),
            SettingsSection(
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
            SettingsSection(
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
            SettingsSection(
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
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
