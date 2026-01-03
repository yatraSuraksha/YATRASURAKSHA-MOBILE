import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/api_config.dart';

/// Service for managing SOS emergency video recording
/// Records continuous 15-second video clips until stopped by user
class SOSVideoService extends ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  Timer? _recordingTimer;

  bool _isRecording = false;
  bool _isInitialized = false;
  int _currentRecordingNumber = 0;
  int _secondsRemaining = 15;

  // Recording configuration
  static const int recordingDurationSeconds = 15;
  static const int maxRecordingClips = 1; // Single 15-second clip

  // Getters
  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;
  int get currentRecordingNumber => _currentRecordingNumber;
  int get secondsRemaining => _secondsRemaining;
  CameraController? get cameraController => _cameraController;

  /// Initialize camera and prepare for recording
  Future<bool> initialize() async {
    try {
      // Request camera and microphone permissions
      debugPrint('📷 Requesting camera permissions...');
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      await Permission.storage.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        debugPrint('❌ Camera or microphone permission denied');
        debugPrint('   Camera: $cameraStatus');
        debugPrint('   Microphone: $micStatus');
        return false;
      }

      if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
        debugPrint('❌ Camera or microphone permission permanently denied');
        debugPrint('   Please enable permissions in app settings');
        await openAppSettings();
        return false;
      }

      debugPrint('✅ Permissions granted');

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('❌ No cameras available');
        return false;
      }

      debugPrint('📷 Found ${_cameras!.length} camera(s)');

      // Use back camera (index 0) by default, front camera would be index 1
      final camera = _cameras!.first;

      // Initialize camera controller with 720p resolution
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // 720p - balance between quality and file size
        enableAudio: true, // Enable audio recording
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      debugPrint('📷 Initializing camera controller...');
      await _cameraController!.initialize();
      _isInitialized = true;
      notifyListeners();

      debugPrint('✅ Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing camera: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      debugPrint('⚠️ Only one camera available, cannot switch');
      return;
    }

    try {
      final wasRecording = _isRecording;
      if (wasRecording) {
        await stopRecording();
      }

      final currentCameraIndex =
          _cameras!.indexOf(_cameraController!.description);
      final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras![newCameraIndex],
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      notifyListeners();

      if (wasRecording) {
        await _startNextRecording();
      }

      debugPrint('✅ Camera switched successfully');
    } catch (e) {
      debugPrint('❌ Error switching camera: $e');
    }
  }

  /// Start the SOS recording cycle
  Future<void> startSOSRecording() async {
    if (!_isInitialized || _cameraController == null) {
      debugPrint('❌ Camera not initialized');
      return;
    }

    if (_isRecording) {
      debugPrint('⚠️ Already recording');
      return;
    }

    _currentRecordingNumber = 0;
    _isRecording = true;
    notifyListeners();

    debugPrint('🎥 Starting SOS recording cycle');
    await _startNextRecording();
  }

  /// Start recording the next 15-second clip
  Future<void> _startNextRecording() async {
    if (!_isRecording || _cameraController == null) return;

    try {
      _currentRecordingNumber++;
      _secondsRemaining = recordingDurationSeconds;

      debugPrint('🎥 Starting recording #$_currentRecordingNumber');

      // Start video recording
      await _cameraController!.startVideoRecording();
      notifyListeners();

      // Start countdown timer
      _recordingTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) async {
        _secondsRemaining--;
        notifyListeners();

        if (_secondsRemaining <= 0) {
          timer.cancel();
          await _finishCurrentRecording();
        }
      });
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  /// Finish current recording and prepare for next one
  Future<void> _finishCurrentRecording() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isRecordingVideo) {
        return;
      }

      // Stop recording
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      debugPrint(
          '✅ Recording #$_currentRecordingNumber completed: ${videoFile.path}');

      // Collect metadata
      final metadata = await _collectMetadata(videoFile);

      // Prepare video for sending (placeholder)
      await _prepareVideoForServer(videoFile, metadata);

      // Check if we should continue recording
      // Stop after maxRecordingClips or if user stopped recording
      if (_isRecording && _currentRecordingNumber < maxRecordingClips) {
        debugPrint('🔄 Starting next recording...');
        await Future.delayed(const Duration(milliseconds: 500)); // Brief pause
        await _startNextRecording();
      } else {
        if (_currentRecordingNumber >= maxRecordingClips) {
          debugPrint('⏹️ Maximum recording limit reached. Stopping...');
        }
        _isRecording = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error finishing recording: $e');
    }
  }

  /// Collect metadata for the video
  Future<Map<String, dynamic>> _collectMetadata(XFile videoFile) async {
    final metadata = <String, dynamic>{
      'recordingNumber': _currentRecordingNumber,
      'timestamp': DateTime.now().toIso8601String(),
      'filePath': videoFile.path,
      'fileSize': await File(videoFile.path).length(),
      'duration': recordingDurationSeconds,
    };

    // Try to get location
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      metadata['location'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (e) {
      debugPrint('⚠️ Could not get location: $e');
      metadata['location'] = null;
    }

    // Add device information
    if (kIsWeb) {
      metadata['platform'] = 'web';
    } else if (Platform.isAndroid) {
      metadata['platform'] = 'android';
    } else if (Platform.isIOS) {
      metadata['platform'] = 'ios';
    }

    return metadata;
  }

  /// Save video to gallery and send to server
  Future<Map<String, dynamic>> _prepareVideoForServer(
    XFile videoFile,
    Map<String, dynamic> metadata,
  ) async {
    debugPrint('📤 Processing video...');
    debugPrint('   Video: ${videoFile.path}');
    debugPrint('   Metadata: $metadata');

    final results = <String, dynamic>{};

    // 1. Save video to device gallery
    try {
      await Gal.putVideo(videoFile.path);
      debugPrint('✅ Video saved to gallery');
      results['gallerySaved'] = true;
      results['galleryPath'] = videoFile.path;
    } catch (e) {
      debugPrint('❌ Error saving to gallery: $e');
      results['gallerySaved'] = false;
      results['galleryError'] = e.toString();
    }

    // 2. Upload video to backend server
    try {
      final uploadResult = await _uploadVideoToBackend(videoFile, metadata);
      results['serverUpload'] = uploadResult;
      debugPrint('✅ Video uploaded to server successfully');
    } catch (e) {
      debugPrint('❌ Error uploading to server: $e');
      results['serverUpload'] = {
        'success': false,
        'error': e.toString(),
      };
    }

    return results;
  }

  /// Upload video to backend server
  Future<Map<String, dynamic>> _uploadVideoToBackend(
    XFile videoFile,
    Map<String, dynamic> metadata,
  ) async {
    final endpoint = ApiConfig.sosVideoUploadEndpoint;

    try {
      final dio = Dio();

      // Prepare multipart form data
      final formData = FormData.fromMap({
        // Video file
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: 'sos_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        ),

        // Metadata as JSON string or individual fields
        'recordingNumber': metadata['recordingNumber'],
        'timestamp': metadata['timestamp'],
        'duration': metadata['duration'],
        'platform': metadata['platform'],

        // Location data (if available)
        if (metadata['location'] != null) ...{
          'latitude': metadata['location']['latitude'],
          'longitude': metadata['location']['longitude'],
          'accuracy': metadata['location']['accuracy'],
        },

        // TODO: Add user authentication and session info
        // 'userId': userId,
        // 'sessionId': emergencySessionId,
      });

      // Set headers (add authentication token when available)
      final options = Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          // TODO: Add authentication
          // 'Authorization': 'Bearer $authToken',
        },
        sendTimeout: ApiConfig.videoUploadTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      );

      debugPrint('📤 Uploading to: $endpoint');

      final response = await dio.post(
        endpoint,
        data: formData,
        options: options,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          debugPrint('Upload progress: $progress%');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Server response: ${response.data}');
        return {
          'success': true,
          'data': response.data,
          'statusCode': response.statusCode,
        };
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Upload failed with status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio error: ${e.type} - ${e.message}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {
          'success': false,
          'error': 'Upload timeout - please check your internet connection',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'success': false,
          'error': 'Connection error - cannot reach server',
        };
      } else {
        return {
          'success': false,
          'error': e.message ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Stop SOS recording cycle
  Future<void> stopRecording() async {
    debugPrint('⏹️ Stopping SOS recording');

    _isRecording = false;
    _recordingTimer?.cancel();

    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      try {
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        final metadata = await _collectMetadata(videoFile);
        await _prepareVideoForServer(videoFile, metadata);
        debugPrint('✅ Final recording saved');
      } catch (e) {
        debugPrint('❌ Error stopping final recording: $e');
      }
    }

    _currentRecordingNumber = 0;
    _secondsRemaining = recordingDurationSeconds;
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  /// Delete old SOS videos to free up storage
  Future<void> cleanupOldVideos({int keepLastN = 5}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      final files = dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains('sos_video_'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Keep only the last N videos, delete the rest
      if (files.length > keepLastN) {
        for (var i = keepLastN; i < files.length; i++) {
          await files[i].delete();
          debugPrint('🗑️ Deleted old SOS video: ${files[i].path}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up videos: $e');
    }
  }
}
