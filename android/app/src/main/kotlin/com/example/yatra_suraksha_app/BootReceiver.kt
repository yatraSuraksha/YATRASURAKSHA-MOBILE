package com.example.yatra_suraksha_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val PREFS_NAME = "location_tracking_prefs"
        private const val KEY_WAS_TRACKING = "was_tracking"
        private const val KEY_API_ENDPOINT = "api_endpoint"
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_TRACKING_MODE = "tracking_mode"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val wasTracking = prefs.getBoolean(KEY_WAS_TRACKING, false)
            
            if (wasTracking) {
                
                val apiEndpoint = prefs.getString(KEY_API_ENDPOINT, null)
                val authToken = prefs.getString(KEY_AUTH_TOKEN, null)
                val trackingMode = prefs.getString(KEY_TRACKING_MODE, "post")
                
                val serviceIntent = Intent(context, LocationForegroundService::class.java).apply {
                    putExtra("apiEndpoint", apiEndpoint)
                    putExtra("authToken", authToken)
                    putExtra("trackingMode", trackingMode)
                }
                
                try {
                    context.startForegroundService(serviceIntent)
                } catch (e: Exception) {
                }
            } else {
            }
        }
    }
}