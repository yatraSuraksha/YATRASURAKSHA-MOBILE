import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:yatra_suraksha_app/backend/services/sos_video_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen SOS video recording interface
/// Shows camera preview with recording status and controls
class SOSRecordingScreen extends StatefulWidget {
  const SOSRecordingScreen({super.key});

  @override
  State<SOSRecordingScreen> createState() => _SOSRecordingScreenState();
}

class _SOSRecordingScreenState extends State<SOSRecordingScreen> {
  late SOSVideoService _videoService;
  bool _isInitializing = false; // Changed to false - camera already initialized
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _videoService = Provider.of<SOSVideoService>(context, listen: false);

    // Listen for recording state changes
    _videoService.addListener(_onRecordingStateChanged);

    // Check if camera is already initialized and recording
    if (!_videoService.isInitialized || !_videoService.isRecording) {
      // Fallback: initialize if not already done
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _videoService.removeListener(_onRecordingStateChanged);
    super.dispose();
  }

  void _onRecordingStateChanged() {
    // Auto-close screen when recording stops
    if (!_videoService.isRecording && mounted) {
      debugPrint('📱 Recording stopped, closing screen...');
      Navigator.of(context).pop();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
    });

    final success = await _videoService.initialize();

    if (success) {
      // Start recording automatically
      await _videoService.startSOSRecording();
      setState(() {
        _isInitializing = false;
      });
    } else {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Failed to initialize camera. Please check permissions.';
      });
    }
  }

  Future<void> _stopAndExit() async {
    await _videoService.stopRecording();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _stopAndExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _isInitializing
              ? _buildLoadingScreen()
              : _errorMessage != null
                  ? _buildErrorScreen()
                  : _buildRecordingScreen(),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          Text(
            'Initializing camera...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingScreen() {
    return Consumer<SOSVideoService>(
      builder: (context, service, child) {
        // Show camera preview if service is initialized
        if (!service.isInitialized ||
            service.cameraController == null ||
            !service.cameraController!.value.isInitialized) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Preparing camera...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Camera preview (full screen)
            Positioned.fill(
              child: CameraPreview(service.cameraController!),
            ),

            // Top status bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(service),
            ),

            // Recording indicator
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: _buildRecordingIndicator(service),
            ),

            // Countdown timer (center)
            Center(
              child: _buildCountdownTimer(service),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(service),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(SOSVideoService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Recording status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RECORDING',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Camera switch button
          IconButton(
            onPressed: () => service.switchCamera(),
            icon: const Icon(
              Icons.cameraswitch,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(SOSVideoService service) {
    return Column(
      children: [
        Text(
          'SOS Emergency Recording',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recording ${service.currentRecordingNumber} of ${SOSVideoService.maxRecordingClips}',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownTimer(SOSVideoService service) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
        border: Border.all(
          color: Colors.red,
          width: 4,
        ),
      ),
      child: Center(
        child: Text(
          '${service.secondsRemaining}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(SOSVideoService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Video will be sent to emergency services automatically',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stop button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _stopAndExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stop_circle_outlined, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'STOP SOS',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
