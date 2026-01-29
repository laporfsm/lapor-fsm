import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              title: 'Akun',
              children: [
                _buildSettingItem(
                  icon: LucideIcons.user,
                  title: 'Edit Profil',
                  onTap: () {}, // Todo: Edit Profile
                ),
                _buildSettingItem(
                  icon: LucideIcons.lock,
                  title: 'Ubah Password',
                  onTap: () {}, // Todo: Change Password Dialog
                ),
              ],
            ),
            const Gap(24),
            _buildSection(
              title: 'Sistem',
              children: [
                _buildSettingItem(
                  icon: LucideIcons.bell,
                  title: 'Notifikasi',
                  hasSwitch: true,
                  switchValue: true,
                  onChanged: (val) {},
                ),
                _buildSettingItem(
                  icon: LucideIcons.monitor,
                  title: 'Tampilan (Dark Mode)',
                  subtitle: 'Fitur belum tersedia',
                  onTap: () {},
                ),
              ],
            ),
            const Gap(24),
            _buildSection(
              title: 'Tentang',
              children: [
                _buildSettingItem(
                  icon: LucideIcons.info,
                  title: 'Versi Aplikasi',
                  subtitle: '1.0.0 (Build 100)',
                  onTap: null,
                ),
                _buildSettingItem(
                  icon: LucideIcons.fileText,
                  title: 'Ketentuan Layanan',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final isLast = index == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
            )
          : (onTap != null
                ? const Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: Colors.grey,
                  )
                : null),
      onTap: hasSwitch ? null : onTap,
    );
  }
}
