import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wiseai_sdk_plugin_method_channel.dart';

/// Platform-agnostic contract for the WiseAI SDK bridge.
///
/// The bridge speaks in raw event maps — one of:
///   `{ "source": "sdk",         "rawData": <verbatim SDK JSON>, "sessionId"?: "..." }`
///   `{ "source": "cancelled",   "rawData": "",                  "sessionId"?: "..." }`
///   `{ "source": "bridgeError", "rawData": <message>,           "sessionId"?: "..." }`
///
/// Classifying these into an [EkycResult] is pure Dart logic that lives in
/// `WiseaiSdkPlugin`, not here — this layer only carries bytes across the
/// platform boundary.
abstract class WiseaiSdkPluginPlatform extends PlatformInterface {
  /// Constructs a WiseaiSdkPluginPlatform.
  WiseaiSdkPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static WiseaiSdkPluginPlatform _instance = MethodChannelWiseaiSdkPlugin();

  /// The default instance of [WiseaiSdkPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelWiseaiSdkPlugin].
  static WiseaiSdkPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WiseaiSdkPluginPlatform] when
  /// they register themselves.
  static set instance(WiseaiSdkPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Stream of raw bridge events emitted by the native side.
  Stream<Map<String, dynamic>> get bridgeEvents {
    throw UnimplementedError('bridgeEvents has not been implemented.');
  }

  /// Start a MyKad eKYC flow. Fire-and-forget — the result arrives later on
  /// [bridgeEvents].
  Future<void> performMykadEkyc(Map<String, dynamic> args) {
    throw UnimplementedError('performMykadEkyc() has not been implemented.');
  }

  /// Start a Passport (optionally NFC) eKYC flow. Fire-and-forget — the
  /// result arrives later on [bridgeEvents].
  Future<void> performPassportNFCEkyc(Map<String, dynamic> args) {
    throw UnimplementedError(
      'performPassportNFCEkyc() has not been implemented.',
    );
  }

  /// Start a Face Verify flow. Fire-and-forget — the result arrives later on
  /// [bridgeEvents].
  Future<void> performFaceVerify(Map<String, dynamic> args) {
    throw UnimplementedError('performFaceVerify() has not been implemented.');
  }
}
