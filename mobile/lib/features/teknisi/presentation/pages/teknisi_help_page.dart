import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TeknisiHelpPage extends StatelessWidget {
  const TeknisiHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bantuan'),
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
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Cari bantuan...',
                  border: InputBorder.none,
                  icon: Icon(LucideIcons.search, color: Colors.grey),
                ),
              ),
            ),
            const Gap(24),

            // FAQ Section
            _buildSectionHeader('Pertanyaan Umum'),
            _buildFaqItem(
              'Bagaimana cara mulai menangani laporan?',
              'Buka detail laporan, lalu klik tombol "Verifikasi & Tangani". Laporan akan pindah ke tab "Aktif".',
            ),
            _buildFaqItem(
              'Bagaimana jika saya berhalangan hadir?',
              'Silakan hubungi supervisor Anda segera atau gunakan fitur "Alihkan Tugas" jika tersedia.',
            ),
            _buildFaqItem(
              'Cara upload foto bukti penyelesaian?',
              'Saat menyelesaikan laporan, Anda akan diminta untuk mengambil atau mengunggah foto sebagai bukti pekerjaan.',
            ),
            const Gap(24),

            // Contact Support
            _buildSectionHeader('Hubungi Kami'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildContactItem(
                    icon: LucideIcons.phone,
                    title: 'Call Center',
                    subtitle: '021-1234567',
                    onTap: () => _launchUrl('tel:0211234567'),
                  ),
                  const Divider(height: 1),
                  _buildContactItem(
                    icon: LucideIcons.mail,
                    title: 'Email Support',
                    subtitle: 'support@lapor-fsm.com',
                    onTap: () => _launchUrl('mailto:support@lapor-fsm.com'),
                  ),
                  const Divider(height: 1),
                  _buildContactItem(
                    icon: LucideIcons.messageSquare,
                    title: 'WhatsApp Supervisor',
                    subtitle: '+62 812-3456-7890',
                    onTap: () => _launchUrl('https://wa.me/6281234567890'),
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
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.secondaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }
}
