import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_serice_method_channel.dart';
import 'src/models/location_data.dart';
import 'src/models/service_options.dart';
import 'src/models/service_status.dart';
import 'src/models/tracking_mode.dart';

abstract class LocationSericePlatform extends PlatformInterface {
  LocationSericePlatform() : super(token: _token);

  static final Object _token = Object();

  static LocationSericePlatform _instance = MethodChannelLocationSerice();

  static LocationSericePlatform get instance => _instance;

  static set instance(LocationSericePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<bool> startService({ServiceOptions options = const ServiceOptions()}) {
    throw UnimplementedError('startService() has not been implemented.');
  }

  Future<bool> stopService() {
    throw UnimplementedError('stopService() has not been implemented.');
  }

  Future<bool> restartService() {
    throw UnimplementedError('restartService() has not been implemented.');
  }

  Future<bool> updateInterval(int intervalSeconds) {
    throw UnimplementedError('updateInterval() has not been implemented.');
  }

  Future<bool> isServiceRunning() {
    throw UnimplementedError('isServiceRunning() has not been implemented.');
  }

  Future<bool> isGpsEnabled() {
    throw UnimplementedError('isGpsEnabled() has not been implemented.');
  }

  Future<bool> openLocationSettings() {
    throw UnimplementedError('openLocationSettings() has not been implemented.');
  }

  Future<LocationPermissionStatus> checkPermission() {
    throw UnimplementedError('checkPermission() has not been implemented.');
  }

  Future<LocationPermissionStatus> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 8),
  }) {
    throw UnimplementedError('getCurrentLocation() has not been implemented.');
  }

  Future<LocationData?> getLastKnownLocation() {
    throw UnimplementedError('getLastKnownLocation() has not been implemented.');
  }

  Stream<LocationData> get locationStream {
    throw UnimplementedError('locationStream has not been implemented.');
  }

  Stream<ServiceStatus> get serviceStatusStream {
    throw UnimplementedError('serviceStatusStream has not been implemented.');
  }
}
