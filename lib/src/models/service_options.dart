import 'tracking_mode.dart';

class ServiceOptions {
  final int intervalSeconds;
  final double distanceFilterMeters;
  final TrackingMode trackingMode;
  final LocationAccuracy accuracy;
  final String notificationTitle;
  final String notificationText;
  final String stopButtonText;
  final String restartButtonText;
  final bool enableWakeLock;
  final String? notificationIcon;

  const ServiceOptions({
    this.intervalSeconds = 5,
    this.distanceFilterMeters = 0.0,
    this.trackingMode = TrackingMode.time,
    this.accuracy = LocationAccuracy.high,
    this.notificationTitle = 'خدمة الموقع',
    this.notificationText = 'جاري تتبع الموقع...',
    this.stopButtonText = 'إيقاف',
    this.restartButtonText = 'إعادة تشغيل',
    this.enableWakeLock = true,
    this.notificationIcon,
  });

  Map<String, dynamic> toMap() {
    return {
      'intervalSeconds': intervalSeconds,
      'distanceFilterMeters': distanceFilterMeters,
      'trackingMode': trackingMode.nameString,
      'accuracy': accuracy.nameString,
      'notificationTitle': notificationTitle,
      'notificationText': notificationText,
      'stopButtonText': stopButtonText,
      'restartButtonText': restartButtonText,
      'enableWakeLock': enableWakeLock,
      if (notificationIcon != null) 'notificationIcon': notificationIcon,
    };
  }

  factory ServiceOptions.fromMap(Map<dynamic, dynamic> map) {
    return ServiceOptions(
      intervalSeconds: (map['intervalSeconds'] as num?)?.toInt() ?? 5,
      distanceFilterMeters: (map['distanceFilterMeters'] as num?)?.toDouble() ?? 0.0,
      trackingMode: TrackingMode.fromString(map['trackingMode'] as String?),
      accuracy: LocationAccuracy.fromString(map['accuracy'] as String?),
      notificationTitle: map['notificationTitle'] as String? ?? 'خدمة الموقع',
      notificationText: map['notificationText'] as String? ?? 'جاري تتبع الموقع...',
      stopButtonText: map['stopButtonText'] as String? ?? 'إيقاف',
      restartButtonText: map['restartButtonText'] as String? ?? 'إعادة تشغيل',
      enableWakeLock: map['enableWakeLock'] as bool? ?? true,
      notificationIcon: map['notificationIcon'] as String?,
    );
  }

  ServiceOptions copyWith({
    int? intervalSeconds,
    double? distanceFilterMeters,
    TrackingMode? trackingMode,
    LocationAccuracy? accuracy,
    String? notificationTitle,
    String? notificationText,
    String? stopButtonText,
    String? restartButtonText,
    bool? enableWakeLock,
    String? notificationIcon,
  }) {
    return ServiceOptions(
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      distanceFilterMeters: distanceFilterMeters ?? this.distanceFilterMeters,
      trackingMode: trackingMode ?? this.trackingMode,
      accuracy: accuracy ?? this.accuracy,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationText: notificationText ?? this.notificationText,
      stopButtonText: stopButtonText ?? this.stopButtonText,
      restartButtonText: restartButtonText ?? this.restartButtonText,
      enableWakeLock: enableWakeLock ?? this.enableWakeLock,
      notificationIcon: notificationIcon ?? this.notificationIcon,
    );
  }
}
