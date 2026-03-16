class AppVersionInfo {
  final String latestVersion;
  final String minVersion;
  final String? androidUrl;
  final String? iosUrl;
  final String? webUrl;
  final String? message;
  final String? releaseNotes;
  final String? updatedAt;

  const AppVersionInfo({
    required this.latestVersion,
    required this.minVersion,
    this.androidUrl,
    this.iosUrl,
    this.webUrl,
    this.message,
    this.releaseNotes,
    this.updatedAt,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latestVersion']?.toString() ?? '0.0.0',
      minVersion: json['minVersion']?.toString() ?? '0.0.0',
      androidUrl: json['androidUrl']?.toString(),
      iosUrl: json['iosUrl']?.toString(),
      webUrl: json['webUrl']?.toString(),
      message: json['message']?.toString(),
      releaseNotes: json['releaseNotes']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
