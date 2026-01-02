import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Enum for tracking modes
enum TrackingMode {
  post,      // Regular POST method for battery efficiency
  websocket, // Real-time WebSocket for live tracking
}

/// WebSocket service for real-time location tracking
class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _lastError;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get lastError => _lastError;

  /// Connect to WebSocket server
  Future<bool> connect(String authToken) async {
    if (_isConnected || _isConnecting) {
      // Already connected or connecting
      return _isConnected;
    }

    try {
      _isConnecting = true;
      _lastError = null;
      notifyListeners();

      // Initiating WebSocket connection

      // Get base URL from environment and convert to WebSocket URL
      String baseUrl = 'ws://74.225.144.0:3000'; // Convert HTTP to WS
      String wsUrl = '$baseUrl/ws/location?token=$authToken';

      // Creating WebSocket connection

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection with timeout
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('WebSocket connection timeout');
        },
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      // WebSocket connected successfully

      // Start listening to messages
      _startListening();
      
      // Start heartbeat
      _startHeartbeat();

      // Send initial connection message
      _sendConnectionMessage();

      notifyListeners();
      return true;

    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _lastError = 'Failed to connect: $e';
      
      // WebSocket connection failed

      notifyListeners();
      
      // Schedule reconnection if within retry limit
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _scheduleReconnect(authToken);
      }
      
      return false;
    }
  }

  /// Start listening to WebSocket messages
  void _startListening() {
    _messageSubscription = _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDisconnection,
    );
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      // Process incoming message

      Map<String, dynamic> data = jsonDecode(message);
      String messageType = data['type'] ?? '';

      switch (messageType) {
        case 'live-tracking-start':
          _handleLiveTrackingStart(data);
          break;
        case 'live-tracking-stop':
          _handleLiveTrackingStop(data);
          break;
        case 'pong':
          _handlePong();
          break;
        case 'error':
          _handleServerError(data);
          break;
        default:
          // Unknown message type - ignore
      }
    } catch (e) {
      // Error handling WebSocket message
    }
  }

  /// Handle live tracking start command
  void _handleLiveTrackingStart(Map<String, dynamic> data) {
    // Live tracking start command received
    
    // Notify listeners about tracking mode change
    _onTrackingModeChange?.call(TrackingMode.websocket);
  }

  /// Handle live tracking stop command
  void _handleLiveTrackingStop(Map<String, dynamic> data) {
    // Live tracking stop command received
    
    // Notify listeners about tracking mode change
    _onTrackingModeChange?.call(TrackingMode.post);
  }

  /// Handle pong response
  void _handlePong() {
    // WebSocket heartbeat pong received
  }

  /// Handle server error
  void _handleServerError(Map<String, dynamic> data) {
    String error = data['message'] ?? 'Unknown server error';
    // Server error received
    _lastError = error;
    notifyListeners();
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    // WebSocket error occurred
    
    _lastError = 'WebSocket error: $error';
    notifyListeners();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    // WebSocket disconnected
    
    _isConnected = false;
    _stopHeartbeat();
    notifyListeners();
    
    // Notify about mode change back to POST
    _onTrackingModeChange?.call(TrackingMode.post);
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send ping message to server
  void _sendPing() {
    try {
      Map<String, dynamic> pingMessage = {
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(pingMessage));
      
      // WebSocket ping sent
    } catch (e) {
      // Error sending ping
    }
  }

  /// Send initial connection message
  void _sendConnectionMessage() {
    try {
      Map<String, dynamic> connectionMessage = {
        'type': 'connection',
        'message': 'Tourist app connected',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(connectionMessage));
      
      // Connection message sent
    } catch (e) {
      // Error sending connection message
    }
  }

  /// Send location data via WebSocket
  Future<bool> sendLocationData(Position position) async {
    if (!_isConnected) {
      // Cannot send location: WebSocket not connected
      return false;
    }

    try {
      // Get device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';
      int batteryLevel = 85; // Default value, you can integrate battery_plus package

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = 'gps_android_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = 'gps_ios_${iosInfo.model}';
      }

      Map<String, dynamic> locationData = {
        'type': 'location-update',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
          'altitude': position.altitude,
          'batteryLevel': batteryLevel,
          'source': deviceId,
          'timestamp': position.timestamp.toIso8601String(),
        }
      };

      _channel?.sink.add(jsonEncode(locationData));

      // WebSocket location update sent

      return true;
    } catch (e) {
      // Error sending location via WebSocket
      return false;
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect(String authToken) {
    _reconnectAttempts++;
    
    // Scheduling WebSocket reconnection attempt
    
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect(authToken);
    });
  }

  /// Disconnect WebSocket
  void disconnect() {

    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _messageSubscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    _messageSubscription = null;
    _reconnectAttempts = 0;
    
    notifyListeners();
  }

  /// Callback for tracking mode changes
  Function(TrackingMode)? _onTrackingModeChange;
  
  /// Set callback for tracking mode changes
  void setTrackingModeChangeCallback(Function(TrackingMode) callback) {
    _onTrackingModeChange = callback;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}