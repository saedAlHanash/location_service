import 'package:flutter_test/flutter_test.dart';
import 'package:location_serice/location_serice.dart';
import 'package:location_serice/location_serice_platform_interface.dart';
import 'package:location_serice/location_serice_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocationSericePlatform
    with MockPlatformInterfaceMixin
    implements LocationSericePlatform {
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
  Stream<ServiceStatus> get serviceStatusStream => const Stream.empty();
}

void main() {
  final LocationSericePlatform initialPlatform = LocationSericePlatform.instance;

  test('$MethodChannelLocationSerice is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLocationSerice>());
  });

  test('getPlatformVersion', () async {
    MockLocationSericePlatform fakePlatform = MockLocationSericePlatform();
    LocationSericePlatform.instance = fakePlatform;

    expect(await LocationSerice.getPlatformVersion(), '42');
  });

  test('startService and stopService', () async {
    MockLocationSericePlatform fakePlatform = MockLocationSericePlatform();
    LocationSericePlatform.instance = fakePlatform;

    expect(await LocationSerice.startService(), true);
    expect(await LocationSerice.restartService(), true);
    expect(await LocationSerice.updateInterval(10), true);
    expect(await LocationSerice.stopService(), true);
  });
}

