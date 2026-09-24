import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/location_service.dart';
import 'package:location_service/location_service_platform_interface.dart';
import 'package:location_service/location_service_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocationServicePlatform
    with MockPlatformInterfaceMixin
    implements LocationServicePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> startService({ServiceOptions options = const ServiceOptions()}) =>
      Future.value(true);

  @override
  Future<bool> stopService() => Future.value(true);

  @override
  Future<bool> restartService() => Future.value(true);

  @override
  Future<bool> updateInterval(int intervalSeconds) => Future.value(true);

  @override
  Future<bool> isServiceRunning() => Future.value(false);


  @override
  Future<bool> isGpsEnabled() => Future.value(true);

  @override
  Future<bool> openLocationSettings() => Future.value(true);

  @override
  Future<LocationPermissionStatus> checkPermission() =>
      Future.value(LocationPermissionStatus.granted);

  @override
  Future<LocationPermissionStatus> requestPermission() =>
      Future.value(LocationPermissionStatus.granted);

  @override
  Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 8),
  }) =>
      Future.value(null);

  @override
  Future<LocationData?> getLastKnownLocation() => Future.value(null);

  @override
  Stream<LocationData> get locationStream => const Stream.empty();

  @override
  Stream<LocationData> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int intervalMillis = 1000,
    int minUpdateIntervalMillis = 500,
    double distanceFilterMeters = 0.0,
  }) =>
      const Stream.empty();

  @override
  Stream<ServiceStatus> get serviceStatusStream => const Stream.empty();
}

void main() {
  final LocationServicePlatform initialPlatform = LocationServicePlatform.instance;

  test('$MethodChannelLocationService is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLocationService>());
  });

  test('getPlatformVersion', () async {
    MockLocationServicePlatform fakePlatform = MockLocationServicePlatform();
    LocationServicePlatform.instance = fakePlatform;

    expect(await LocationService.getPlatformVersion(), '42');
  });

  test('startService and stopService', () async {
    MockLocationServicePlatform fakePlatform = MockLocationServicePlatform();
    LocationServicePlatform.instance = fakePlatform;

    expect(await LocationService.startService(), true);
    expect(await LocationService.restartService(), true);
    expect(await LocationService.updateInterval(10), true);
    expect(await LocationService.stopService(), true);
  });
}

