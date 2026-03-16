import 'package:pub_semver/pub_semver.dart';

class VersionUtils {
  static Version? parseVersion(String value) {
    try {
      return Version.parse(value);
    } catch (_) {
      return null;
    }
  }

  static bool isZeroVersion(String value) {
    return value.trim() == '0.0.0';
  }

  static int compare(String a, String b) {
    final versionA = parseVersion(a);
    final versionB = parseVersion(b);

    if (versionA == null || versionB == null) {
      return 0;
    }

    return versionA.compareTo(versionB);
  }
}
