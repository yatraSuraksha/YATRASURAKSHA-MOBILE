# Google Places API Setup Guide

This guide will help you set up the Google Places API for the Yatra Suraksha emergency app to fetch real-time hospital and police station data.

## Prerequisites
- Google Cloud Platform account
- Credit card (required for Google Cloud, but you get $300 free credits)

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Create Project"** or select an existing project
3. Give your project a name (e.g., "Yatra-Suraksha-Emergency-App")
4. Click **"Create"**

## Step 2: Enable Required APIs

1. In the Google Cloud Console, go to **"APIs & Services"** > **"Library"**
2. Search for and enable the following APIs:
   - **Places API** (for nearby places)
   - **Maps SDK for Android** (for map display on Android)
   - **Maps SDK for iOS** (for map display on iOS)
   - **Geocoding API** (optional, for address lookups)

## Step 3: Create API Key

1. Go to **"APIs & Services"** > **"Credentials"**
2. Click **"+ CREATE CREDENTIALS"** > **"API key"**
3. Your API key will be created and displayed
4. **IMPORTANT**: Click "Edit API key" to restrict it for security

### Restrict Your API Key (HIGHLY RECOMMENDED)

#### Application Restrictions:
- For **Android**: Select "Android apps" and add your package name
  - Package name: `com.example.yatra_suraksha_app` (or your actual package name)
  - Get SHA-1 certificate fingerprint:
    ```bash
    # For debug key (development)
    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
    
    # For release key (production)
    keytool -list -v -keystore your-release-key.jks -alias your-key-alias
    ```

- For **iOS**: Select "iOS apps" and add your bundle identifier
  - Bundle ID: `com.example.yatraSurakshaApp` (or your actual bundle ID)

#### API Restrictions:
- Select "Restrict key"
- Check only the APIs you're using:
  - ✓ Places API
  - ✓ Maps SDK for Android
  - ✓ Maps SDK for iOS
  - ✓ Geocoding API (if using)

5. Click **"Save"**

## Step 4: Set Up Environment Variables

### Create .env File

1. In your project root directory (`YATRA-SURAKSHA-APP-master`), create a file named `.env`
2. Add your Google Places API key:

```env
# Google Places API Key
GOOGLE_PLACES_API_KEY=YOUR_API_KEY_HERE

# Other API Keys (if you have them)
CLAUDE_API_KEY=your_claude_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

3. Replace `YOUR_API_KEY_HERE` with your actual API key from Step 3

### Important Security Notes:
- ✅ The `.env` file is already in `.gitignore` - **NEVER commit it to Git**
- ✅ Never share your API keys publicly
- ✅ Use API restrictions to prevent unauthorized usage
- ✅ Monitor your API usage in Google Cloud Console

## Step 5: Configure Android

### Add API Key to AndroidManifest.xml

Edit `android/app/src/main/AndroidManifest.xml` and add inside the `<application>` tag:

```xml
<application>
    <!-- Add this meta-data inside application tag -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
    
    <!-- Rest of your application configuration -->
</application>
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

## Step 6: Configure iOS

### Add API Key to AppDelegate.swift

Edit `ios/Runner/AppDelegate.swift` and add the import and configuration:

```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line with your API key
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

## Step 7: Verify Dependencies

Ensure `flutter_dotenv` is in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_dotenv: ^5.1.0  # For loading environment variables
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  http: ^1.1.0
  # ... other dependencies
```

Run:
```bash
flutter pub get
```

## Step 8: Test the Integration

1. Run your app on a real device (location services work better on real devices)
2. Navigate to "Nearby Hospitals" or "Nearby Police Stations"
3. Grant location permissions when prompted
4. The app should now fetch real-time data from Google Places API

## Troubleshooting

### API Key Not Working?
- ✅ Wait 5-10 minutes after creating the API key for it to activate
- ✅ Check that the APIs are enabled in Google Cloud Console
- ✅ Verify API restrictions match your app's package name/bundle ID
- ✅ Check that the SHA-1 fingerprint is correct (for Android)
- ✅ Monitor "APIs & Services" > "Dashboard" for errors

### Location Not Working?
- ✅ Enable location services on your device
- ✅ Grant location permissions to the app
- ✅ Test on a real device (emulators may have issues)
- ✅ Check internet connectivity

### No Results Returned?
- ✅ The app falls back to mock data if API fails (check console logs)
- ✅ Increase the search radius in `places_service.dart` (default: 5000m = 5km)
- ✅ Check your API usage quota in Google Cloud Console
- ✅ Verify you're in a location with hospitals/police stations nearby

### API Usage Limits
- Google Places API has usage limits
- New accounts get $300 free credits (valid for 90 days)
- Monitor usage: Google Cloud Console > "APIs & Services" > "Dashboard"
- Set up billing alerts to avoid unexpected charges

## API Features Implemented

✅ **Real-time Location Data**
- Fetches hospitals and police stations based on GPS location
- Updates automatically when location changes (every 50 meters)

✅ **Complete Place Information**
- Name, address, phone number
- Distance from user (sorted nearest first)
- Ratings and reviews
- Operating hours (open/closed status)

✅ **Map Display**
- Interactive Google Maps
- Markers for user location and places
- Click markers for details
- "Get Directions" button

✅ **Error Handling**
- Graceful fallback to mock data if API fails
- Loading indicators
- Error messages for no internet/location denied

✅ **Security**
- API key loaded from environment variables
- Proper API restrictions
- .env file in .gitignore

## Cost Estimation

Google Places API pricing (as of 2024):
- **Nearby Search**: $32 per 1,000 requests
- **Place Details**: $17 per 1,000 requests
- **Free tier**: $200/month credit

**Estimated usage for your app:**
- Typical user: 10-20 searches per session
- With caching and mock fallback, costs should be minimal
- Monitor usage to stay within free tier

## Support

For issues with Google Cloud Platform:
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Google Cloud Support](https://cloud.google.com/support)

For app-specific issues:
- Check the app's debug console for error messages
- Review `places_service.dart` for API call details
