# location_serice

إضافة (Plugin) لتتبع الموقع في الخلفية على أندرويد عبر **Foreground Service** مع مؤقت دوري (Timer) وإشعار تفاعلي مباشر مع إمكانية الإيقاف النظيف.

## الميزات (Key Features)

- **Foreground Service متوافقة مع Android 14+**: تعتمد `foregroundServiceType="location"`.
- **مؤقت دوري (Periodic Timer Single-Fix)**: لا تفتح stream دائم على حساس الـ GPS؛ بل تجلب الموقع كـ single-shot fix كل فترة زمنية محددة (افتراضياً 5 ثوانٍ) لمنع تعليق الحساس وتوفير الطاقة.
- **إشعار تفاعلي ديناميكي (Dynamic Notification)**:
  - يعرض حالة الخدمة الحالية.
  - يعرض آخر إحداثيات مستلمة (Lat, Lng, Accuracy) ووقت الاستلام بالثانية.
  - زر إيقاف (Stop Action Button) داخل الإشعار لإيقاف الخدمة فوراً بنظافة وبلا كراش، مع إشعار تطبيق Flutter بالتوقف لحظياً.
- **API بسيط وسهل التضمين**: دوال `static` خفيفة للتشغيل والإيقاف وفحص الصلاحيات وفتح الإعدادات والاستماع للبيانات.

---

## إعدادات الأندرويد (Android Setup)

أضف الصلاحيات التالية في `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

---

## طريقة الاستخدام في فلاتر (Usage)

### 1. طلب الصلاحيات وفحص الـ GPS:
```dart
import 'package:location_serice/location_serice.dart';

// طلب الصلاحيات (الموقع + الإشعارات)
final permission = await LocationSerice.requestPermission();
if (permission == LocationPermissionStatus.granted) {
  // الصلاحيات ممنوحة
}

// فحص تفعيل الـ GPS
final isGpsOn = await LocationSerice.isGpsEnabled();
if (!isGpsOn) {
  await LocationSerice.openLocationSettings();
}
```

### 2. تشغيل الخدمة بالخلفية:
```dart
await LocationSerice.startService(
  intervalSeconds: 5, // جلب الموقع كل 5 ثوانٍ (قابل للتعديل بأي وقت)
  notificationTitle: 'تتبع الموقع',
  notificationText: 'جاري تتبع الموقع في الخلفية...',
  stopButtonText: 'إيقاف',
  restartButtonText: 'إعادة تشغيل',
  enableWakeLock: true,
);
```

### 3. تعديل المؤقت لحظياً أثناء عمل الخدمة (Dynamic Interval):
```dart
// تغيير فترة الجلب في أي وقت (مثلاً كل 10 ثوانٍ) دون الحاجة لإعادة التشغيل
await LocationSerice.updateInterval(10);
```

### 4. إعادة تشغيل الخدمة بالكامل من الصفر (Restart Service):
```dart
// إطفاء الخدمة بالكامل من جذورها وإعادة بنائها من الصفر بنظافة
await LocationSerice.restartService();
```

### 5. إيقاف الخدمة:
```dart
await LocationSerice.stopService();
```

### 6. الاستماع للمواقع وحالة الخدمة لحظياً:

```dart
// الاستماع لتحديثات الموقع
LocationSerice.onLocationChanged.listen((LocationData location) {
  print('Latitude: ${location.latitude}, Longitude: ${location.longitude}');
  print('Time: ${location.dateTime}');
});

// الاستماع لحالة تشغيل الخدمة (مثلاً عند إيقافها من زر الإشعار)
LocationSerice.onServiceStatusChanged.listen((ServiceStatus status) {
  print('Is Running: ${status.isRunning}');
});
```
