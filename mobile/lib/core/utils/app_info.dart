import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static Future<PackageInfo>? _cachedInfo;

  static Future<PackageInfo> get platformInfo {
    _cachedInfo ??= PackageInfo.fromPlatform();
    return _cachedInfo!;
  }

  static Future<String> versionLabel({bool includeBuild = true}) async {
    final info = await platformInfo;
    final version = info.version;
    final build = info.buildNumber;

    if (!includeBuild || build.isEmpty) {
      return version;
    }

    return '$version (Build $build)';
  }

  static Future<String> fullVersion() async {
    final info = await platformInfo;
    if (info.buildNumber.isEmpty) return info.version;
    return '${info.version}+${info.buildNumber}';
  }
}
