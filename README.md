# Vapi Flutter SDK

## Minimum requirements
The Daily Client SDK for Flutter requires the following versions:

- Flutter ≥ 3.0.0
- iOS ≥ 13.0 (objective-C and Swift applications are supported)
- Android compileSdkVersion ≥ 33
- Android minSdkVersion ≥ 24
- Android NDK ≥ 25.1.8937393

## Setup
Add `vapi_flutter` as a dependency: 

```
flutter pub add vapi_flutter
```

Follow the platform-specific setup instructions for `permission_handler``.

### iOS
According to the permission_handler instructions above, add the permission flags for camera and microphone.

Also add this to your Info.plist:
```
<key>NSMicrophoneUsageDescription</key>
<string>This app requires access to the microphone for live audio calls.</string>
```

We recommend adding the audio background mode to your app's capabilities.

### Android
Add the necessary permissions to your AndroidManifest.xml:

```<uses-permission android:name="android.permission.INTERNET" /> <uses-permission android:name="android.permission.CAMERA" /> <uses-permission android:name="android.permission.RECORD_AUDIO" /> <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />```

Add the permission flags for camera and microphone according to the permission_handler instructions above.







