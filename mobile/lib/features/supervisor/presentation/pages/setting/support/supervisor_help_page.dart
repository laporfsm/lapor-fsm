import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/base_templates.dart';

class SupervisorHelpPage extends StatelessWidget {
  const SupervisorHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseHelpPage(
      title: 'Bantuan Supervisor',
      accentColor: AppTheme.supervisorColor,
      topics: [
        HelpTopic(
          icon: LucideIcons.users,
          title: 'Manajemen Staf',
          description:
              'Kelola data teknisi dan PJ Gedung. Anda bisa menambah, mengedit, atau menonaktifkan akun staf.',
        ),
        HelpTopic(
          icon: LucideIcons.barChart3,
          title: 'Analisis Statistik',
          description:
              'Pantau kinerja tim dan tren kerusakan fasilitas melalui dashboard statistik yang komprehensif.',
        ),
        HelpTopic(
          icon: LucideIcons.layoutGrid,
          title: 'Manajemen Kategori',
          description:
              'Atur kategori laporan dan assign penanggung jawab untuk setiap kategori agar koordinasi lebih efisien.',
        ),
        HelpTopic(
          icon: LucideIcons.fileSearch,
          title: 'Aktivitias & Log',
          description:
              'Lihat seluruh riwayat aktivitas dalam sistem untuk memantau alur kerja penanganan laporan.',
        ),
      ],
    );
  }
}
