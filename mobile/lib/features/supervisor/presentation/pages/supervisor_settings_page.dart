import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

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
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notifikasi'),
            const Gap(8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Notifikasi Email'),
                    subtitle: const Text('Terima pembaruan via email'),
                    value: _emailNotification,
                    onChanged: (val) =>
                        setState(() => _emailNotification = val),
                    secondary: const Icon(
                      LucideIcons.mail,
                      color: AppTheme.primaryColor,
                    ),
                    activeColor: AppTheme.supervisorColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Push Notification'),
                    subtitle: const Text('Notifikasi di aplikasi'),
                    value: _pushNotification,
                    onChanged: (val) => setState(() => _pushNotification = val),
                    secondary: const Icon(
                      LucideIcons.bell,
                      color: AppTheme.primaryColor,
                    ),
                    activeColor: AppTheme.supervisorColor,
                  ),
                ],
              ),
            ),
            const Gap(24),
            _buildSectionHeader('Tampilan'),
            const Gap(8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Mode Gelap'),
                subtitle: const Text('Sesuaikan tema aplikasi'),
                value: _darkMode,
                onChanged: (val) => setState(() => _darkMode = val),
                secondary: const Icon(
                  LucideIcons.moon,
                  color: AppTheme.primaryColor,
                ),
                activeColor: AppTheme.supervisorColor,
              ),
            ),
            const Gap(24),
            _buildSectionHeader('Keamanan'),
            const Gap(8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  LucideIcons.lock,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Ubah Password'),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {
                  // TODO: Navigate to change password page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur Ubah Password belum tersedia'),
                    ),
                  );
                },
              ),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Clear cache logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache berhasil dibersihkan')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Hapus Cache Aplikasi'),
              ),
            ),
            const Gap(8),
            Center(
              child: Text(
                'Versi Aplikasi 1.0.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
