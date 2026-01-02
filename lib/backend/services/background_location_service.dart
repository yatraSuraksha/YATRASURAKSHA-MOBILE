import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BackgroundLocationService {
  static const _channel = MethodChannel('background_location_service');

  /// Start background location tracking with API integration
  Future<bool> startBackgroundTracking({
    String? apiEndpoint,
    String? authToken,
    String trackingMode = 'post',
  }) async {
    try {
      final result = await _channel.invokeMethod('startBackgroundTracking', {
        'apiEndpoint': apiEndpoint,
        'authToken': authToken,
        'trackingMode': trackingMode,
      });

      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Stop background location tracking
  Future<bool> stopBackgroundTracking() async {
    try {
      final result = await _channel.invokeMethod('stopBackgroundTracking');

      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Update tracking mode
  Future<bool> updateTrackingMode(String mode) async {
    try {
      final result = await _channel.invokeMethod('updateTrackingMode', {
        'trackingMode': mode,
      });

      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Check if background tracking is active
  Future<bool> isBackgroundTrackingActive() async {
    try {
      final result = await _channel.invokeMethod('isBackgroundTrackingActive');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Get background tracking status with details
  Future<Map<String, dynamic>> getBackgroundTrackingStatus() async {
    try {
      final result = await _channel.invokeMethod('getBackgroundTrackingStatus');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return {};
    }
  }
}