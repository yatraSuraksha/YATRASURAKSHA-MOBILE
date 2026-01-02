package com.example.yatra_suraksha_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class LocationForegroundService : Service() {
    companion object {
        private const val TAG = "LocationForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "location_tracking_channel"
        private const val PREFS_NAME = "location_tracking_prefs"
        private const val KEY_WAS_TRACKING = "was_tracking"
        private const val KEY_API_ENDPOINT = "api_endpoint"
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_TRACKING_MODE = "tracking_mode"
        
        fun saveTrackingState(context: Context, apiEndpoint: String?, authToken: String?, trackingMode: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putBoolean(KEY_WAS_TRACKING, true)
                putString(KEY_API_ENDPOINT, apiEndpoint)
                putString(KEY_AUTH_TOKEN, authToken)
                putString(KEY_TRACKING_MODE, trackingMode)
                apply()
            }
        }
        
        fun clearTrackingState(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback
    private var serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var wakeLock: PowerManager.WakeLock? = null
    
    private var apiEndpoint: String? = null
    private var authToken: String? = null
    private var trackingMode: String = "post"
    private var lastLocationTime = 0L
    private var locationUpdateCount = 0
    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

    override fun onCreate() {
        super.onCreate()
        
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "YatraSuraksha::LocationTracking"
        )
        wakeLock?.acquire(10*60*1000L)
        
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
        setupLocationRequest()
        setupLocationCallback()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        
        apiEndpoint = intent?.getStringExtra("apiEndpoint")
        authToken = intent?.getStringExtra("authToken")
        trackingMode = intent?.getStringExtra("trackingMode") ?: "post"
        
        saveTrackingState(this, apiEndpoint, authToken, trackingMode)
        
        startForeground(NOTIFICATION_ID, createNotification())
        
        startLocationTracking()
        
        return START_STICKY
    }

    private fun setupLocationRequest() {
        // Real-time tracking configuration
        val intervalMs = when (trackingMode) {
            "realtime", "websocket" -> 2000L  // 2 seconds for real-time
            else -> 5000L  // 5 seconds for normal mode
        }
        
        val distanceMeters = when (trackingMode) {
            "realtime", "websocket" -> 1f  // 1 meter for real-time
            else -> 5f  // 5 meters for normal mode
        }
        
        locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMs).apply {
            setMinUpdateDistanceMeters(distanceMeters)
            setGranularity(Granularity.GRANULARITY_PERMISSION_LEVEL)
            setWaitForAccurateLocation(false)
            setMaxUpdateDelayMillis(intervalMs + 1000L) // Force updates
        }.build()
    }

    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (location in locationResult.locations) {
                    locationUpdateCount++
                    
                    updateNotification(location)
                    sendLocationToAPI(location)
                }
            }
            
            override fun onLocationAvailability(availability: LocationAvailability) {
            }
        }
    }

    private fun startLocationTracking() {
        try {
            
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            
            fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                if (location != null) {
                    sendLocationToAPI(location)
                }
            }
            
        } catch (e: SecurityException) {
        } catch (e: Exception) {
        }
    }

    private fun sendLocationToAPI(location: Location) {
        // Real-time mode: reduce rate limiting for more frequent updates
        val rateLimitMs = when (trackingMode) {
            "realtime", "websocket" -> 1000L  // 1 second for real-time
            else -> 3000L  // 3 seconds for normal mode
        }
        
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastLocationTime < rateLimitMs) {
            return
        }
        lastLocationTime = currentTime
        
        serviceScope.launch {
            try {
                
                if (apiEndpoint.isNullOrEmpty()) {
                    return@launch
                }
                
                val success = postLocationToAPI(location)
                
            } catch (e: Exception) {
            }
        }
    }

    private suspend fun postLocationToAPI(location: Location): Boolean = withContext(Dispatchers.IO) {
        try {
            
            val url = URL(apiEndpoint)
            val connection = url.openConnection() as HttpURLConnection
            
            connection.apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                if (!authToken.isNullOrEmpty()) {
                    setRequestProperty("Authorization", "Bearer $authToken")
                }
                doOutput = true
                connectTimeout = 15000
                readTimeout = 15000
            }
            
            val jsonPayload = JSONObject().apply {
                put("latitude", location.latitude)
                put("longitude", location.longitude)
                put("accuracy", location.accuracy)
                put("timestamp", dateFormatter.format(Date(location.time)))
                put("source", "background_service")
                put("tracking_mode", trackingMode)
                put("update_count", locationUpdateCount)
            }
            
            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(jsonPayload.toString())
                writer.flush()
            }
            
            val responseCode = connection.responseCode
            
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                val response = connection.inputStream.bufferedReader().readText()
                return@withContext true
            } else {
                val errorResponse = connection.errorStream?.bufferedReader()?.readText() ?: "No error details"
                return@withContext false
            }
            
        } catch (e: Exception) {
            return@withContext false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Yatra Suraksha Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background location tracking for tourist safety"
                setSound(null, null)
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡️ Yatra Suraksha Active")
            .setContentText("Background location tracking is running")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun updateNotification(location: Location) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡️ Yatra Suraksha Active")
            .setContentText("📍 Updates: $locationUpdateCount | Acc: ${String.format("%.1f", location.accuracy)}m")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setSilent(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
            serviceScope.cancel()
            wakeLock?.release()
        } catch (e: Exception) {
        }
        
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}