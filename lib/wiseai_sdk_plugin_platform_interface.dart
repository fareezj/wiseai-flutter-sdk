import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wiseai_sdk_plugin_method_channel.dart';

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

  Future<void> initSDK({required String clientId, required String baseUrl}) {
    throw UnimplementedError('initSDK() has not been implemented.');
  }

  Future<void> setLanguageCode(String languageCode) {
    throw UnimplementedError('setLanguageCode() has not been implemented.');
  }

  Future<String?> startNewSession({bool withEncryption = false}) {
    throw UnimplementedError('startNewSession() has not been implemented.');
  }

  Future<String?> getSessionResult() {
    throw UnimplementedError('getSessionResult() has not been implemented.');
  }
}
