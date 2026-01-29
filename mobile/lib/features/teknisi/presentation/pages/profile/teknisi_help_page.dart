import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/base_templates.dart';

class TeknisiHelpPage extends StatelessWidget {
  const TeknisiHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseHelpPage(
      title: 'Bantuan Teknisi',
      accentColor: AppTheme.teknisiColor,
      topics: [
        HelpTopic(
          icon: LucideIcons.clipboardList,
          title: 'Menerima Tugas',
          description:
              'Buka Dashboard dan pilih laporan dengan status "Siap Diproses". Tekan "Mulai Penanganan" untuk memulai pekerjaan.',
        ),
        HelpTopic(
          icon: LucideIcons.pauseCircle,
          title: 'Menunda Pekerjaan (On Hold)',
          description:
              'Jika butuh sparepart atau alat tambahan, tekan "Pause" dan masukkan alasan penundaan yang jelas.',
        ),
        HelpTopic(
          icon: LucideIcons.checkCircle2,
          title: 'Menyelesaikan Laporan',
          description:
              'Setelah perbaikan selesai, ambil foto bukti hasil pekerjaan dan berikan deskripsi penanganan sebelum menekan "Selesaikan".',
        ),
        HelpTopic(
          icon: LucideIcons.history,
          title: 'Riwayat Pekerjaan',
          description:
              'Anda dapat melihat semua laporan yang pernah Anda tangani di menu Riwayat pada Dashboard.',
        ),
      ],
    );
  }
}
