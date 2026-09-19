import 'dart:math' as math;

import 'location_service_platform_interface.dart';
import 'src/models/location_data.dart';
import 'src/models/service_options.dart';
import 'src/models/service_status.dart';
import 'src/models/tracking_mode.dart';

export 'src/models/location_data.dart';
export 'src/models/service_options.dart';
export 'src/models/service_status.dart';
export 'src/models/tracking_mode.dart';

/// Flutter API for Android Background Location Service.
class LocationService {
  const LocationService();

  static LocationServicePlatform get _platform => LocationServicePlatform.instance;

  /// Check platform version.
  static Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  /// Start foreground location service.
  ///
  /// [intervalSeconds] specifies how often (in seconds) the service fetches the location.
  /// [distanceFilterMeters] specifies the minimum movement in meters required to emit a location.
  /// [trackingMode] specifies filtering behavior (`time`, `distance`, or `timeOrDistance`).
  /// [accuracy] specifies location provider priority.
  static Future<bool> startService({
    int intervalSeconds = 5,
    double distanceFilterMeters = 0.0,
    TrackingMode trackingMode = TrackingMode.time,
    LocationAccuracy accuracy = LocationAccuracy.high,
    String notificationTitle = 'خدمة الموقع',
    String notificationText = 'جاري تتبع الموقع...',
    String stopButtonText = 'إيقاف',
    String restartButtonText = 'إعادة تشغيل',
    bool enableWakeLock = true,
    String? notificationIcon,
    ServiceOptions? options,
  }) {
    final effectiveOptions = options ??
        ServiceOptions(
          intervalSeconds: intervalSeconds,
          distanceFilterMeters: distanceFilterMeters,
          trackingMode: trackingMode,
          accuracy: accuracy,
          notificationTitle: notificationTitle,
          notificationText: notificationText,
          stopButtonText: stopButtonText,
          restartButtonText: restartButtonText,
          enableWakeLock: enableWakeLock,
          notificationIcon: notificationIcon,
        );
    return _platform.startService(options: effectiveOptions);
  }

  /// Stop foreground location service cleanly.
  static Future<bool> stopService() {
    return _platform.stopService();
  }

  /// Restart foreground location service cleanly from scratch.
  static Future<bool> restartService() {
    return _platform.restartService();
  }

  /// Dynamically update the location fetch interval while the service is running or stopped.
  static Future<bool> updateInterval(int intervalSeconds) {
    return _platform.updateInterval(intervalSeconds);
  }

  /// Check if the foreground location service is currently active.
  static Future<bool> isServiceRunning() {
    return _platform.isServiceRunning();
  }

  /// Check if GPS / location hardware is enabled on the device.
  static Future<bool> isGpsEnabled() {
    return _platform.isGpsEnabled();
  }

  /// Open device location settings screen.
  static Future<bool> openLocationSettings() {
    return _platform.openLocationSettings();
  }

  /// Check current location and notification permissions.
  static Future<LocationPermissionStatus> checkPermission() {
    return _platform.checkPermission();
  }

  /// Request runtime location and notification permissions.
  static Future<LocationPermissionStatus> requestPermission() {
    return _platform.requestPermission();
  }

  /// Fetch single-fix current location on-demand.
  static Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 8),
  }) {
    return _platform.getCurrentLocation(
      accuracy: accuracy,
      timeout: timeout,
    );
  }

  /// Fetch last known device position immediately without turning on sensors.
  static Future<LocationData?> getLastKnownLocation() {
    return _platform.getLastKnownLocation();
  }

  /// Calculate distance in meters between two geographic points using Haversine formula.
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((endLatitude - startLatitude) * p) / 2 +
        math.cos(startLatitude * p) *
            math.cos(endLatitude * p) *
            (1 - math.cos((endLongitude - startLongitude) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a)); // 2 * R * 1000 in meters
  }

  /// Stream of location updates emitted periodically by the background service.
  static Stream<LocationData> get onLocationChanged => _platform.locationStream;

  /// Stream of service status updates (e.g. running state changes).
  static Stream<ServiceStatus> get onServiceStatusChanged => _platform.serviceStatusStream;

  // Instance wrappers for flexibility
  Future<String?> platformVersion() => getPlatformVersion();
  Future<bool> start({
    int intervalSeconds = 5,
    double distanceFilterMeters = 0.0,
    TrackingMode trackingMode = TrackingMode.time,
    LocationAccuracy accuracy = LocationAccuracy.high,
    String notificationTitle = 'Location Service',
    String notificationText = 'Tracking location...',
    String stopButtonText = 'Stop',
    String restartButtonText = 'Restart',
    bool enableWakeLock = true,
    String? notificationIcon,
    ServiceOptions? options,
  }) =>
      startService(
        intervalSeconds: intervalSeconds,
        distanceFilterMeters: distanceFilterMeters,
        trackingMode: trackingMode,
        accuracy: accuracy,
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        stopButtonText: stopButtonText,
        restartButtonText: restartButtonText,
        enableWakeLock: enableWakeLock,
        notificationIcon: notificationIcon,
        options: options,
      );
  Future<bool> stop() => stopService();
  Future<bool> restart() => restartService();
  Future<bool> setInterval(int seconds) => updateInterval(seconds);
  Future<bool> isRunning() => isServiceRunning();

  Future<LocationData?> currentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 8),
  }) =>
      getCurrentLocation(accuracy: accuracy, timeout: timeout);

  Future<LocationData?> lastKnownLocation() => getLastKnownLocation();

  Stream<LocationData> get locationStream => onLocationChanged;
  Stream<ServiceStatus> get serviceStatusStream => onServiceStatusChanged;
}
