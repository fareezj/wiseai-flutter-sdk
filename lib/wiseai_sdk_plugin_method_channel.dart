import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wiseai_sdk_plugin_platform_interface.dart';

/// An implementation of [WiseaiSdkPluginPlatform] that uses method channels.
class MethodChannelWiseaiSdkPlugin extends WiseaiSdkPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.example/wiseai_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> initSDK({
    required String clientId,
    required String baseUrl,
  }) async {
    await methodChannel.invokeMethod('initSDK', {
      'clientId': clientId,
      'baseUrl': baseUrl,
    });
  }

  @override
  Future<void> setLanguageCode(String languageCode) async {
    await methodChannel.invokeMethod('setLanguageCode', {
      'languageCode': languageCode,
    });
  }

  @override
  Future<String?> startNewSession({bool withEncryption = false}) async {
    final result = await methodChannel.invokeMethod<String>('startNewSession', {
      'withEncryption': withEncryption,
    });
    return result;
  }

  @override
  Future<String?> getSessionResult() async {
    final result = await methodChannel.invokeMethod<String>('getSessionResult');
    return result;
  }
}
