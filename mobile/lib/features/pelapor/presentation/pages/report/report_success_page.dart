import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class ReportSuccessPage extends StatelessWidget {
  const ReportSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCheck, size: 64, color: Colors.green),
              ),
              const Gap(24),
              const Text(
                "Laporan Terkirim!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Gap(12),
              const Text(
                "Terima kasih atas laporan Anda. Teknisi kami akan segera menangani masalah ini.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text("KEMBALI KE BERANDA"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
