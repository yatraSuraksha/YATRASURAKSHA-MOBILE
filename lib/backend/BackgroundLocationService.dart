import 'package:flutter/services.dart';

/// Service for managing background location tracking
/// This bridges Flutter with native Android foreground service
class BackgroundLocationService {
  static const MethodChannel _channel = MethodChannel('background_location_service');
  
  static bool _isInitialized = false;
  static bool _isTracking = false;
  
  /// Initialize the background location service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up method call handler for callbacks from native side
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      
      // Service initialized successfully
    } catch (e) {
      // Service initialization failed
      rethrow;
    }
  }
  
  /// Start background location tracking
  /// 
  /// Parameters:
  /// - [apiEndpoint]: Backend API endpoint for location updates
  /// - [authToken]: Authentication token (optional)
  /// - [trackingMode]: "post" or "websocket" tracking mode
  static Future<bool> startTracking({
    required String apiEndpoint,
    String? authToken,
    String trackingMode = 'post',
  }) async {
    try {
      await initialize();
      
      // Starting background tracking
      
      final result = await _channel.invokeMethod('startTracking', {
        'apiEndpoint': apiEndpoint,
        'authToken': authToken,
        'trackingMode': trackingMode,
      });
      
      _isTracking = result == true;
      
      // Tracking status updated
      
      return _isTracking;
    } catch (e) {
      // Error starting tracking
      _isTracking = false;
      return false;
    }
  }
  
  /// Stop background location tracking
  static Future<bool> stopTracking() async {
    try {
      await initialize();
      
      // Stopping background tracking
      
      final result = await _channel.invokeMethod('stopTracking');
      
      _isTracking = !(result == true);
      
      // Tracking stopped
      
      return result == true;
    } catch (e) {
      // Error stopping tracking
      return false;
    }
  }
  
  /// Check if background tracking is currently active
  static Future<bool> isTracking() async {
    try {
      await initialize();
      
      final result = await _channel.invokeMethod('isTracking');
      _isTracking = result == true;
      
      // Checking tracking status
      
      return _isTracking;
    } catch (e) {
      // Error checking tracking status
      return false;
    }
  }
  
  /// Get current tracking status without calling native method
  static bool get isCurrentlyTracking => _isTracking;
  
  /// Handle method calls from native side
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    // Received native method call
    
    switch (call.method) {
      case 'onLocationUpdate':
        final data = call.arguments as Map<dynamic, dynamic>;
        _handleLocationUpdate(data);
        break;
        
      case 'onTrackingStatusChanged':
        final isActive = call.arguments as bool;
        _isTracking = isActive;
        
        // Tracking status changed
        break;
        
      case 'onError':
        // Native error received
        break;
        
      default:
        // Unknown method call
    }
  }
  
  /// Handle location updates from native side
  static void _handleLocationUpdate(Map<dynamic, dynamic> data) {
    // Location update received - process if needed
    // For now, just acknowledge the update
  }
  
  /// Test the background service (useful for debugging)
  static Future<Map<String, dynamic>> testService() async {
    try {
      await initialize();
      
      // Running service test
      
      final result = await _channel.invokeMethod('testService');
      
      final testResults = {
        'serviceAvailable': result['serviceAvailable'] ?? false,
        'locationPermission': result['locationPermission'] ?? false,
        'backgroundPermission': result['backgroundPermission'] ?? false,
        'playServicesAvailable': result['playServicesAvailable'] ?? false,
        'message': result['message'] ?? 'Test completed',
      };
      
      // Test completed
      
      return testResults;
    } catch (e) {
      // Test failed
      
      return {
        'serviceAvailable': false,
        'locationPermission': false,
        'backgroundPermission': false,
        'playServicesAvailable': false,
        'message': 'Test failed: $e',
      };
    }
  }
  
  /// Get service statistics
  static Future<Map<String, dynamic>> getStats() async {
    try {
      await initialize();
      
      final result = await _channel.invokeMethod('getStats');
      
      return {
        'isTracking': result['isTracking'] ?? false,
        'updateCount': result['updateCount'] ?? 0,
        'lastUpdateTime': result['lastUpdateTime'] ?? 0,
        'apiCallCount': result['apiCallCount'] ?? 0,
        'errorCount': result['errorCount'] ?? 0,
      };
    } catch (e) {
      // Error getting stats
      
      return {
        'isTracking': false,
        'updateCount': 0,
        'lastUpdateTime': 0,
        'apiCallCount': 0,
        'errorCount': 0,
      };
    }
  }
}