import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/base_templates.dart';

class AdminHelpPage extends StatelessWidget {
  const AdminHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseHelpPage(
      title: 'Bantuan Admin',
      accentColor: AppTheme.adminColor,
      topics: [
        HelpTopic(
          icon: LucideIcons.database,
          title: 'Master Data',
          description:
              'Kelola data master aplikasi seperti data gedung, FAQ, dan parameter sistem lainnya.',
        ),
        HelpTopic(
          icon: LucideIcons.userPlus,
          title: 'Registrasi User',
          description:
              'Verifikasi dan kelola pendaftaran user baru baik pelapor maupun staf internal.',
        ),
        HelpTopic(
          icon: LucideIcons.shieldAlert,
          title: 'Keamanan & Akses',
          description:
              'Pantau akses sistem dan tangani masalah keamanan atau penyalahgunaan akun jika ditemukan.',
        ),
        HelpTopic(
          icon: LucideIcons.settings,
          title: 'Konfigurasi Aplikasi',
          description:
              'Atur konfigurasi sistem, maintenance mode, dan update metadata aplikasi secara terpusat.',
        ),
      ],
    );
  }
}
