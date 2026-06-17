import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wiseai_sdk_plugin_platform_interface.dart';

/// An implementation of [WiseaiSdkPluginPlatform] that uses method/event
/// channels. Channel names must match the native bridge exactly — see
/// android/.../WiseaiSdkPlugin.kt and ios/Classes/WiseaiSdkPlugin.swift.
class MethodChannelWiseaiSdkPlugin extends WiseaiSdkPluginPlatform {
  /// The method channel used to invoke SDK operations on the native side.
  @visibleForTesting
  final methodChannel = const MethodChannel('WiseAiMethods');

  /// The event channel the native side uses to stream back SDK results.
  @visibleForTesting
  final eventChannel = const EventChannel(
    'com.wiseai.wiseai_sdk_plugin/events',
  );

  Stream<Map<String, dynamic>>? _bridgeEvents;

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Stream<Map<String, dynamic>> get bridgeEvents {
    return _bridgeEvents ??= eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
  }

  @override
  Future<void> performMykadEkyc(Map<String, dynamic> args) {
    return methodChannel.invokeMethod('performMykadEkyc', args);
  }

  @override
  Future<void> performPassportNFCEkyc(Map<String, dynamic> args) {
    return methodChannel.invokeMethod('performPassportNFCEkyc', args);
  }

  @override
  Future<void> performFaceVerify(Map<String, dynamic> args) {
    return methodChannel.invokeMethod('performFaceVerify', args);
  }
}
