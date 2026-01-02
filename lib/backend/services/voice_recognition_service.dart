import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();

      if (!permissionStatus.isGranted) {
        print('Microphone permission denied');
        return false;
      }

      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );

      return _isInitialized;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Check if the service is currently listening
  bool get isListening => _isListening;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Start listening for speech input
  /// [onResult] - callback function that receives the transcribed text
  /// [onListeningStateChanged] - optional callback for listening state changes
  Future<void> startListening({
    required Function(String) onResult,
    Function(bool)? onListeningStateChanged,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('Failed to initialize speech recognition');
        return;
      }
    }

    if (_isListening) {
      print('Already listening');
      return;
    }

    try {
      _isListening = true;
      onListeningStateChanged?.call(true);

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
        pauseFor: const Duration(seconds: 3), // Stop after 3 seconds of silence
        partialResults: false, // Only get final results
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  /// Cancel the current listening session
  Future<void> cancel() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.cancel();
      _isListening = false;
    } catch (e) {
      print('Error canceling speech recognition: $e');
    }
  }

  /// Get available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      return [];
    }

    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('Error getting available locales: $e');
      return [];
    }
  }

  /// Dispose of resources
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
  }
}
