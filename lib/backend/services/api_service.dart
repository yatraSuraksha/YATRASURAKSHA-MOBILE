import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for handling API communication with the backend server
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuration - can be updated later
  static String _baseUrl = 'http://4.186.25.99:3000';
  static String _authToken = ''; // Leave empty for now
  static String _touristId = ''; // Leave empty for now

  // HTTP client with timeout configuration
  final http.Client _client = http.Client();

  // Dynamic timeout from environment variables
  static Duration get _timeout {
    final timeoutSeconds =
        int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;
    return Duration(seconds: timeoutSeconds);
  }

  /// Update API configuration
  static void updateConfig({
    String? baseUrl,
    String? authToken,
    String? touristId,
  }) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (authToken != null) _authToken = authToken;
    if (touristId != null) _touristId = touristId;

    // API configuration updated
  }

  /// Get current battery level (approximate)
  Future<int> _getBatteryLevel() async {
    try {
      // For now, return a default value since battery_plus requires additional setup
      // You can integrate battery_plus package later for actual battery level
      return 85; // Default battery level
    } catch (e) {
      return 85; // Fallback value
    }
  }

  /// Get device information for source identification
  Future<String> _getLocationSource() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'gps_android_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'gps_ios_${iosInfo.model}';
      }
      return 'gps';
    } catch (e) {
      return 'gps';
    }
  }

  /// Post location coordinates to the API
  Future<bool> postLocationUpdate(Position position) async {
    // Skip if configuration is not set
    if (_baseUrl.isEmpty) {
      return false;
    }

    try {
      // Get additional device information
      final batteryLevel = await _getBatteryLevel();
      final source = await _getLocationSource();

      // Prepare the JSON payload according to your specification
      final locationData = {
        'touristId': _touristId.isEmpty ? '' : _touristId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
        'batteryLevel': batteryLevel,
        'source': source,
      };

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if token is available
      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      if (kDebugMode) {
        headers.forEach((key, value) {});
      }

      // Make the POST request
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: headers,
            body: jsonEncode(locationData),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          if (response.body.isNotEmpty) {
            try {
              jsonDecode(response.body);
            } catch (e) {
              print(e);
            }
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    if (_baseUrl.isEmpty) {
      return false;
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      final response = await _client
          .get(
            Uri.parse(_baseUrl),
            headers: headers,
          )
          .timeout(_timeout);

      return response.statusCode < 500; // Accept any non-server error
    } catch (e) {
      return false;
    }
  }

  /// Generic GET request method
  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    if (_baseUrl.isEmpty) {
      return {'error': 'API URL not configured'};
    }

    try {
      // Build the URL with query parameters
      String url =
          _baseUrl.endsWith('/') ? _baseUrl + endpoint : '$_baseUrl/$endpoint';
      Uri uri = Uri.parse(url);

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if token is available
      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      // Make the GET request
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return {'success': true, 'data': jsonResponse};
        } catch (e) {
          return {'success': true, 'data': response.body};
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'statusCode': response.statusCode,
          'message': response.body,
          'headers': response.headers
        };
      }
    } catch (e, stackTrace) {
      return {
        'success': false,
        'error': 'Exception: $e',
        'exception': e.toString(),
        'stackTrace': stackTrace.toString()
      };
    }
  }

  /// Generic POST request method
  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    if (_baseUrl.isEmpty) {
      return {'error': 'API URL not configured'};
    }

    try {
      // Build the URL
      String url =
          _baseUrl.endsWith('/') ? _baseUrl + endpoint : '$_baseUrl/$endpoint';
      Uri uri = Uri.parse(url);

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if token is available
      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      // Make the POST request
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return {'success': true, 'data': jsonResponse};
        } catch (e) {
          return {'success': true, 'data': response.body};
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'statusCode': response.statusCode,
          'message': response.body,
          'headers': response.headers
        };
      }
    } catch (e, stackTrace) {
      return {
        'success': false,
        'error': 'Exception: $e',
        'exception': e.toString(),
        'stackTrace': stackTrace.toString()
      };
    }
  }

  /// Verify user with Firebase token
  Future<Map<String, dynamic>> verifyUser(String firebaseToken) async {
    // Temporarily update auth token for this request
    final previousToken = _authToken;
    _authToken = firebaseToken;

    try {
      final result = await post('api/users/verify');
      return result;
    } finally {
      // Restore previous token
      _authToken = previousToken;
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    return await get('user/profile');
  }

  /// Get tourist location history
  Future<Map<String, dynamic>> getLocationHistory({
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    final queryParams = <String, String>{};

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (limit != null) queryParams['limit'] = limit.toString();

    return await get('tourist/locations', queryParams: queryParams);
  }

  /// Get safety alerts for current location
  Future<Map<String, dynamic>> getSafetyAlerts({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    final queryParams = <String, String>{};

    if (latitude != null) queryParams['lat'] = latitude.toString();
    if (longitude != null) queryParams['lng'] = longitude.toString();
    if (radius != null) queryParams['radius'] = radius.toString();

    return await get('safety/alerts', queryParams: queryParams);
  }

  /// Get emergency contacts
  Future<Map<String, dynamic>> getEmergencyContacts() async {
    return await get('emergency/contacts');
  }

  /// Get nearby places of interest
  Future<Map<String, dynamic>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': radius.toString(),
    };

    if (type != null) queryParams['type'] = type;

    return await get('places/nearby', queryParams: queryParams);
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }

  /// Get current configuration status
  Map<String, dynamic> getConfigStatus() {
    return {
      'baseUrlConfigured': _baseUrl.isNotEmpty,
      'authTokenConfigured': _authToken.isNotEmpty,
      'touristIdConfigured': _touristId.isNotEmpty,
      'baseUrl': _baseUrl.isNotEmpty ? _baseUrl : null,
      'touristId': _touristId.isNotEmpty ? _touristId : null,
    };
  }
}
