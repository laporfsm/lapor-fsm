import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class SupervisorHelpPage extends StatelessWidget {
  const SupervisorHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bantuan'),
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
          children: [
            // Search Help
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Cari topik bantuan...',
                  border: InputBorder.none,
                  icon: Icon(LucideIcons.search, color: Colors.grey),
                ),
              ),
            ),
            const Gap(24),

            // FAQ Section
            _buildSectionTitle('Sering Ditanyakan'),
            const Gap(12),
            _buildFAQItem(
              'Bagaimana cara menambah teknisi?',
              'Anda dapat menambah teknisi melalui menu "Teknisi" di tab manajemen staff, lalu tekan tombol tambah (+).',
            ),
            const Gap(12),
            _buildFAQItem(
              'Bagaimana memverifikasi laporan?',
              'Buka detail laporan yang perlu diverifikasi, lalu tekan tombol "Setujui" atau "Tolak" di bagian bawah halaman.',
            ),
            const Gap(12),
            _buildFAQItem(
              'Apa itu fitur Export?',
              'Fitur Export memungkinkan Anda mengunduh rekap laporan dalam format PDF atau Excel untuk keperluan administrasi.',
            ),

            const Gap(24),
            _buildSectionTitle('Hubungi Kami'),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildContactItem(
                    LucideIcons.phone,
                    'Hubungi Admin Pusat',
                    '024-1234567',
                  ),
                  const Divider(),
                  _buildContactItem(
                    LucideIcons.mail,
                    'Email Support',
                    'helpdesk@fsm.undip.ac.id',
                  ),
                  const Divider(),
                  _buildContactItem(
                    LucideIcons.messageCircle,
                    'WhatsApp Center',
                    '0812-3456-7890',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.supervisorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.supervisorColor, size: 20),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
