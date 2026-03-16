import 'package:flutter/material.dart';
import 'package:mobile/core/services/app_update_checker.dart';
import 'package:mobile/core/services/app_version_service.dart';
import 'package:mobile/core/utils/app_info.dart';
import 'package:mobile/core/utils/update_requirement.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionGuard extends StatefulWidget {
  final Widget child;

  const VersionGuard({super.key, required this.child});

  @override
  State<VersionGuard> createState() => _VersionGuardState();
}

class _VersionGuardState extends State<VersionGuard>
    with WidgetsBindingObserver {
  static const _lastPromptedVersionKey = 'last_prompted_version';
  static const _lastPromptedAtKey = 'last_prompted_at';
  static const _optionalPromptCooldown = Duration(hours: 24);

  bool _isChecking = false;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleCheck();
    }
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (_isChecking || _dialogShowing) return;
    _isChecking = true;

    try {
      final info = await AppVersionService().fetchVersionInfo();
      if (!mounted || info == null) return;

      final currentVersion = await AppInfo.fullVersion();
      final requirement =
          AppUpdateChecker.evaluateRequirement(info, currentVersion);
      if (requirement == UpdateRequirement.none) return;

      if (requirement == UpdateRequirement.optional &&
          await _shouldSkipOptionalPrompt(info.latestVersion)) {
        return;
      }

      if (!mounted) return;
      _dialogShowing = true;
      await AppUpdateChecker.showUpdateDialog(
        context,
        info,
        currentVersion,
        requirement,
      );
      if (requirement == UpdateRequirement.optional) {
        await _markOptionalPrompt(info.latestVersion);
      }
    } finally {
      _dialogShowing = false;
      _isChecking = false;
    }
  }

  Future<bool> _shouldSkipOptionalPrompt(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final lastVersion = prefs.getString(_lastPromptedVersionKey);
    final lastPromptedAtMs = prefs.getInt(_lastPromptedAtKey) ?? 0;
    if (lastVersion != latestVersion || lastPromptedAtMs == 0) {
      return false;
    }

    final lastPromptedAt =
        DateTime.fromMillisecondsSinceEpoch(lastPromptedAtMs);
    return DateTime.now().difference(lastPromptedAt) <
        _optionalPromptCooldown;
  }

  Future<void> _markOptionalPrompt(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPromptedVersionKey, latestVersion);
    await prefs.setInt(
      _lastPromptedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
