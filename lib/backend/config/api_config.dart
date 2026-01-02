import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Configuration helper for API settings
class ApiConfig {
  /// Configure the location API settings
  /// 
  /// Example usage:
  /// ```dart
  /// ApiConfig.setup(
  ///   baseUrl: 'https://your-api.com/api/location',
  ///   authToken: 'your-auth-token-here',
  ///   touristId: 'tourist-123',
  /// );
  /// ```
  static void setup({
    required String baseUrl,
    String? authToken,
    String? touristId,
  }) {
    final locationService = LocationService();
    locationService.configureApi(
      baseUrl: baseUrl,
      authToken: authToken,
      touristId: touristId,
    );
    
    if (kDebugMode) {
      print('🔧 ═══════════════════════════════════════════════════════════');
      print('🔧 API CONFIGURATION APPLIED');
      print('🔧 ═══════════════════════════════════════════════════════════');
      print('📡 Base URL: $baseUrl');
      print('🔑 Auth Token: ${authToken != null ? '[Configured]' : '[Not Set]'}');
      print('👤 Tourist ID: ${touristId ?? '[Not Set]'}');
      print('🔧 ═══════════════════════════════════════════════════════════');
    }
  }

  /// Update only the authentication token
  static void updateAuthToken(String authToken) {
    final locationService = LocationService();
    locationService.configureApi(authToken: authToken);
    
    if (kDebugMode) {
      print('🔑 Auth token updated successfully');
    }
  }

  /// Update only the tourist ID
  static void updateTouristId(String touristId) {
    final locationService = LocationService();
    locationService.configureApi(touristId: touristId);
    
    if (kDebugMode) {
      print('👤 Tourist ID updated successfully');
    }
  }

  /// Get current configuration status
  static Map<String, dynamic> getStatus() {
    final locationService = LocationService();
    return locationService.getApiStatus();
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    final locationService = LocationService();
    return await locationService.testApiConnection();
  }

  /// Quick setup for development/testing (empty values)
  static void setupForTesting() {
    if (kDebugMode) {
      print('⚠️ Setting up API configuration for testing (empty values)');
      print('💡 Remember to update with actual values later using:');
      print('   ApiConfig.setup(baseUrl: "your-url", authToken: "your-token")');
    }
    
    setup(
      baseUrl: '', // Will be updated later
      authToken: '', // Will be updated later
      touristId: '', // Will be updated later
    );
  }
}