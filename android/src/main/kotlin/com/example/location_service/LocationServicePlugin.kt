package com.example.location_service

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class LocationServicePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var locationEventChannel: EventChannel
    private lateinit var statusEventChannel: EventChannel
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var locationSink: EventChannel.EventSink? = null
    private var statusSink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: Result? = null

    private val PERMISSION_REQUEST_CODE = 4001

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val ctx = flutterPluginBinding.applicationContext
        context = ctx
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(ctx)

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "location_service")
        channel.setMethodCallHandler(this)

        locationEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "location_service/updates")
        locationEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                locationSink = events
            }

            override fun onCancel(arguments: Any?) {
                locationSink = null
            }
        })

        statusEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "location_service/status")
        statusEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                statusSink = events
                events?.success(
                    mapOf(
                        "isRunning" to LocationForegroundService.isRunning,
                        "status" to if (LocationForegroundService.isRunning) "Service running" else "Service stopped"
                    )
                )
            }

            override fun onCancel(arguments: Any?) {
                statusSink = null
            }
        })

        LocationForegroundService.locationListener = { locationMap ->
            mainHandler.post {
                locationSink?.success(locationMap)
            }
        }

        LocationForegroundService.statusListener = { isRunning, status ->
            mainHandler.post {
                statusSink?.success(
                    mapOf(
                        "isRunning" to isRunning,
                        "status" to status
                    )
                )
            }
        }
    }

    private fun locationToMap(location: Location): Map<String, Any> {
        val data = HashMap<String, Any>()
        data["latitude"] = location.latitude
        data["longitude"] = location.longitude
        data["accuracy"] = location.accuracy.toDouble()
        data["altitude"] = location.altitude
        data["speed"] = location.speed.toDouble()
        data["bearing"] = location.bearing.toDouble()
        data["timestamp"] = location.time
        return data
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Application context is null", null)
            return
        }

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            "startService" -> {
                val intervalSeconds = call.argument<Int>("intervalSeconds") ?: 5
                val distanceFilterMeters = call.argument<Double>("distanceFilterMeters") ?: 0.0
                val trackingMode = call.argument<String>("trackingMode") ?: "time"
                val accuracy = call.argument<String>("accuracy") ?: "high"
                val title = call.argument<String>("notificationTitle") ?: "خدمة الموقع"
                val text = call.argument<String>("notificationText") ?: "جاري تتبع الموقع..."
                val stopText = call.argument<String>("stopButtonText") ?: "إيقاف"
                val restartText = call.argument<String>("restartButtonText") ?: "إعادة تشغيل"
                val enableWakeLock = call.argument<Boolean>("enableWakeLock") ?: true
                val notificationIcon = call.argument<String>("notificationIcon")

                val intent = Intent(ctx, LocationForegroundService::class.java).apply {
                    action = LocationForegroundService.ACTION_START
                    putExtra(LocationForegroundService.EXTRA_INTERVAL_SECONDS, intervalSeconds)
                    putExtra(LocationForegroundService.EXTRA_DISTANCE_FILTER_METERS, distanceFilterMeters)
                    putExtra(LocationForegroundService.EXTRA_TRACKING_MODE, trackingMode)
                    putExtra(LocationForegroundService.EXTRA_ACCURACY, accuracy)
                    putExtra(LocationForegroundService.EXTRA_NOTIFICATION_TITLE, title)
                    putExtra(LocationForegroundService.EXTRA_NOTIFICATION_TEXT, text)
                    putExtra(LocationForegroundService.EXTRA_STOP_BUTTON_TEXT, stopText)
                    putExtra(LocationForegroundService.EXTRA_RESTART_BUTTON_TEXT, restartText)
                    putExtra(LocationForegroundService.EXTRA_ENABLE_WAKELOCK, enableWakeLock)
                    putExtra(LocationForegroundService.EXTRA_NOTIFICATION_ICON, notificationIcon)
                }

                ContextCompat.startForegroundService(ctx, intent)
                result.success(true)
            }

            "restartService" -> {
                LocationForegroundService.restart(ctx)
                result.success(true)
            }

            "updateInterval" -> {
                val intervalSeconds = call.argument<Int>("intervalSeconds") ?: 5
                LocationForegroundService.updateInterval(ctx, intervalSeconds)
                result.success(true)
            }

            "stopService" -> {
                LocationForegroundService.stop(ctx)
                result.success(true)
            }

            "isServiceRunning" -> {
                result.success(LocationForegroundService.isRunning)
            }

            "isGpsEnabled" -> {
                val locationManager = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
                val isGps = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                val isNetwork = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                result.success(isGps || isNetwork)
            }

            "openLocationSettings" -> {
                val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                ctx.startActivity(intent)
                result.success(true)
            }

            "getCurrentLocation" -> {
                val hasFine = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
                val hasCoarse = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED

                if (!hasFine && !hasCoarse) {
                    result.error("PERMISSION_DENIED", "Location permission is not granted", null)
                    return
                }

                val accuracyArg = call.argument<String>("accuracy") ?: "high"
                val priority = when (accuracyArg.lowercase()) {
                    "balanced" -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
                    "low" -> Priority.PRIORITY_LOW_POWER
                    "passive" -> Priority.PRIORITY_PASSIVE
                    else -> Priority.PRIORITY_HIGH_ACCURACY
                }

                val timeoutMillis = (call.argument<Int>("timeoutMillis") ?: 8000).toLong()
                val cts = CancellationTokenSource()
                var isCompleted = false

                val timeoutRunnable = Runnable {
                    if (!isCompleted) {
                        isCompleted = true
                        cts.cancel()
                        fusedLocationClient.lastLocation.addOnSuccessListener { fallback ->
                            if (fallback != null) {
                                result.success(locationToMap(fallback))
                            } else {
                                result.error("TIMEOUT", "Location request timed out", null)
                            }
                        }.addOnFailureListener {
                            result.error("TIMEOUT", "Location request timed out", null)
                        }
                    }
                }
                mainHandler.postDelayed(timeoutRunnable, timeoutMillis)

                fusedLocationClient.getCurrentLocation(priority, cts.token)
                    .addOnSuccessListener { location: Location? ->
                        if (!isCompleted) {
                            isCompleted = true
                            mainHandler.removeCallbacks(timeoutRunnable)
                            if (location != null) {
                                result.success(locationToMap(location))
                            } else {
                                fusedLocationClient.lastLocation.addOnSuccessListener { fallback ->
                                    if (fallback != null) {
                                        result.success(locationToMap(fallback))
                                    } else {
                                        result.success(null)
                                    }
                                }.addOnFailureListener {
                                    result.success(null)
                                }
                            }
                        }
                    }
                    .addOnFailureListener { e ->
                        if (!isCompleted) {
                            isCompleted = true
                            mainHandler.removeCallbacks(timeoutRunnable)
                            result.error("LOCATION_ERROR", e.localizedMessage, null)
                        }
                    }
            }

            "getLastKnownLocation" -> {
                val hasFine = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
                val hasCoarse = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED

                if (!hasFine && !hasCoarse) {
                    result.error("PERMISSION_DENIED", "Location permission is not granted", null)
                    return
                }

                fusedLocationClient.lastLocation
                    .addOnSuccessListener { loc ->
                        if (loc != null) {
                            result.success(locationToMap(loc))
                        } else {
                            result.success(null)
                        }
                    }
                    .addOnFailureListener { e ->
                        result.error("LOCATION_ERROR", e.localizedMessage, null)
                    }
            }

            "checkPermission" -> {
                val hasFine = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
                val hasCoarse = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED

                val hasNotification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ContextCompat.checkSelfPermission(
                        ctx,
                        Manifest.permission.POST_NOTIFICATIONS
                    ) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }

                val status = if (hasFine || hasCoarse) {
                    if (hasNotification) "granted" else "notification_denied"
                } else {
                    "denied"
                }

                result.success(status)
            }

            "requestPermission" -> {
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "Cannot request permission without activity", null)
                    return
                }

                if (pendingPermissionResult != null) {
                    result.error("ALREADY_REQUESTING", "Permission request is already in progress", null)
                    return
                }

                val permissions = mutableListOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    permissions.add(Manifest.permission.POST_NOTIFICATIONS)
                }

                pendingPermissionResult = result
                ActivityCompat.requestPermissions(act, permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val res = pendingPermissionResult ?: return false
            pendingPermissionResult = null

            val ctx = context ?: run {
                res.success("denied")
                return true
            }

            val hasFine = ContextCompat.checkSelfPermission(
                ctx,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            val hasCoarse = ContextCompat.checkSelfPermission(
                ctx,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

            val hasNotification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }

            val status = if (hasFine || hasCoarse) {
                if (hasNotification) "granted" else "notification_denied"
            } else {
                "denied"
            }

            res.success(status)
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        locationEventChannel.setStreamHandler(null)
        statusEventChannel.setStreamHandler(null)
        LocationForegroundService.locationListener = null
        LocationForegroundService.statusListener = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }
}
