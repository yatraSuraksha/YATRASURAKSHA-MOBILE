# SOS Video Backend Integration Guide

## Overview
The SOS video feature now automatically:
1. ✅ **Saves videos to device gallery** - All recorded videos are saved in the user's photo gallery
2. ✅ **Uploads videos to backend server** - Videos are sent to your server with metadata

## Quick Start

### 1. Configure Backend URL

In your app initialization (e.g., `main.dart` or before using SOS feature):

```dart
import 'package:yatra_suraksha_app/backend/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure SOS video backend endpoint
  ApiConfig.configureSosVideoApi(
    baseUrl: 'https://your-backend-domain.com',  // Replace with actual URL
  );
  
  runApp(MyApp());
}
```

### 2. Backend API Endpoint

The app will send POST requests to:
```
https://your-backend-domain.com/api/emergency/sos-video
```

### 3. Expected Request Format

**Method:** POST  
**Content-Type:** multipart/form-data

**Form Fields:**
```javascript
{
  video: File,                    // The video file (.mp4)
  recordingNumber: Integer,       // Sequential number (1, 2, 3...)
  timestamp: String,              // ISO 8601 format
  duration: Integer,              // Video duration in seconds (15)
  platform: String,               // "android" or "ios"
  latitude: Double,               // GPS latitude (if available)
  longitude: Double,              // GPS longitude (if available)
  accuracy: Double                // GPS accuracy in meters (if available)
}
```

**Headers:**
```
Content-Type: multipart/form-data
Authorization: Bearer <token>  // Add when authentication is ready
```

### 4. Backend Response Format

**Success Response (200/201):**
```json
{
  "success": true,
  "videoId": "unique-video-id",
  "message": "Video uploaded successfully",
  "storageUrl": "https://storage.example.com/videos/..."
}
```

**Error Response (4xx/5xx):**
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## Backend Implementation Example

### Node.js/Express Example:

```javascript
const express = require('express');
const multer = require('multer');
const app = express();

// Configure file upload
const storage = multer.diskStorage({
  destination: './uploads/sos-videos/',
  filename: (req, file, cb) => {
    const timestamp = Date.now();
    cb(null, `sos_${timestamp}_${file.originalname}`);
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 100 * 1024 * 1024 } // 100MB limit
});

// SOS Video upload endpoint
app.post('/api/emergency/sos-video', upload.single('video'), async (req, res) => {
  try {
    const {
      recordingNumber,
      timestamp,
      duration,
      platform,
      latitude,
      longitude,
      accuracy
    } = req.body;
    
    const videoFile = req.file;
    
    // Save to database
    const videoRecord = await db.sosVideos.create({
      filePath: videoFile.path,
      fileName: videoFile.filename,
      fileSize: videoFile.size,
      recordingNumber: parseInt(recordingNumber),
      timestamp: new Date(timestamp),
      duration: parseInt(duration),
      platform: platform,
      location: latitude && longitude ? {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        accuracy: parseFloat(accuracy)
      } : null
    });
    
    // Upload to cloud storage (S3, GCS, etc.) - optional
    // await uploadToCloudStorage(videoFile.path);
    
    res.status(200).json({
      success: true,
      videoId: videoRecord.id,
      message: 'SOS video uploaded successfully'
    });
    
  } catch (error) {
    console.error('Error uploading SOS video:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
```

### Python/Django Example:

```python
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.core.files.storage import default_storage
import json

@csrf_exempt
def upload_sos_video(request):
    if request.method == 'POST':
        try:
            video_file = request.FILES.get('video')
            recording_number = request.POST.get('recordingNumber')
            timestamp = request.POST.get('timestamp')
            duration = request.POST.get('duration')
            platform = request.POST.get('platform')
            latitude = request.POST.get('latitude')
            longitude = request.POST.get('longitude')
            accuracy = request.POST.get('accuracy')
            
            # Save file
            filename = default_storage.save(
                f'sos_videos/{video_file.name}', 
                video_file
            )
            
            # Save to database
            sos_video = SOSVideo.objects.create(
                file_path=filename,
                recording_number=int(recording_number),
                timestamp=timestamp,
                duration=int(duration),
                platform=platform,
                latitude=float(latitude) if latitude else None,
                longitude=float(longitude) if longitude else None,
                accuracy=float(accuracy) if accuracy else None
            )
            
            return JsonResponse({
                'success': True,
                'videoId': str(sos_video.id),
                'message': 'SOS video uploaded successfully'
            })
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)
```

## Testing Without Backend

The app will work without a configured backend:
- ✅ Videos will still be saved to gallery
- ⚠️ Server upload will fail gracefully with error logs
- 📝 Check debug console for upload attempts

To test, simply use the default placeholder URL.

## Adding Authentication

When your authentication system is ready, update the upload function:

1. Open `lib/backend/services/sos_video_service.dart`
2. Find the `_uploadVideoToBackend` method
3. Uncomment and update the authorization header:

```dart
final options = Options(
  headers: {
    'Content-Type': 'multipart/form-data',
    'Authorization': 'Bearer $authToken', // Add your token
  },
  ...
);
```

## Troubleshooting

### Videos not saving to gallery
- Check Android/iOS permissions are granted
- Verify storage permissions in manifest

### Upload failing
- Check backend URL is correct in `ApiConfig.configureSosVideoApi()`
- Verify backend endpoint is accessible
- Check server logs for errors
- Test with Postman/curl first

### Network timeout
- Increase timeout in `api_config.dart` if needed
- Check internet connection
- Verify file size isn't too large

## Storage Management

Videos are saved in:
- **Gallery:** User's device photo library
- **App Storage:** Temporary storage for upload
- **Backend:** Your server storage

To clean up old videos from app storage:
```dart
await sosVideoService.cleanupOldVideos(keepLastN: 5);
```

## Security Considerations

1. **Authentication:** Add JWT/OAuth tokens before production
2. **Encryption:** Consider encrypting videos in transit (HTTPS)
3. **Access Control:** Restrict video access to authorized users
4. **Storage Limits:** Implement quotas on backend
5. **Validation:** Verify file types and sizes on backend
