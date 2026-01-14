import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bantuan'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.helpCircle, size: 40, color: Colors.white),
                  ),
                  const Gap(16),
                  const Text(
                    'Ada yang bisa kami bantu?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  const Text(
                    'Temukan jawaban atau hubungi tim kami',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Gap(24),

            // FAQ Section
            _buildSectionHeader('Pertanyaan Umum (FAQ)'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _FAQItem(
                    question: 'Bagaimana cara membuat laporan?',
                    answer: 'Tekan tombol "LAPOR DARURAT" untuk laporan darurat, atau pilih kategori di menu untuk laporan biasa. Isi formulir dan kirim laporan Anda.',
                  ),
                  const Divider(height: 1),
                  _FAQItem(
                    question: 'Berapa lama respon untuk laporan darurat?',
                    answer: 'Laporan darurat akan ditangani dalam waktu maksimal 30 menit. Tim darurat akan segera menghubungi Anda.',
                  ),
                  const Divider(height: 1),
                  _FAQItem(
                    question: 'Bagaimana cara melacak status laporan?',
                    answer: 'Buka menu "Aktivitas Saya" di bottom navigation untuk melihat daftar dan status semua laporan Anda.',
                  ),
                  const Divider(height: 1),
                  _FAQItem(
                    question: 'Apa itu laporan darurat?',
                    answer: 'Laporan darurat adalah untuk situasi yang membutuhkan penanganan segera seperti kebakaran, kebocoran gas, kecelakaan, atau ancaman keselamatan.',
                  ),
                  const Divider(height: 1),
                  _FAQItem(
                    question: 'Bisakah saya membatalkan laporan?',
                    answer: 'Laporan yang sudah dikirim tidak bisa dibatalkan. Namun, Anda bisa menghubungi tim untuk memberikan update.',
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Panduan Section
            _buildSectionHeader('Panduan Penggunaan'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.fileText, color: AppTheme.primaryColor),
                    ),
                    title: const Text('Cara Membuat Laporan'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => _showGuide(context, 'Cara Membuat Laporan', _reportGuide),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.siren, color: Colors.red),
                    ),
                    title: const Text('Kapan Gunakan Lapor Darurat'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => _showGuide(context, 'Laporan Darurat', _emergencyGuide),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.clock, color: Colors.orange),
                    ),
                    title: const Text('Status Laporan'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => _showGuide(context, 'Status Laporan', _statusGuide),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Kontak Section
            _buildSectionHeader('Hubungi Kami'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.phone, color: Colors.green),
                    ),
                    title: const Text('Telepon'),
                    subtitle: const Text('(024) 7474754'),
                    onTap: () => _launchUrl('tel:0247474754'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.messageCircle, color: Colors.green),
                    ),
                    title: const Text('WhatsApp'),
                    subtitle: const Text('0812-3456-7890'),
                    onTap: () => _launchUrl('https://wa.me/6281234567890'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.mail, color: Colors.blue),
                    ),
                    title: const Text('Email'),
                    subtitle: const Text('fsm@undip.ac.id'),
                    onTap: () => _launchUrl('mailto:fsm@undip.ac.id'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.globe, color: Colors.purple),
                    ),
                    title: const Text('Website'),
                    subtitle: const Text('fsm.undip.ac.id'),
                    onTap: () => _launchUrl('https://fsm.undip.ac.id'),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Emergency Contact
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.siren, color: Colors.white, size: 20),
                      ),
                      const Gap(12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kontak Darurat 24 Jam',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            Text(
                              'Untuk keadaan darurat dan mendesak',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl('tel:112'),
                          icon: const Icon(LucideIcons.phone, size: 16),
                          label: const Text('112'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl('tel:118'),
                          icon: const Icon(LucideIcons.heartPulse, size: 16),
                          label: const Text('118'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
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

  void _showGuide(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(20),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static const String _reportGuide = '''
1. PILIH JENIS LAPORAN
   • Laporan Darurat: Untuk situasi mendesak yang membutuhkan penanganan segera
   • Laporan Non-Darurat: Untuk kerusakan fasilitas biasa

2. ISI FORMULIR LAPORAN
   • Pilih kategori yang sesuai
   • Pilih lokasi gedung
   • Tambahkan foto bukti (opsional tapi disarankan)
   • Tulis deskripsi yang jelas

3. KIRIM LAPORAN
   • Pastikan semua data sudah benar
   • Tekan tombol "Kirim Laporan"
   • Tunggu konfirmasi dari sistem

4. PANTAU STATUS
   • Cek status laporan di menu "Aktivitas Saya"
   • Anda akan menerima notifikasi saat ada update
''';

  static const String _emergencyGuide = '''
GUNAKAN LAPORAN DARURAT UNTUK:
• Kebakaran atau asap mencurigakan
• Kebocoran gas atau bahan berbahaya
• Kecelakaan atau cedera
• Ancaman keselamatan
• Banjir atau genangan air berbahaya
• Listrik konslet/menyetrum
• Pohon tumbang

JANGAN GUNAKAN UNTUK:
• Kerusakan fasilitas biasa
• Kebersihan area
• Perawatan rutin
• Keluhan umum

PROSEDUR DARURAT:
1. Pastikan Anda dalam kondisi aman
2. Tekan tombol "LAPOR DARURAT"
3. Pilih jenis kejadian
4. Lokasi akan terdeteksi otomatis
5. Tambahkan foto jika memungkinkan
6. Kirim dan tunggu respon dalam 30 menit
''';

  static const String _statusGuide = '''
STATUS LAPORAN:

📝 PENDING (Menunggu)
   Laporan Anda sudah masuk dan menunggu ditinjau oleh tim.

🔍 VERIFIKASI
   Tim sedang memverifikasi laporan Anda.

⚙️ PENANGANAN
   Petugas sudah ditugaskan dan sedang menangani masalah.

✅ SELESAI
   Masalah telah ditangani. Anda akan diminta memberikan feedback.

❌ DITOLAK
   Laporan tidak dapat ditindaklanjuti. Lihat alasan penolakan di detail laporan.

TIMELINE:
• Laporan Darurat: Respon maks. 30 menit
• Laporan Biasa: Respon maks. 1x24 jam
• Penanganan tergantung tingkat kerusakan
''';
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            widget.question,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 20,
          ),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ),
      ],
    );
  }
}
