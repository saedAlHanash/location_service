enum TrackingMode {
  time,
  distance,
  timeOrDistance;

  String get nameString {
    switch (this) {
      case TrackingMode.time:
        return 'time';
      case TrackingMode.distance:
        return 'distance';
      case TrackingMode.timeOrDistance:
        return 'timeOrDistance';
    }
  }

  static TrackingMode fromString(String? value) {
    switch (value) {
      case 'distance':
        return TrackingMode.distance;
      case 'timeOrDistance':
        return TrackingMode.timeOrDistance;
      case 'time':
      default:
        return TrackingMode.time;
    }
  }
}

enum LocationAccuracy {
  high,
  balanced,
  low,
  passive;

  String get nameString => name;

  static LocationAccuracy fromString(String? value) {
    switch (value) {
      case 'balanced':
        return LocationAccuracy.balanced;
      case 'low':
        return LocationAccuracy.low;
      case 'passive':
        return LocationAccuracy.passive;
      case 'high':
      default:
        return LocationAccuracy.high;
    }
  }
}
