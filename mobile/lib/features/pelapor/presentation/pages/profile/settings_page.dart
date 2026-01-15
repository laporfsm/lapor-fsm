import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  String _selectedLanguage = 'Indonesia';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),

            // Notifikasi Section
            _buildSectionHeader('Notifikasi'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Aktifkan Notifikasi'),
                    subtitle: const Text('Terima pembaruan tentang laporan Anda'),
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                    secondary: const Icon(LucideIcons.bell),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifikasi Email'),
                    subtitle: const Text('Kirim update ke email'),
                    value: _emailNotifications,
                    onChanged: _notificationsEnabled 
                        ? (value) => setState(() => _emailNotifications = value) 
                        : null,
                    secondary: const Icon(LucideIcons.mail),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Push Notification'),
                    subtitle: const Text('Notifikasi di perangkat'),
                    value: _pushNotifications,
                    onChanged: _notificationsEnabled 
                        ? (value) => setState(() => _pushNotifications = value) 
                        : null,
                    secondary: const Icon(LucideIcons.smartphone),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Suara Notifikasi'),
                    subtitle: const Text('Aktifkan suara saat notifikasi'),
                    value: _soundEnabled,
                    onChanged: _notificationsEnabled 
                        ? (value) => setState(() => _soundEnabled = value) 
                        : null,
                    secondary: const Icon(LucideIcons.volume2),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Tampilan Section
            _buildSectionHeader('Tampilan'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.globe),
                    title: const Text('Bahasa'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => _showLanguageDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.palette),
                    title: const Text('Tema'),
                    subtitle: const Text('Terang'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tema lainnya akan segera hadir!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Privasi Section
            _buildSectionHeader('Privasi & Keamanan'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.shield),
                    title: const Text('Kebijakan Privasi'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      _showInfoDialog('Kebijakan Privasi', 
                        'Data Anda dilindungi sesuai dengan kebijakan privasi Universitas Diponegoro. '
                        'Informasi yang Anda berikan hanya digunakan untuk keperluan pelaporan fasilitas.');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.fileText),
                    title: const Text('Syarat & Ketentuan'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      _showInfoDialog('Syarat & Ketentuan', 
                        'Dengan menggunakan aplikasi ini, Anda setuju untuk menggunakan layanan secara bertanggung jawab. '
                        'Laporan palsu dapat dikenakan sanksi sesuai peraturan universitas.');
                    },
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Tentang Section
            _buildSectionHeader('Tentang'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.info),
                    title: const Text('Versi Aplikasi'),
                    subtitle: const Text('1.0.0 (Build 1)'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.code),
                    title: const Text('Pengembang'),
                    subtitle: const Text('Tim Lapor FSM - FSM Undip'),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Danger Zone
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Hapus semua data akun Anda', style: TextStyle(fontSize: 12)),
                trailing: const Icon(LucideIcons.chevronRight, color: Colors.red),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Indonesia'),
            _buildLanguageOption('English'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language 
          ? const Icon(LucideIcons.check, color: AppTheme.primaryColor) 
          : null,
      onTap: () {
        setState(() => _selectedLanguage = language);
        Navigator.pop(context);
      },
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
          'Tindakan ini akan menghapus semua data akun Anda secara permanen. '
          'Laporan yang sudah dibuat tidak akan dapat dikembalikan.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
