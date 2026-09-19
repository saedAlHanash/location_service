import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location_service/location_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Service Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LocationServiceDemoPage(),
    );
  }
}

class LocationServiceDemoPage extends StatefulWidget {
  const LocationServiceDemoPage({super.key});

  @override
  State<LocationServiceDemoPage> createState() => _LocationServiceDemoPageState();
}

class _LocationServiceDemoPageState extends State<LocationServiceDemoPage> {
  bool _isServiceRunning = false;
  bool _isGpsEnabled = false;
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;
  LocationData? _latestLocation;
  int _updateCount = 0;
  int _intervalSeconds = 5;

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<ServiceStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
    _subscribeToStreams();
  }

  Future<void> _checkInitialState() async {
    final running = await LocationService.isServiceRunning();
    final gps = await LocationService.isGpsEnabled();
    final perm = await LocationService.checkPermission();

    if (!mounted) return;
    setState(() {
      _isServiceRunning = running;
      _isGpsEnabled = gps;
      _permissionStatus = perm;
    });
  }

  void _subscribeToStreams() {
    _locationSubscription = LocationService.onLocationChanged.listen((data) {
      if (!mounted) return;
      setState(() {
        _latestLocation = data;
        _updateCount++;
      });
    });

    _statusSubscription = LocationService.onServiceStatusChanged.listen((status) {
      if (!mounted) return;
      setState(() {
        _isServiceRunning = status.isRunning;
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final status = await LocationService.requestPermission();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> _toggleService() async {
    if (_isServiceRunning) {
      await LocationService.stopService();
      if (!mounted) return;
      setState(() {
        _isServiceRunning = false;
      });
    } else {
      if (_permissionStatus != LocationPermissionStatus.granted) {
        await _requestPermissions();
        if (_permissionStatus != LocationPermissionStatus.granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى منح الصلاحيات أولاً تشغيل الخدمة')),
          );
          return;
        }
      }

      final success = await LocationService.startService(
        intervalSeconds: _intervalSeconds,
        notificationTitle: 'تتبع الموقع بالخلفية',
        notificationText: 'الخدمة نشطة وتجلب الموقع دورياً',
        stopButtonText: 'إيقاف الخدمة',
        enableWakeLock: true,
      );

      if (!mounted) return;
      if (success) {
        setState(() {
          _isServiceRunning = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Location Service'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkInitialState,
            tooltip: 'تحديث الحالة',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Service Status Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'حالة الخدمة',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isServiceRunning ? Colors.green.shade700 : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _isServiceRunning ? 'قيد التشغيل (Running)' : 'متوقفة (Stopped)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نظام GPS:'),
                      Text(
                        _isGpsEnabled ? 'مفعّل ✅' : 'معطّل ❌',
                        style: TextStyle(
                          color: _isGpsEnabled ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('حالة الصلاحيات:'),
                      Text(
                        _permissionStatus.name,
                        style: TextStyle(
                          color: _permissionStatus == LocationPermissionStatus.granted
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _requestPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('طلب الصلاحيات'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => LocationService.openLocationSettings(),
                          icon: const Icon(Icons.location_searching),
                          label: const Text('إعدادات الموقع'),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Controls Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التحكم بالمؤقت والخدمة',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('معدل الجلب الدوري (Timer):'),
                      Text(
                        '$_intervalSeconds ثوانٍ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _intervalSeconds.toDouble(),
                    min: 2,
                    max: 60,
                    divisions: 29,
                    label: '$_intervalSeconds ثانية',
                    onChanged: (val) {
                      final newSec = val.round();
                      setState(() {
                        _intervalSeconds = newSec;
                      });
                      if (_isServiceRunning) {
                        LocationService.updateInterval(newSec);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isServiceRunning ? Colors.red : colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _toggleService,
                      icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        _isServiceRunning ? 'إيقاف الخدمة (Stop Service)' : 'تشغيل الخدمة (Start Service)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_isServiceRunning) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade800,
                          side: BorderSide(color: Colors.amber.shade800),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await LocationService.restartService();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('تمت إعادة تشغيل الخدمة من الصفر')),
                          );
                        },

                        icon: const Icon(Icons.restart_alt),
                        label: const Text('إعادة تشغيل الخدمة (Restart Service)'),
                      ),
                    ),
                  ],

                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Location Live Metrics Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'آخر موقع مستلم',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'تحديثات: $_updateCount',
                        style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_latestLocation == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'بانتظار استلام أول إحداثيات...\n(شغّل الخدمة لرؤية التحديثات المباشرة)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else ...[
                    _buildMetricRow('خط العرض (Latitude):', '${_latestLocation!.latitude}'),
                    _buildMetricRow('خط الطول (Longitude):', '${_latestLocation!.longitude}'),
                    _buildMetricRow('الدقة (Accuracy):', '${_latestLocation!.accuracy.toStringAsFixed(1)} m'),
                    _buildMetricRow('الارتفاع (Altitude):', '${_latestLocation!.altitude.toStringAsFixed(1)} m'),
                    _buildMetricRow('السرعة (Speed):', '${_latestLocation!.speed.toStringAsFixed(2)} m/s'),
                    _buildMetricRow('الوقت (Timestamp):', _latestLocation!.dateTime.toLocal().toString().split('.').first),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
