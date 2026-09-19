package com.example.location_service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class LocationForegroundService : Service() {

    companion object {
        const val ACTION_START = "com.example.location_service.ACTION_START"
        const val ACTION_STOP = "com.example.location_service.ACTION_STOP"
        const val ACTION_RESTART = "com.example.location_service.ACTION_RESTART"
        const val ACTION_UPDATE_INTERVAL = "com.example.location_service.ACTION_UPDATE_INTERVAL"

        const val EXTRA_INTERVAL_SECONDS = "interval_seconds"
        const val EXTRA_DISTANCE_FILTER_METERS = "distance_filter_meters"
        const val EXTRA_TRACKING_MODE = "tracking_mode"
        const val EXTRA_ACCURACY = "accuracy"
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_TEXT = "notification_text"
        const val EXTRA_STOP_BUTTON_TEXT = "stop_button_text"
        const val EXTRA_RESTART_BUTTON_TEXT = "restart_button_text"
        const val EXTRA_ENABLE_WAKELOCK = "enable_wakelock"
        const val EXTRA_NOTIFICATION_ICON = "notification_icon"

        const val CHANNEL_ID = "location_service_channel"
        const val NOTIFICATION_ID = 1001

        var isRunning: Boolean = false
            private set

        var currentIntervalSeconds: Int = 5
            private set

        var locationListener: ((Map<String, Any>) -> Unit)? = null
        var statusListener: ((Boolean, String) -> Unit)? = null

        fun stop(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun restart(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java).apply {
                action = ACTION_RESTART
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun updateInterval(context: Context, intervalSeconds: Int) {
            val intent = Intent(context, LocationForegroundService::class.java).apply {
                action = ACTION_UPDATE_INTERVAL
                putExtra(EXTRA_INTERVAL_SECONDS, intervalSeconds)
            }
            context.startService(intent)
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var notificationManager: NotificationManager
    private var wakeLock: PowerManager.WakeLock? = null

    private val handler = Handler(Looper.getMainLooper())
    private var locationRunnable: Runnable? = null
    private var cancellationTokenSource: CancellationTokenSource? = null

    private var intervalMillis: Long = 5000L
    private var distanceFilterMeters: Double = 0.0
    private var trackingMode: String = "time"
    private var accuracy: String = "high"
    private var notificationTitle: String = "خدمة الموقع"
    private var notificationText: String = "جاري تتبع الموقع..."
    private var stopButtonText: String = "إيقاف"
    private var restartButtonText: String = "إعادة تشغيل"
    private var enableWakeLock: Boolean = true
    private var notificationIconName: String? = null

    private var lastEmittedLocation: Location? = null
    private var lastEmittedTimeMillis: Long = 0L

    private var lastLocationInfo: String = "جاري التهيئة..."
    private val timeFormatter = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        when (action) {
            ACTION_STOP -> {
                stopLocationService()
                return START_NOT_STICKY
            }

            ACTION_UPDATE_INTERVAL -> {
                val newInterval = intent?.getIntExtra(EXTRA_INTERVAL_SECONDS, currentIntervalSeconds) ?: currentIntervalSeconds
                applyNewInterval(newInterval)
                return START_STICKY
            }

            ACTION_RESTART -> {
                restartLocationService()
                return START_STICKY
            }

            ACTION_START -> {
                val intervalSec = intent?.getIntExtra(EXTRA_INTERVAL_SECONDS, 5) ?: 5
                currentIntervalSeconds = if (intervalSec < 1) 1 else intervalSec
                intervalMillis = currentIntervalSeconds * 1000L

                distanceFilterMeters = intent?.getDoubleExtra(EXTRA_DISTANCE_FILTER_METERS, 0.0) ?: 0.0
                trackingMode = intent?.getStringExtra(EXTRA_TRACKING_MODE) ?: "time"
                accuracy = intent?.getStringExtra(EXTRA_ACCURACY) ?: "high"
                notificationTitle = intent?.getStringExtra(EXTRA_NOTIFICATION_TITLE) ?: "خدمة الموقع"
                notificationText = intent?.getStringExtra(EXTRA_NOTIFICATION_TEXT) ?: "جاري تتبع الموقع..."
                stopButtonText = intent?.getStringExtra(EXTRA_STOP_BUTTON_TEXT) ?: "إيقاف"
                restartButtonText = intent?.getStringExtra(EXTRA_RESTART_BUTTON_TEXT) ?: "إعادة تشغيل"
                enableWakeLock = intent?.getBooleanExtra(EXTRA_ENABLE_WAKELOCK, true) ?: true
                notificationIconName = intent?.getStringExtra(EXTRA_NOTIFICATION_ICON)

                lastEmittedLocation = null
                lastEmittedTimeMillis = 0L

                startForegroundServiceProperly()
                setupWakeLock()
                startPeriodicLocationFetch()
            }
        }

        return START_STICKY
    }

    private fun startForegroundServiceProperly() {
        val notification = buildNotification(lastLocationInfo)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isRunning = true
        statusListener?.invoke(true, "Service started")
    }

    private fun restartLocationService() {
        locationRunnable?.let { handler.removeCallbacks(it) }
        locationRunnable = null

        cancellationTokenSource?.cancel()
        cancellationTokenSource = null

        releaseWakeLock()

        lastEmittedLocation = null
        lastEmittedTimeMillis = 0L

        lastLocationInfo = "تمت إعادة التشغيل - جاري جلب الموقع..."
        updateNotification(lastLocationInfo)
        statusListener?.invoke(true, "Service restarted")

        setupWakeLock()
        startPeriodicLocationFetch()
    }

    private fun applyNewInterval(newIntervalSec: Int) {
        currentIntervalSeconds = if (newIntervalSec < 1) 1 else newIntervalSec
        intervalMillis = currentIntervalSeconds * 1000L

        if (isRunning) {
            startPeriodicLocationFetch()
            updateNotification("$lastLocationInfo (مؤقت: ${currentIntervalSeconds}ث)")
            statusListener?.invoke(true, "Interval updated to ${currentIntervalSeconds}s")
        }
    }

    private fun setupWakeLock() {
        if (!enableWakeLock) return
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "LocationForegroundService::WakeLock"
            ).apply {
                setReferenceCounted(false)
            }
        }
        if (wakeLock?.isHeld == false) {
            wakeLock?.acquire(24 * 60 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        wakeLock = null
    }

    private fun startPeriodicLocationFetch() {
        locationRunnable?.let { handler.removeCallbacks(it) }

        locationRunnable = object : Runnable {
            override fun run() {
                fetchCurrentLocation()
                handler.postDelayed(this, intervalMillis)
            }
        }

        fetchCurrentLocation()
        handler.postDelayed(locationRunnable!!, intervalMillis)
    }

    private fun getPriorityCode(): Int {
        return when (accuracy.lowercase()) {
            "balanced" -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
            "low" -> Priority.PRIORITY_LOW_POWER
            "passive" -> Priority.PRIORITY_PASSIVE
            "high" -> Priority.PRIORITY_HIGH_ACCURACY
            else -> Priority.PRIORITY_HIGH_ACCURACY
        }
    }

    private fun fetchCurrentLocation() {
        val hasFine = ActivityCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ActivityCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasFine && !hasCoarse) {
            lastLocationInfo = "صلاحية الموقع غير ممنوحة"
            updateNotification(lastLocationInfo)
            statusListener?.invoke(true, lastLocationInfo)
            return
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

        if (!isGpsEnabled && !isNetworkEnabled) {
            lastLocationInfo = "نظام الـ GPS معطل"
            updateNotification(lastLocationInfo)
            statusListener?.invoke(true, lastLocationInfo)
            return
        }

        cancellationTokenSource?.cancel()
        val cts = CancellationTokenSource()
        cancellationTokenSource = cts

        val priority = getPriorityCode()

        fusedLocationClient.getCurrentLocation(priority, cts.token)
            .addOnSuccessListener { location: Location? ->
                if (location != null) {
                    onNewLocation(location)
                } else {
                    fusedLocationClient.lastLocation.addOnSuccessListener { fallback: Location? ->
                        if (fallback != null) {
                            onNewLocation(fallback)
                        } else {
                            lastLocationInfo = "بانتظار إشارة GPS..."
                            updateNotification(lastLocationInfo)
                        }
                    }
                }
            }
            .addOnFailureListener { e ->
                lastLocationInfo = "خطأ: ${e.localizedMessage ?: "فشل تحديد الموقع"}"
                updateNotification(lastLocationInfo)
            }
    }

    private fun onNewLocation(location: Location) {
        val timeStr = timeFormatter.format(Date(location.time))
        val lat = String.format(Locale.US, "%.5f", location.latitude)
        val lng = String.format(Locale.US, "%.5f", location.longitude)
        val accuracyVal = String.format(Locale.US, "%.1f", location.accuracy)

        // Apply distance / time filters
        var shouldEmit = true
        val lastLoc = lastEmittedLocation
        if (lastLoc != null) {
            val distanceMoved = location.distanceTo(lastLoc).toDouble()
            when (trackingMode) {
                "distance" -> {
                    if (distanceFilterMeters > 0.0 && distanceMoved < distanceFilterMeters) {
                        shouldEmit = false
                    }
                }
                "timeOrDistance" -> {
                    val elapsedSec = (location.time - lastEmittedTimeMillis) / 1000L
                    val distanceCondition = distanceFilterMeters > 0.0 && distanceMoved >= distanceFilterMeters
                    val timeCondition = elapsedSec >= currentIntervalSeconds
                    if (!distanceCondition && !timeCondition) {
                        shouldEmit = false
                    }
                }
                "time" -> {
                    shouldEmit = true
                }
            }
        }

        if (!shouldEmit) {
            lastLocationInfo = "الموقع ثابت: Lat: $lat, Lng: $lng في $timeStr"
            updateNotification(lastLocationInfo)
            return
        }

        lastEmittedLocation = location
        lastEmittedTimeMillis = location.time
        lastLocationInfo = "Lat: $lat, Lng: $lng (±${accuracyVal}m) في $timeStr"
        updateNotification(lastLocationInfo)

        val data = HashMap<String, Any>()
        data["latitude"] = location.latitude
        data["longitude"] = location.longitude
        data["accuracy"] = location.accuracy.toDouble()
        data["altitude"] = location.altitude
        data["speed"] = location.speed.toDouble()
        data["bearing"] = location.bearing.toDouble()
        data["timestamp"] = location.time

        locationListener?.invoke(data)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Location Service"
            val descriptionText = "Notifications for background location service"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun resolveSmallIcon(): Int {
        if (!notificationIconName.isNullOrEmpty()) {
            val resId = resources.getIdentifier(notificationIconName, "drawable", packageName)
            if (resId != 0) return resId
            val mipmapId = resources.getIdentifier(notificationIconName, "mipmap", packageName)
            if (mipmapId != 0) return mipmapId
        }
        return applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.ic_menu_mylocation
    }

    private fun buildNotification(statusText: String): Notification {
        val stopIntent = Intent(this, LocationForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val restartIntent = Intent(this, LocationForegroundService::class.java).apply {
            action = ACTION_RESTART
        }
        val restartPendingIntent = PendingIntent.getService(
            this,
            1,
            restartIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val icon = resolveSmallIcon()

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(icon)
            .setContentTitle(notificationTitle)
            .setContentText(statusText)
            .setSubText("${notificationText} [${currentIntervalSeconds}ث]")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                android.R.drawable.ic_menu_rotate,
                restartButtonText,
                restartPendingIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                stopButtonText,
                stopPendingIntent
            )

        if (contentPendingIntent != null) {
            builder.setContentIntent(contentPendingIntent)
        }

        return builder.build()
    }

    private fun updateNotification(statusText: String) {
        if (!isRunning) return
        try {
            val notification = buildNotification(statusText)
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (_: Exception) {}
    }

    private fun stopLocationService() {
        locationRunnable?.let { handler.removeCallbacks(it) }
        locationRunnable = null

        cancellationTokenSource?.cancel()
        cancellationTokenSource = null

        releaseWakeLock()

        lastEmittedLocation = null
        lastEmittedTimeMillis = 0L

        isRunning = false
        statusListener?.invoke(false, "Service stopped")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        stopLocationService()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
