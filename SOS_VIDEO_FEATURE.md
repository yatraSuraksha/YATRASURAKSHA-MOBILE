# SOS Video Recording Feature

## Overview
The SOS Video Recording feature automatically captures continuous 15-second video clips with audio during emergency situations. Videos are prepared for sending to emergency services and stored locally until transmission is confirmed.

## Features

### ✅ Implemented
- **Automatic Recording**: Camera opens and starts recording immediately upon SOS activation
- **15-Second Cycles**: Each recording is exactly 15 seconds long
- **Continuous Recording**: Automatically starts next recording after completing current one
- **Audio Capture**: Records both video and audio
- **720p Quality**: Balanced quality (medium resolution) for optimal file size
- **Camera Switching**: Toggle between front and back camera during recording
- **Metadata Collection**: 
  - Recording number
  - Timestamp (start/end)
  - GPS location (if available)
  - Device platform
  - File size
- **Visual Indicators**:
  - Recording status (red dot + "RECORDING" badge)
  - Countdown timer (15, 14, 13...)
  - Recording number (Recording 1 of ∞, Recording 2 of ∞...)
- **User Controls**:
  - Stop SOS button to end recording cycle
  - Camera switch button
- **Permission Handling**: Proper camera, microphone, and location permissions
- **Error Handling**: Graceful handling of permission denials and camera failures

### 🔄 Placeholder (Ready for Server Integration)
The following function is prepared and ready for backend implementation:

```dart
Future<Map<String, dynamic>> _prepareVideoForServer(
  XFile videoFile,
  Map<String, dynamic> metadata,
) async {
  // TODO: Implement when server is ready
  // Expected endpoint: POST /api/emergency/sos-video
  // Should send:
  //   - video file (multipart/form-data)
  //   - metadata as JSON
  //   - user authentication token
  //   - emergency session ID (if applicable)
}
```

## File Structure

```
lib/
├── backend/
│   └── services/
│       └── sos_video_service.dart    # Core SOS recording service
├── pages/
│   └── home/
│       ├── hometab.dart              # SOS button trigger
│       └── sos_recording_screen.dart  # Recording UI
└── main.dart                         # Provider setup
```

## Usage

### For Users
1. Press SOS button on home screen
2. Camera automatically opens and starts recording
3. First 15-second video is recorded
4. Video is prepared for sending (currently placeholder)
5. Next 15-second recording starts automatically
6. Process continues until "STOP SOS" button is pressed

### For Developers

#### Installation
```bash
flutter pub get
```

#### Permissions Required
**Android** (`AndroidManifest.xml`):
- `CAMERA`
- `RECORD_AUDIO`
- `WRITE_EXTERNAL_STORAGE`
- `READ_EXTERNAL_STORAGE`

**iOS** (`Info.plist`):
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryUsageDescription`

#### Service Integration
The `SOSVideoService` is provided via Provider in `main.dart`:

```dart
ChangeNotifierProvider(create: (_) => SOSVideoService()),
```

#### Starting Recording
```dart
// Navigate to recording screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const SOSRecordingScreen(),
  ),
);
```

## Technical Implementation

### Recording Flow
1. **Initialization**
   - Camera controller initialized with medium resolution (720p)
   - Audio enabled
   - Service marked as ready

2. **Recording Cycle**
   ```
   Start Recording (15s) → Stop Recording → 
   Collect Metadata → Prepare for Server → 
   Start Next Recording (15s) → ...
   ```

3. **Metadata Collection**
   ```dart
   {
     'recordingNumber': 1,
     'timestamp': '2026-01-03T...',
     'filePath': '/data/user/0/.../sos_video_1_1234567890.mp4',
     'fileSize': 2457600,  // bytes
     'duration': 15,
     'location': {
       'latitude': 16.5653918,
       'longitude': 81.5215735,
       'accuracy': 15.0
     },
     'platform': 'android'
   }
   ```

4. **Video Storage**
   - Stored in app documents directory
   - Filename format: `sos_video_{number}_{timestamp}.mp4`
   - Cleanup function available to delete old videos

### Server Integration (To Be Implemented)

When the server endpoint is ready, implement the following:

```dart
Future<Map<String, dynamic>> _prepareVideoForServer(
  XFile videoFile,
  Map<String, dynamic> metadata,
) async {
  final uri = Uri.parse('${apiBaseUrl}/api/emergency/sos-video');
  final request = http.MultipartRequest('POST', uri);
  
  // Add auth headers
  request.headers['Authorization'] = 'Bearer $userToken';
  
  // Add video file
  request.files.add(
    await http.MultipartFile.fromPath('video', videoFile.path)
  );
  
  // Add metadata
  request.fields['metadata'] = jsonEncode(metadata);
  request.fields['userId'] = userId;
  request.fields['sessionId'] = emergencySessionId;
  
  final response = await request.send();
  final responseData = await response.stream.bytesToString();
  
  if (response.statusCode == 200) {
    final result = jsonDecode(responseData);
    
    // Clean up local file after successful upload
    await File(videoFile.path).delete();
    
    return result;
  } else {
    throw Exception('Upload failed');
  }
}
```

#### Expected Server Endpoint
```
POST /api/emergency/sos-video
Content-Type: multipart/form-data

Fields:
- video: File (MP4 format, ~2-5MB per 15s)
- metadata: JSON string
- userId: String
- sessionId: String (optional, for linking multiple videos in one emergency)

Response:
{
  "success": true,
  "videoId": "uuid",
  "message": "Video received and processing"
}
```

## Testing Recommendations

### Unit Tests
```dart
// Test video service initialization
test('SOSVideoService initializes camera', () async {
  final service = SOSVideoService();
  final result = await service.initialize();
  expect(result, true);
  expect(service.isInitialized, true);
});

// Test recording cycle
test('Recording completes 15-second cycle', () async {
  final service = SOSVideoService();
  await service.initialize();
  await service.startSOSRecording();
  
  await Future.delayed(Duration(seconds: 16));
  expect(service.currentRecordingNumber, 2); // Should be on 2nd recording
});
```

### Manual Testing
1. **Normal Flow**: Press SOS → Verify recording starts → Wait 15s → Verify new recording starts
2. **Stop Flow**: Press SOS → Wait 5s → Press STOP → Verify recording stops and saves
3. **Camera Switch**: While recording → Press camera switch → Verify camera changes
4. **Permission Denial**: Deny camera permission → Verify error screen shows
5. **Low Storage**: Fill device storage → Verify error handling

## Performance Considerations

### File Sizes
- 720p, 15 seconds ≈ 2-5 MB per video
- 10 recordings ≈ 20-50 MB

### Battery Impact
- Camera usage: High
- Continuous recording: ~5-10% battery per minute
- Recommendation: Notify users of battery drain

### Storage Management
```dart
// Clean up old videos, keep only last 5
await sosVideoService.cleanupOldVideos(keepLastN: 5);
```

## Error Handling

### Camera Permission Denied
```dart
if (!success) {
  // Show error screen with instructions
  // Prompt user to enable permissions in settings
}
```

### Camera Already in Use
```dart
try {
  await _cameraController!.initialize();
} catch (e) {
  // Show "Camera in use by another app" message
  // Provide retry button
}
```

### Storage Full
```dart
try {
  await _cameraController!.startVideoRecording();
} catch (e) {
  if (e.toString().contains('storage')) {
    // Show "Storage full" message
    // Suggest cleaning up old videos
  }
}
```

## Future Enhancements

- [ ] Configurable recording duration (10s, 15s, 30s)
- [ ] Video compression before upload
- [ ] Retry mechanism for failed uploads
- [ ] Emergency contact notification with video links
- [ ] Live streaming option (when network available)
- [ ] Picture-in-picture mode for recording
- [ ] Flash/torch control during recording
- [ ] Video watermark with timestamp

## Dependencies

```yaml
dependencies:
  camera: ^0.11.0+2          # Camera access and recording
  path_provider: ^2.1.4       # File system paths
  video_player: ^2.10.0       # Video preview (if needed)
  geolocator: ^10.1.1         # GPS location
  provider: ^6.1.5+1          # State management
  http: ^1.2.2                # Server communication (when ready)
```

## Support

For issues or questions:
1. Check debug logs (look for 🎥, ✅, ❌, ⚠️ prefixes)
2. Verify permissions are granted
3. Check device storage availability
4. Review error messages in UI

## License

Part of Yatra Suraksha - Tourist Safety Application
