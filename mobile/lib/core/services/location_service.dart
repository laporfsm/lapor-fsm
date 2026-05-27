import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  bool get isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> isLocationServiceEnabled() async {
    if (!isMobilePlatform) return true;
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    if (!isMobilePlatform) return LocationPermission.always;
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    if (!isMobilePlatform) return LocationPermission.always;
    return Geolocator.requestPermission();
  }

  bool isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Check and request location permissions
  Future<bool> handleLocationPermission() async {
    if (!isMobilePlatform) return true;

    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    var permission = await checkPermission();
    if (!isPermissionGranted(permission)) {
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }
      if (!isPermissionGranted(permission)) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }
}

final locationService = LocationService();
