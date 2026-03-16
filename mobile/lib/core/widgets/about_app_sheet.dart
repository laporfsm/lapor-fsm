import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/app_update_checker.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/app_version_widgets.dart';

void showAboutAppSheet(BuildContext context, {Color? accentColor}) {
  final rootContext = context;
  final color = accentColor ?? AppTheme.primaryColor;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.megaphone,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const Gap(16),
          const Text(
            'Lapor FSM!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          AppVersionText(style: TextStyle(color: Colors.grey.shade500)),
          const Gap(12),
          Text(
            'Aplikasi pelaporan fasilitas\nFakultas Sains dan Matematika UNDIP',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const Gap(20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                AppUpdateChecker.checkForUpdate(rootContext);
              },
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Cek Update'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    ),
  );
}
