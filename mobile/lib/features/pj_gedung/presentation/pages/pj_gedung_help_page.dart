import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/base_templates.dart';

class PJGedungHelpPage extends StatelessWidget {
  const PJGedungHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseHelpPage(
      title: 'Bantuan PJ Lokasi',
      accentColor: AppTheme.pjLokasiColor,
      topics: [
        HelpTopic(
          icon: LucideIcons.mapPin,
          title: 'Pemantauan Lokasi',
          description:
              'Pantau laporan yang masuk khusus untuk lokasi yang Anda kelola. Pastikan setiap masalah segera diverifikasi.',
        ),
        HelpTopic(
          icon: LucideIcons.checkSquare,
          title: 'Verifikasi Laporan',
          description:
              'Lakukan pengecekan fisik ke lokasi dan berikan verifikasi apakah laporan tersebut valid untuk ditindaklanjuti.',
        ),
        HelpTopic(
          icon: LucideIcons.barChart,
          title: 'Statistik Lokasi',
          description:
              'Lihat tren kerusakan dan performa penanganan masalah di lokasi Anda melalui dashboard statistik.',
        ),
        HelpTopic(
          icon: LucideIcons.messageSquare,
          title: 'Koordinasi dengan Supervisor',
          description:
              'Jika ada masalah skala besar, segera koordinasikan dengan Supervisor melalui fitur yang tersedia.',
        ),
      ],
    );
  }
}
