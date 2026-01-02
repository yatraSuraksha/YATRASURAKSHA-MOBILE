import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Example usage and documentation for the API integration
class ApiUsageExample {
  
  /// Example 1: Basic API setup
  static void exampleBasicSetup() {
    if (kDebugMode) {
      print('📖 Example: Basic API Setup');
    }
    
    // Configure your API endpoint and authentication
    ApiConfig.setup(
      baseUrl: 'https://your-api.com/api/location',
      authToken: 'your-bearer-token-here',
      touristId: 'tourist-123',
    );
  }

  /// Example 2: Setup for testing with empty values
  static void exampleTestingSetup() {
    if (kDebugMode) {
      print('📖 Example: Testing Setup');
    }
    
    // Setup with empty values for testing
    ApiConfig.setupForTesting();
    
    // Later, update with real values:
    // ApiConfig.updateAuthToken('real-token');
    // ApiConfig.updateTouristId('real-tourist-id');
  }

  /// Example 3: Check API status
  static void exampleCheckStatus() {
    if (kDebugMode) {
      print('📖 Example: Check API Status');
    }
    
    final status = ApiConfig.getStatus();
    
    if (kDebugMode) {
      print('API Configuration Status:');
      print('  Base URL configured: ${status['baseUrlConfigured']}');
      print('  Auth token configured: ${status['authTokenConfigured']}');
      print('  Tourist ID configured: ${status['touristIdConfigured']}');
    }
  }

  /// Example 4: Test API connection
  static Future<void> exampleTestConnection() async {
    if (kDebugMode) {
      print('📖 Example: Test API Connection');
    }
    
    final isConnected = await ApiConfig.testConnection();
    
    if (kDebugMode) {
      print('API Connection Test: ${isConnected ? 'Success' : 'Failed'}');
    }
  }

  /// Documentation: JSON payload that will be sent
  /// 
  /// This is the exact JSON structure that will be posted to your API:
  /// 
  /// ```json
  /// {
  ///   "touristId": "64f8a2b4c1d2e3f456789abc",
  ///   "latitude": 26.1445,
  ///   "longitude": 91.7362,
  ///   "accuracy": 5.2,
  ///   "speed": 2.5,
  ///   "heading": 180,
  ///   "altitude": 56,
  ///   "batteryLevel": 85,
  ///   "source": "gps"
  /// }
  /// ```
  /// 
  /// Headers included:
  /// - Content-Type: application/json
  /// - Accept: application/json
  /// - Authorization: Bearer {your-token} (if token provided)
  static void documentationJsonPayload() {
    // This method serves as documentation
    // The actual JSON posting happens automatically in the background
  }
}