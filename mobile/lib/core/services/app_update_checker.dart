import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/models/app_version_info.dart';
import 'package:mobile/core/services/app_version_service.dart';
import 'package:mobile/core/utils/app_info.dart';
import 'package:mobile/core/utils/update_requirement.dart';
import 'package:mobile/core/utils/version_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateChecker {
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool showUpToDateDialog = true,
  }) async {
    final info = await AppVersionService().fetchVersionInfo();
    if (info == null) {
      if (context.mounted) {
        _showSnackBar(context, 'Gagal memeriksa update. Coba lagi.');
      }
      return;
    }

    final currentVersion = await AppInfo.fullVersion();
    final requirement = evaluateRequirement(info, currentVersion);

    if (requirement == UpdateRequirement.none) {
      if (showUpToDateDialog && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Versi Terbaru',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('Versi terpasang: $currentVersion'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await showUpdateDialog(context, info, currentVersion, requirement);
  }

  static UpdateRequirement evaluateRequirement(
    AppVersionInfo info,
    String currentVersion,
  ) {
    if (VersionUtils.isZeroVersion(info.latestVersion) &&
        VersionUtils.isZeroVersion(info.minVersion)) {
      return UpdateRequirement.none;
    }

    final minCompare =
        VersionUtils.compare(currentVersion, info.minVersion);
    if (minCompare < 0) {
      return UpdateRequirement.required;
    }

    final latestCompare =
        VersionUtils.compare(currentVersion, info.latestVersion);
    if (latestCompare < 0) {
      return UpdateRequirement.optional;
    }

    return UpdateRequirement.none;
  }

  static Future<void> showUpdateDialog(
    BuildContext context,
    AppVersionInfo info,
    String currentVersion,
    UpdateRequirement requirement,
  ) async {
    final isRequired = requirement == UpdateRequirement.required;
    final updateUrl = _resolveUpdateUrl(info);

    return showDialog<void>(
      context: context,
      barrierDismissible: !isRequired,
      builder: (context) => AlertDialog(
        title: Text(
          isRequired ? 'Update Wajib' : 'Update Tersedia',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.message ??
                  (isRequired
                      ? 'Versi aplikasi Anda sudah tidak didukung. Silakan update untuk melanjutkan.'
                      : 'Ada versi terbaru aplikasi. Update untuk pengalaman terbaik.'),
            ),
            const SizedBox(height: 12),
            Text('Versi terpasang: $currentVersion'),
            Text('Versi terbaru: ${info.latestVersion}'),
            if (info.releaseNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                info.releaseNotes!,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
            if (updateUrl == null) ...[
              const SizedBox(height: 12),
              const Text(
                'Link update belum tersedia. Hubungi admin.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          if (!isRequired)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
          ElevatedButton(
            onPressed: updateUrl == null
                ? null
                : () async {
                    await _launchUpdateUrl(updateUrl);
                    if (!isRequired && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: Text(isRequired ? 'Update Sekarang' : 'Update'),
          ),
          if (isRequired &&
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android)
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Keluar'),
            ),
        ],
      ),
    );
  }

  static String? _resolveUpdateUrl(AppVersionInfo info) {
    if (kIsWeb) return info.webUrl ?? info.androidUrl ?? info.iosUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return info.androidUrl ?? info.webUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return info.iosUrl ?? info.webUrl;
    }
    return info.webUrl;
  }

  static Future<void> _launchUpdateUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
