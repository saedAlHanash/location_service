import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'location_serice_platform_interface.dart';
import 'src/models/location_data.dart';
import 'src/models/service_options.dart';
import 'src/models/service_status.dart';
import 'src/models/tracking_mode.dart';

/// An implementation of [LocationSericePlatform] that uses method channels.
class MethodChannelLocationSerice extends LocationSericePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('location_serice');

  final _locationEventChannel = const EventChannel('location_serice/updates');
  final _statusEventChannel = const EventChannel('location_serice/status');

  Stream<LocationData>? _locationStream;
  Stream<ServiceStatus>? _statusStream;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> startService({ServiceOptions options = const ServiceOptions()}) async {
    final result = await methodChannel.invokeMethod<bool>(
      'startService',
      options.toMap(),
    );
    return result ?? false;
  }

  @override
  Future<bool> stopService() async {
    final result = await methodChannel.invokeMethod<bool>('stopService');
    return result ?? false;
  }

  @override
  Future<bool> restartService() async {
    final result = await methodChannel.invokeMethod<bool>('restartService');
    return result ?? false;
  }

  @override
  Future<bool> updateInterval(int intervalSeconds) async {
    final result = await methodChannel.invokeMethod<bool>(
      'updateInterval',
      {'intervalSeconds': intervalSeconds},
    );
    return result ?? false;
  }

  @override
  Future<bool> isServiceRunning() async {
    final result = await methodChannel.invokeMethod<bool>('isServiceRunning');
    return result ?? false;
  }

  @override
  Future<bool> isGpsEnabled() async {
    final result = await methodChannel.invokeMethod<bool>('isGpsEnabled');
    return result ?? false;
  }

  @override
  Future<bool> openLocationSettings() async {
    final result = await methodChannel.invokeMethod<bool>('openLocationSettings');
    return result ?? false;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final result = await methodChannel.invokeMethod<String>('checkPermission');
    return LocationPermissionStatus.fromString(result);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final result = await methodChannel.invokeMethod<String>('requestPermission');
    return LocationPermissionStatus.fromString(result);
  }

  @override
  Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getCurrentLocation',
        {
          'accuracy': accuracy.nameString,
          'timeoutMillis': timeout.inMilliseconds,
        },
      );
      if (result != null) {
        return LocationData.fromJson(result);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LocationData?> getLastKnownLocation() async {
    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>('getLastKnownLocation');
      if (result != null) {
        return LocationData.fromJson(result);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LocationData> get locationStream {
    _locationStream ??= _locationEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => LocationData.fromJson(Map<dynamic, dynamic>.from(event)))
        .asBroadcastStream();
    return _locationStream!;
  }

  @override
  Stream<ServiceStatus> get serviceStatusStream {
    _statusStream ??= _statusEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => ServiceStatus.fromMap(Map<dynamic, dynamic>.from(event)))
        .asBroadcastStream();
    return _statusStream!;
  }
}
