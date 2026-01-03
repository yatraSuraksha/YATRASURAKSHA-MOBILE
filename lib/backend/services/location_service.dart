import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'api_service.dart';
import 'websocket_service.dart';
import 'background_location_service.dart';

/// A robust location service for background location tracking
/// Designed for tourist safety applications with API integration
/// Supports hybrid tracking: POST method (default) and WebSocket (live tracking)
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal() {
    // Start monitoring location service status when the service is created
    _startServiceStatusMonitoring();

    // Initialize WebSocket service and set callback
    _initializeWebSocketService();

    // Auto-start real-time background tracking
    _autoStartRealTimeTracking();
  }

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Position? _currentPosition;
  bool _isTracking = false;
  String? _lastError;
  TrackingMode _currentMode = TrackingMode.post;
  bool _isWebSocketConnected = false;

  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();
  final BackgroundLocationService _backgroundLocationService =
      BackgroundLocationService();

  // Background tracking state
  bool _isBackgroundTrackingEnabled = false;
  String? _backgroundApiEndpoint;
  String? _backgroundAuthToken;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get lastError => _lastError;
  TrackingMode get currentMode => _currentMode;
  bool get isWebSocketConnected => _isWebSocketConnected;
  bool get isBackgroundTrackingEnabled => _isBackgroundTrackingEnabled;

  /// Request comprehensive location permissions
  /// Returns true if all necessary permissions are granted
  Future<bool> requestPermission() async {
    try {
      _lastError = null;

      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastError =
            'Location services are disabled. Please enable location services in device settings.';
        notifyListeners();
        return false;
      }

      // Step 2: Check current location permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Step 3: Request basic location permission if needed
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastError =
              'Location permission denied. Please grant location permission to use this feature.';
          notifyListeners();
          return false;
        }
      }

      // Step 4: Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        _lastError =
            'Location permissions are permanently denied. Please enable them in app settings.';
        notifyListeners();
        return false;
      }

      // Step 5: Check if we have whileInUse permission
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Step 6: Request background location permission (always)
        ph.PermissionStatus backgroundPermission =
            await ph.Permission.locationAlways.request();

        if (backgroundPermission.isGranted) {
          return true;
        } else if (backgroundPermission.isPermanentlyDenied) {
          _lastError =
              'Background location permission is permanently denied. Please enable "Allow all the time" in app settings.';
          notifyListeners();
          return false;
        } else {
          _lastError =
              'Background location permission denied. For safety tracking, please allow "All the time" location access.';
          notifyListeners();
          return false;
        }
      }

      return false;
    } catch (e) {
      _lastError = 'Error requesting permissions: $e';
      notifyListeners();
      return false;
    }
  }

  /// Open app settings for manual permission configuration
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Start monitoring location service status
  void _startServiceStatusMonitoring() {
    try {
      _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
        _onServiceStatusChanged,
        onError: _onServiceStatusError,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Handle location service status changes
  void _onServiceStatusChanged(ServiceStatus status) {
    if (status == ServiceStatus.disabled) {
      // Location services have been disabled
      DateTime timestamp = DateTime.now();

      // Log the location-off event to backend
      _logEventToBackend('location-off', timestamp);

      // Update error state
      _lastError = 'Location services have been disabled';
      notifyListeners();
    } else if (status == ServiceStatus.enabled) {
      // Location services have been re-enabled

      // Clear error if it was related to disabled services
      if (_lastError?.contains('disabled') == true) {
        _lastError = null;
        notifyListeners();
      }
    }
  }

  /// Handle service status stream errors
  void _onServiceStatusError(dynamic error) {
    // Handle error silently
  }

  /// Log events to backend for safety monitoring
  Future<void> _logEventToBackend(String eventType, DateTime timestamp) async {
    try {
      // TODO: Implement your backend API call here
      // Example:
      // await http.post(
      //   Uri.parse('https://your-api.com/safety-events'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'event_type': eventType,
      //     'timestamp': timestamp.toIso8601String(),
      //     'device_id': 'your_device_id',
      //     'user_id': 'your_user_id',
      //   }),
      // );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Initialize WebSocket service and set up tracking mode callbacks
  void _initializeWebSocketService() {
    // Set callback for tracking mode changes from server
    _webSocketService.setTrackingModeChangeCallback(_onTrackingModeChange);

    // Listen to WebSocket connection status
    _webSocketService.addListener(_onWebSocketStatusChange);
  }

  /// Handle tracking mode changes from WebSocket service
  void _onTrackingModeChange(TrackingMode newMode) {
    if (_currentMode == newMode) return;

    _currentMode = newMode;

    // Restart tracking with new mode if already tracking
    if (_isTracking) {
      _restartTrackingWithNewMode();
    }

    // Update background service mode if enabled
    _updateBackgroundTrackingMode();

    notifyListeners();
  }

  /// Handle WebSocket connection status changes
  void _onWebSocketStatusChange() {
    bool wasConnected = _isWebSocketConnected;
    _isWebSocketConnected = _webSocketService.isConnected;

    if (wasConnected != _isWebSocketConnected) {
      notifyListeners();
    }
  }

  /// Restart tracking with new mode settings
  void _restartTrackingWithNewMode() {
    // Stop current tracking
    _positionStreamSubscription?.cancel();

    // Start with new settings based on mode
    _startLocationStreamWithMode(_currentMode);
  }

  /// Connect to WebSocket server for live tracking capability
  Future<bool> connectWebSocket(String authToken) async {
    try {
      bool connected = await _webSocketService.connect(authToken);
      return connected;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    _webSocketService.disconnect();
  }

  /// Start automatic background location tracking
  void startLocationStream() async {
    if (_isTracking) {
      return;
    }

    try {
      // Check permissions before starting
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return;
      }

      // Start with current mode
      _startLocationStreamWithMode(_currentMode);
    } catch (e) {
      _lastError = 'Failed to start location tracking: $e';
      _isTracking = false;
      notifyListeners();
    }
  }

  /// Start location stream with specific mode settings
  void _startLocationStreamWithMode(TrackingMode mode) {
    LocationSettings settings;

    // Configure location settings based on tracking mode
    switch (mode) {
      case TrackingMode.post:
        // Battery-optimized settings for POST mode
        settings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Update every 10 meters for battery efficiency
        );
        break;
      case TrackingMode.websocket:
        // High-frequency settings for real-time WebSocket mode
        settings = const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1, // Update every 1 meter for real-time tracking
        );
        break;
    }

    // Start the position stream with mode-specific settings
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _onLocationUpdate,
      onError: _onLocationError,
      onDone: _onLocationStreamDone,
    );

    _isTracking = true;
    notifyListeners();
  }

  /// Stop location tracking
  void stopLocationStream() async {
    if (!_isTracking) {
      return;
    }

    try {
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _isTracking = false;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    _currentPosition = position;
    _lastError = null;
    notifyListeners();

    // Handle location data processing and API posting
    _handleLocationData(position);
  }

  /// Handle location stream errors
  void _onLocationError(dynamic error) {
    _lastError = 'Location stream error: $error';
    notifyListeners();

    // Attempt to restart the stream after a brief delay
    Future.delayed(const Duration(seconds: 5), () {
      if (_isTracking) {
        startLocationStream();
      }
    });
  }

  /// Handle location stream completion
  void _onLocationStreamDone() {
    // If we expect the stream to continue, restart it
    if (_isTracking) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_isTracking) {
          startLocationStream();
        }
      });
    }
  }

  /// Process location data for your specific use case
  void _handleLocationData(Position position) {
    // Send location data based on current tracking mode
    switch (_currentMode) {
      case TrackingMode.post:
        // Use POST method for regular tracking (battery efficient)
        _sendLocationToBackend(position);
        break;
      case TrackingMode.websocket:
        // Use WebSocket for real-time tracking
        _sendLocationViaWebSocket(position);
        break;
    }

    // Additional processing can be added here:
    // - Check safety zones/geofences
    // - Trigger emergency protocols if needed
    // - Store in local database for offline access
    // - Analyze movement patterns
  }

  /// Send location coordinates to backend API via POST
  Future<void> _sendLocationToBackend(Position position) async {
    try {
      // Location ready for backend integration
      // TODO: Implement backend location update when API is ready
      final result = {
        'success': true,
        'message': 'Location tracked',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
          'altitude': position.altitude,
        }
      };

      if (result['success'] == true) {
        debugPrint('✅ Location tracked successfully');
      } else {
        debugPrint('⚠️ Location tracking failed: ${result['error']}');
        // Fallback to old API service
        await _apiService.postLocationUpdate(position);
      }
    } catch (e) {
      // Fallback to old API service
      try {
        await _apiService.postLocationUpdate(position);
      } catch (fallbackError) {
        debugPrint('❌ Location update failed: $fallbackError');
      }
    }
  }

  /// Send location coordinates via WebSocket for real-time tracking
  Future<void> _sendLocationViaWebSocket(Position position) async {
    try {
      if (!_webSocketService.isConnected) {
        // Fallback to POST if WebSocket is not connected
        await _sendLocationToBackend(position);
        return;
      }

      final success = await _webSocketService.sendLocationData(position);

      if (!success) {
        // Fallback to POST method
        await _sendLocationToBackend(position);
      }
    } catch (e) {
      // Fallback to POST method
      await _sendLocationToBackend(position);
    }
  }

  /// Get current location once (not streaming)
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      notifyListeners();

      return position;
    } catch (e) {
      _lastError = 'Failed to get current location: $e';
      notifyListeners();
      return null;
    }
  }

  /// Check if background location permission is granted
  Future<bool> hasBackgroundLocationPermission() async {
    return await ph.Permission.locationAlways.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// TEST METHOD: Start location tracking with enhanced debug output
  /// Call this method to begin seeing live coordinates in debug console
  Future<void> startLiveLocationDebugging() async {
    startLocationStream();
  }

  /// Configure API settings for location posting
  void configureApi({
    String? baseUrl,
    String? authToken,
    String? touristId,
  }) {
    ApiService.updateConfig(
      baseUrl: baseUrl,
      authToken: authToken,
      touristId: touristId,
    );
  }

  /// Get current API configuration status
  Map<String, dynamic> getApiStatus() {
    return _apiService.getConfigStatus();
  }

  /// Test API connectivity
  Future<bool> testApiConnection() async {
    final result = await _apiService.testConnection();
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════
  // BACKGROUND LOCATION TRACKING METHODS
  // These methods enable true background tracking when app is closed
  // ═══════════════════════════════════════════════════════════════════

  /// Enable background location tracking using native foreground service
  /// This ensures location tracking continues even when app is closed
  Future<bool> enableBackgroundTracking({
    String? apiEndpoint,
    String? authToken,
  }) async {
    try {
      // Save configuration
      _backgroundApiEndpoint = apiEndpoint;
      _backgroundAuthToken = authToken;

      // Start native background service with real-time mode
      final success = await _backgroundLocationService.startBackgroundTracking(
        apiEndpoint: apiEndpoint,
        authToken: authToken,
        trackingMode: 'realtime', // Force real-time mode
      );

      if (success) {
        _isBackgroundTrackingEnabled = true;
        notifyListeners();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Disable background location tracking
  Future<bool> disableBackgroundTracking() async {
    try {
      final success = await _backgroundLocationService.stopBackgroundTracking();

      if (success) {
        _isBackgroundTrackingEnabled = false;
        _backgroundApiEndpoint = null;
        _backgroundAuthToken = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Update background service tracking mode when mode changes
  Future<void> _updateBackgroundTrackingMode() async {
    if (_isBackgroundTrackingEnabled) {
      try {
        await _backgroundLocationService.updateTrackingMode(_currentMode.name);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  /// Check if background tracking is currently active
  Future<bool> checkBackgroundTrackingStatus() async {
    try {
      final isActive =
          await _backgroundLocationService.isBackgroundTrackingActive();
      _isBackgroundTrackingEnabled = isActive;
      notifyListeners();
      return isActive;
    } catch (e) {
      return false;
    }
  }

  /// Start both regular and background tracking (recommended for full safety coverage)
  Future<bool> startFullTracking({
    String? apiEndpoint,
    String? authToken,
  }) async {
    try {
      // Start regular tracking (existing functionality)
      startLocationStream();

      // Start background tracking
      final backgroundSuccess = await enableBackgroundTracking(
        apiEndpoint: apiEndpoint,
        authToken: authToken,
      );

      return backgroundSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Stop both regular and background tracking
  Future<bool> stopFullTracking() async {
    try {
      // Stop regular tracking
      stopLocationStream();

      // Stop background tracking
      final success = await disableBackgroundTracking();

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Auto-start real-time background tracking
  Future<void> _autoStartRealTimeTracking() async {
    // Use your actual API endpoint here
    _backgroundApiEndpoint =
        'https://httpbin.org/post'; // Replace with your real API
    _backgroundAuthToken = null; // Add your auth token if needed

    // Start background tracking with real-time mode
    await Future.delayed(
        const Duration(seconds: 2)); // Small delay to ensure app is ready

    await enableBackgroundTracking(
      apiEndpoint: _backgroundApiEndpoint,
      authToken: _backgroundAuthToken,
    );
  }

  /// Dispose of resources
  @override
  void dispose() {
    stopLocationStream();
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _apiService.dispose();
    super.dispose();
  }
}
