import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/location_service.dart';

class GpsAccessGuard extends StatefulWidget {
  final Widget child;

  const GpsAccessGuard({super.key, required this.child});

  @override
  State<GpsAccessGuard> createState() => _GpsAccessGuardState();
}

class _GpsAccessGuardState extends State<GpsAccessGuard>
    with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _serviceEnabled = false;
  bool _permissionGranted = false;
  bool _permissionDeniedForever = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus(requestPermission: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus({bool requestPermission = false}) async {
    if (!locationService.isMobilePlatform) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _serviceEnabled = true;
          _permissionGranted = true;
          _permissionDeniedForever = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isChecking = true);

    final serviceEnabled = await locationService.isLocationServiceEnabled();
    var permission = await locationService.checkPermission();

    if (requestPermission &&
        permission == LocationPermission.denied &&
        serviceEnabled) {
      permission = await locationService.requestPermission();
    }

    if (!mounted) return;
    setState(() {
      _serviceEnabled = serviceEnabled;
      _permissionGranted = locationService.isPermissionGranted(permission);
      _permissionDeniedForever =
          permission == LocationPermission.deniedForever;
      _isChecking = false;
    });
  }

  bool get _isReady => _serviceEnabled && _permissionGranted;

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isReady) {
      return widget.child;
    }

    final message = !_serviceEnabled
        ? 'GPS perangkat Anda belum aktif. Aktifkan GPS untuk melanjutkan penggunaan aplikasi.'
        : _permissionDeniedForever
        ? 'Izin lokasi ditolak permanen. Buka pengaturan aplikasi lalu izinkan akses lokasi.'
        : 'Aplikasi memerlukan izin lokasi untuk membuat dan memproses laporan.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.mapPin,
                      size: 36,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aktifkan GPS Dulu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!_serviceEnabled) {
                          await locationService.openLocationSettings();
                        } else {
                          await locationService.openAppSettings();
                        }
                        if (!mounted) return;
                        await _refreshStatus();
                      },
                      icon: const Icon(LucideIcons.settings),
                      label: Text(
                        !_serviceEnabled
                            ? 'Buka Pengaturan Lokasi'
                            : 'Buka Pengaturan Aplikasi',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _refreshStatus(requestPermission: true),
                      child: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
