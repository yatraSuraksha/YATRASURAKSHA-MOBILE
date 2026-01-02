package com.example.yatra_suraksha_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "background_location_service"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundTracking" -> {
                    
                    // Request battery optimization exemption first
                    requestBatteryOptimizationExemption()
                    
                    val apiEndpoint = call.argument<String>("apiEndpoint")
                    val authToken = call.argument<String>("authToken")
                    val trackingMode = call.argument<String>("trackingMode") ?: "post"
                    
                    try {
                        val intent = Intent(this, LocationForegroundService::class.java).apply {
                            putExtra("apiEndpoint", apiEndpoint)
                            putExtra("authToken", authToken)
                            putExtra("trackingMode", trackingMode)
                        }
                        
                        startForegroundService(intent)
                        
                        // Save tracking state for reboot recovery
                        LocationForegroundService.saveTrackingState(this, apiEndpoint, authToken, trackingMode)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                
                "stopBackgroundTracking" -> {
                    
                    try {
                        val intent = Intent(this, LocationForegroundService::class.java)
                        stopService(intent)
                        
                        // Clear tracking state
                        LocationForegroundService.clearTrackingState(this)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            val packageName = packageName
            
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                
                try {
                    startActivity(intent)
                } catch (e: Exception) {
                }
            } else {
            }
        }
    }
}