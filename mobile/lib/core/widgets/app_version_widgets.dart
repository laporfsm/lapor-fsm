import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/utils/app_info.dart';
import 'package:mobile/core/widgets/settings_widgets.dart';

class AppVersionText extends StatelessWidget {
  final TextStyle? style;
  final bool includeBuild;

  const AppVersionText({
    super.key,
    this.style,
    this.includeBuild = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppInfo.versionLabel(includeBuild: includeBuild),
      builder: (context, snapshot) {
        final text = snapshot.data ?? 'Memuat versi...';
        return Text(text, style: style);
      },
    );
  }
}

class AppVersionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool includeBuild;

  const AppVersionTile({
    super.key,
    this.icon = LucideIcons.info,
    this.title = 'Versi Aplikasi',
    this.includeBuild = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppInfo.versionLabel(includeBuild: includeBuild),
      builder: (context, snapshot) {
        final subtitle = snapshot.data ?? 'Memuat versi...';
        return SettingsTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: const SizedBox.shrink(),
        );
      },
    );
  }
}
