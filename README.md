# wiseai_sdk_plugin

A Flutter plugin wrapping the native WiseAI eKYC / Face Verify SDKs (Android & iOS).

## Requirements

- Android: `minSdk 28` (required by WiseAI SDK 3.x)
- iOS: `15.0` (required by `WiseAISDK.framework` 3.0.4)
- Camera permission (both platforms); NFC entitlement + permission for Passport NFC eKYC.

## Usage

```dart
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin.dart';

final plugin = WiseaiSdkPlugin();

// Listen before starting any flow — results arrive asynchronously.
plugin.resultStream.listen((EkycResult result) {
  switch (result.status) {
    case EkycStatus.success:
      // result.parsed has the decoded SDK JSON; result.rawData has it verbatim.
      break;
    case EkycStatus.sdkError:
      // result.errorCode / result.errorMessage from the SDK.
      break;
    case EkycStatus.cancelled:
      break;
    case EkycStatus.bridgeError:
      // Bridge couldn't reach the SDK (bad args, session-start failure, etc.).
      break;
  }
});

// MyKad eKYC
await plugin.performEkyc(
  Platform.isAndroid
      ? AndroidMyKadEkycConfig(apiToken: token, apiURL: url)
      : IosMyKadEkycConfig(apiToken: token, apiURL: url),
);

// Passport (optionally NFC) eKYC
await plugin.performPassportNFCEkyc(
  Platform.isAndroid
      ? AndroidPassportEkycConfig(apiToken: token, apiURL: url)
      : IosPassportEkycConfig(apiToken: token, apiURL: url, isNFC: true),
);

// Face Verify against a reference image
await plugin.performFaceVerify(
  Platform.isAndroid
      ? AndroidFaceVerifyConfig(apiToken: token, apiURL: url, faceImageBytes: bytes)
      : IosFaceVerifyConfig(apiToken: token, apiURL: url, faceImageBytes: bytes),
);

// Dispose when done (closes the result stream).
plugin.dispose();
```

See `example/lib` for a full runnable demo (MyKad, Passport NFC, and Face Verify
pages with EN/BM language switching).

## Bridge contract

The native side (`android/.../WiseaiSdkPlugin.kt`, `ios/Classes/WiseaiSdkPlugin.swift`)
forwards SDK responses verbatim over an `EventChannel` — it never reshapes the
JSON or decides success vs. error; that classification happens in
`WiseaiSdkPlugin` (Dart). See the doc comment at the top of each native file
for the exact event shape before changing either side.
