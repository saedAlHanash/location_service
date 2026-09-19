class ServiceStatus {
  final bool isRunning;
  final String status;

  const ServiceStatus({
    required this.isRunning,
    required this.status,
  });

  factory ServiceStatus.fromMap(Map<dynamic, dynamic> map) {
    return ServiceStatus(
      isRunning: map['isRunning'] as bool? ?? false,
      status: map['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isRunning': isRunning,
      'status': status,
    };
  }

  @override
  String toString() => 'ServiceStatus(isRunning: $isRunning, status: $status)';
}

enum LocationPermissionStatus {
  granted,
  denied,
  notificationDenied,
  unknown;

  bool get isGranted => this == LocationPermissionStatus.granted;
  bool get isDenied => this == LocationPermissionStatus.denied;
  bool get isNotificationDenied => this == LocationPermissionStatus.notificationDenied;

  static LocationPermissionStatus fromString(String? value) {
    switch (value) {
      case 'granted':
        return LocationPermissionStatus.granted;
      case 'notification_denied':
        return LocationPermissionStatus.notificationDenied;
      case 'denied':
        return LocationPermissionStatus.denied;
      default:
        return LocationPermissionStatus.unknown;
    }
  }
}
