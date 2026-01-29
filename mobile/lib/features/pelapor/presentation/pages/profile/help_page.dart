import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/widgets/base_templates.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseHelpPage(
      title: 'Bantuan Pelapor',
      topics: [
        HelpTopic(
          icon: LucideIcons.filePlus,
          title: 'Cara Membuat Laporan',
          description:
              'Pilih kategori masalah, tentukan lokasi gedung, tambahkan foto, dan tulis deskripsi singkat. Tekan "Kirim" untuk memproses.',
        ),
        HelpTopic(
          icon: LucideIcons.siren,
          title: 'Kapan Menggunakan Lapor Darurat?',
          description:
              'Gunakan tombol Lapor Darurat hanya untuk situasi mendesak seperti kebakaran, kecelakaan, atau ancaman keselamatan.',
        ),
        HelpTopic(
          icon: LucideIcons.clock,
          title: 'Berapa Lama Respon Tim?',
          description:
              'Laporan darurat akan ditangani maks 30 menit. Laporan rutin akan ditinjau dalam 1x24 jam hari kerja.',
        ),
        HelpTopic(
          icon: LucideIcons.activity,
          title: 'Memantau Status Laporan',
          description:
              'Buka menu Aktivitas Saya untuk melihat perkembangan status laporan Anda dari Pending hingga Selesai.',
        ),
        HelpTopic(
          icon: LucideIcons.phoneCall,
          title: 'Hubungi Call Center',
          description:
              'Jika butuh bantuan mendesak lainnya, hubungi (024) 7474754 atau email fsm@undip.ac.id.',
        ),
      ],
    );
  }
}
