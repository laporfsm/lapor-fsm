import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class AdminHelpPage extends StatelessWidget {
  const AdminHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bantuan & Dukungan'),
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
            _buildFAQItem(
              'Bagaimana cara memverifikasi user?',
              'Buka menu Verifikasi di tab bawah. User yang mendaftar akan muncul di sana. Klik tombol "Verifikasi" untuk mengaktifkan akun mereka.',
            ),
            const Gap(16),
            _buildFAQItem(
              'Bagaimana cara menonaktifkan akun yang melanggar?',
              'Cari user tersebut di menu Direktori (atau search), buka profilnya, dan tekan tombol "Nonaktifkan Akun" (warna merah).',
            ),
            const Gap(16),
            _buildFAQItem(
              'Apa itu PJ Gedung?',
              'PJ Gedung adalah staff yang bertanggung jawab memvalidasi laporan yang masuk untuk gedung tertentu sebelum diteruskan ke teknisi.',
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Contact developer logic
                },
                icon: const Icon(LucideIcons.messageCircle),
                label: const Text('Hubungi Developer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.helpCircle,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            answer,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}
