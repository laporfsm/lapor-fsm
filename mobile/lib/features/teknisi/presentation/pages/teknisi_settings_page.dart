import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Account Section
            _buildSectionHeader('Akun'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: LucideIcons.user,
                    title: 'Profil Saya',
                    onTap: () {}, // TODO: Navigate to Edit Profile
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: LucideIcons.lock,
                    title: 'Ubah Kata Sandi',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Notifications Section
            _buildSectionHeader('Notifikasi'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    title: 'Push Notification',
                    value: _pushNotifications,
                    onChanged: (val) =>
                        setState(() => _pushNotifications = val),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // App Section
            _buildSectionHeader('Aplikasi'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    title: 'Mode Gelap',
                    value: _darkMode,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: LucideIcons.languages,
                    title: 'Bahasa',
                    subtitle: 'Indonesia',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: LucideIcons.info,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Versi 1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.secondaryColor,
    );
  }
}
