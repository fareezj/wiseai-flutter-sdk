# Android eKYC Integration - Fixed Issues

## Issues Fixed

### 1. TLS Protocol Error (TLSv1.1 not supported)
**Problem:** `java.lang.IllegalArgumentException: protocol TLSv1.1 is not supported`

**Solution:**
- Updated WiseAI SDK from `2.5.0` to `2.7.3` (latest version with better TLS support)
- Set `minSdk = 24` (Android 7.0+) as required by SDK 2.7.0+

### 2. Duplicate Session Starts
**Problem:** App was calling `startNewSession()` twice before performing eKYC

**Solution:** Removed the duplicate call - only call `startNewSession()` once before each eKYC operation

## Configuration

### Android Plugin ([android/build.gradle](android/build.gradle))
```gradle
dependencies {
    implementation ("com.wiseai.ekyc:app:2.7.3")  // Updated to latest
    implementation ("com.google.code.gson:gson:2.10")
}

defaultConfig {
    minSdk = 24  // Required by WiseAI SDK 2.7.0+
}
```

### Example App ([example/android/app/build.gradle.kts](example/android/app/build.gradle.kts))
```kotlin
defaultConfig {
    minSdk = 24  // Required by WiseAI SDK 2.7.0+
    multiDexEnabled = true
}
```

## Correct Usage Pattern

```dart
final plugin = WiseaiSdkPlugin();

// 1. Initialize SDK once
await plugin.initSDK(
  clientId: 'YOUR_API_TOKEN',
  baseUrl: 'https://wiseconsole-demo.wiseai.tech/',
);

// 2. Set language
await plugin.setLanguageCode('en');

// 3. Start a new session (only once before eKYC)
await plugin.startNewSession(withEncryption: false);

// 4. Perform eKYC
try {
  final result = await plugin.performEkyc(
    exportDoc: true,
    exportFace: true,
    cameraFacing: "FRONT",
  );
  print('eKYC Result: $result');
} catch (e) {
  print('eKYC Error: $e');
}
```

## Important Notes

1. **Session Management**: Start a new session only once before each eKYC operation
2. **Minimum Android Version**: Android 7.0 (API 24) or higher is required
3. **Firebase Setup**: Ensure you replace the placeholder `google-services.json` with your actual Firebase configuration
4. **TLS Support**: SDK 2.7.3 uses modern TLS protocols (TLSv1.2+) compatible with current Android versions
5. **Testing**: Always test on a real device as eKYC requires camera access

## SDK Version Features (2.7.3)

- Support for 16 KB page sizes (Google Play requirement)
- Enhanced Quality Checking on MyKad
- Enhanced active liveness detection
- Bug fixes for document quality checking in HYBRID mode
- UI enhancements
- Better TLS/SSL support

## Troubleshooting

### If you still get TLS errors:
1. Ensure your device is running Android 7.0 (API 24) or higher
2. Check that the baseUrl uses `https://` (not `http://`)
3. Verify your Firebase configuration is properly set up
4. Clear the build cache: `flutter clean && cd android && ./gradlew clean`

### If eKYC doesn't launch:
1. Check that permissions are granted (Camera, Location)
2. Verify the API token is valid
3. Check logs for specific error messages
4. Ensure session was started successfully before calling performEkyc
