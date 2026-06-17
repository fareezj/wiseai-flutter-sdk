# Android eKYC Integration Notes

> The plugin's public API and native bridge contract changed when the
> WiseAI integration sample (event-channel based, MyKad / Passport NFC /
> Face Verify) was adopted. The sequence described below (`initSDK` →
> `setLanguageCode` → `startNewSession` → `performEkyc(exportDoc:...)`) no
> longer exists. See [README.md](README.md) for the current usage pattern.

## SDK version & minimum Android version

- WiseAI Android SDK: `com.wiseai.ekyc:app:3.0.2` ([android/build.gradle](android/build.gradle))
- `minSdk = 28` — required by SDK 3.x (the 2.7.x-era `minSdk = 24` requirement
  no longer applies)
- Same `minSdk` is set in the example app
  ([example/android/app/build.gradle.kts](example/android/app/build.gradle.kts))

## Gradle repositories

Two GitHub Packages maven repos are required to resolve the SDK and its
Face Verify transitive dependency — both are declared in
[android/build.gradle](android/build.gradle) (and mirrored in
[example/android/build.gradle.kts](example/android/build.gradle.kts)):

```gradle
maven { url = uri("https://maven.pkg.github.com/WiseAI-Tech/ekyc110") }
maven { url = uri("https://maven.pkg.github.com/WiseAI-Tech/ekyc110-face-verify") }
```

> The credentials embedded in these `maven` blocks predate this change and
> are committed in plaintext. Rotate/replace them with your own GitHub
> Packages PAT before publishing this plugin anywhere public.

## Bridge contract

`android/src/main/kotlin/.../WiseaiSdkPlugin.kt` never parses or reshapes
the SDK's response — it forwards it verbatim over an `EventChannel`, plus
two non-SDK event sources (`cancelled`, `bridgeError`). See the doc comment
at the top of that file for the exact event shape before changing it; the
Dart side classifies the payload in `WiseaiSdkPlugin.resultStream`.

## Testing

eKYC, Passport NFC, and Face Verify all require a real device — camera
access (and NFC hardware for the NFC flow) isn't available on the emulator.
