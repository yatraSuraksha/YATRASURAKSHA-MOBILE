# Voice-Activated SOS Feature

## Overview
This feature adds multilingual voice-activated emergency detection to the Yatra Suraksha app. Users can speak emergency requests in any language, and the system will automatically trigger the SOS functionality.

## Features
- **Multilingual Support**: Detects emergency requests in multiple languages including:
  - English, Hindi, Spanish, French, German
  - Portuguese, Italian, Russian, Arabic
  - Chinese, Japanese, Korean, and more

- **AI-Powered Detection**: Uses Google's Gemini 2.0 Flash model via Firebase Vertex AI to intelligently detect emergency/help requests

- **Speech Recognition**: Real-time speech-to-text conversion with support for multiple languages

- **Visual Feedback**: Microphone button with visual states (idle/listening) and status messages

## How It Works

1. **User taps the microphone button** below the main SOS button
2. **Speech recognition starts** - user can speak in any language
3. **Text is transcribed** from speech to text
4. **AI analyzes the text** to determine if it's an emergency/help request
5. **SOS is triggered automatically** if emergency is detected

## Setup Instructions

### 1. Dependencies Added
The following packages have been added to `pubspec.yaml`:
```yaml
firebase_vertexai: ^2.2.0  # For Gemini AI
speech_to_text: ^7.0.0     # For voice recognition
```

### 2. Android Permissions
Microphone permissions have been added to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### 3. Firebase Configuration
Make sure Firebase is properly configured in your project:
- `firebase_options.dart` should be present
- Firebase project should have Vertex AI enabled
- Ensure you're on a Firebase plan that supports Vertex AI (Blaze plan recommended)

### 4. Enable Vertex AI in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to "Build" → "Vertex AI in Firebase"
4. Enable the API if not already enabled
5. Make sure billing is set up (required for Gemini API)

## Files Created/Modified

### New Services
1. **`lib/backend/services/gemini_ai_service.dart`**
   - Handles AI-powered emergency detection
   - Uses Gemini 2.0 Flash model
   - Includes fallback keyword detection

2. **`lib/backend/services/voice_recognition_service.dart`**
   - Manages speech-to-text functionality
   - Handles microphone permissions
   - Provides listening state management

### Modified Files
1. **`lib/pages/home/hometab.dart`**
   - Added voice SOS button UI
   - Integrated voice recognition and AI services
   - Added state management for listening status

2. **`pubspec.yaml`**
   - Added firebase_vertexai and speech_to_text dependencies

3. **`android/app/src/main/AndroidManifest.xml`**
   - Added microphone and Bluetooth permissions

## Usage

### For Users
1. Tap the green microphone button below the main SOS button
2. Button turns orange and shows "Listening..."
3. Speak your emergency request in any language, for example:
   - "Help me!" (English)
   - "मदद करो!" (Hindi)
   - "¡Ayuda!" (Spanish)
   - "Aidez-moi!" (French)
   - "救命!" (Chinese)
4. The app will automatically detect the emergency and trigger SOS

### Emergency Keywords Detected
The AI detects variations of:
- Help / मदद / ayuda / aide / hilfe
- Emergency / आपातकाल / emergencia / urgence
- Danger / खतरा / peligro / danger / опасность
- Rescue / बचाओ / rescate / sauvetage
- SOS / Save me

## Testing

### Test the Feature
1. Run the app: `flutter run`
2. Navigate to the home screen
3. Tap the microphone button
4. Grant microphone permission when prompted
5. Speak a test phrase like "Help me"
6. Verify that the SOS dialog appears

### Debug Mode
Check the console logs for:
- Speech recognition status
- Transcribed text
- AI analysis results
- Error messages

## Error Handling
- If microphone permission is denied, an error message is shown
- If speech recognition fails, the service gracefully handles it
- If AI service is unavailable, falls back to keyword-based detection
- All errors are logged to console for debugging

## Performance Considerations
- Speech recognition runs for up to 10 seconds per session
- Stops automatically after 3 seconds of silence
- AI analysis happens in real-time (typically < 2 seconds)
- Minimal battery impact when not actively listening

## Privacy & Security
- Audio is processed locally on device for speech-to-text
- Only transcribed text (not audio) is sent to Gemini AI
- No audio recordings are stored
- Complies with user privacy expectations for emergency apps

## Future Enhancements
- Add support for more languages
- Implement offline keyword detection
- Add voice feedback confirmation
- Support for continuous listening mode
- Custom emergency phrases configuration

## Troubleshooting

### Microphone Permission Issues
- Ensure permissions are granted in device settings
- Check AndroidManifest.xml has RECORD_AUDIO permission
- Try reinstalling the app

### AI Detection Not Working
- Verify Firebase Vertex AI is enabled
- Check Firebase project billing status
- Review console logs for API errors
- Ensure internet connection is available

### Speech Recognition Issues
- Check device microphone is working
- Ensure no other app is using microphone
- Try speaking more clearly or closer to device
- Verify speech_to_text package is properly installed

## Cost Considerations
- Gemini 2.0 Flash is cost-effective for this use case
- Firebase Vertex AI has a free tier
- Check [Firebase Pricing](https://firebase.google.com/pricing) for details
- Monitor usage in Firebase Console

## Support
For issues or questions:
1. Check console logs for error messages
2. Verify all dependencies are installed: `flutter pub get`
3. Ensure Firebase configuration is correct
4. Test microphone permissions in device settings
