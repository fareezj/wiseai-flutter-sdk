import 'wiseai_sdk_plugin_platform_interface.dart';

class WiseaiSdkPlugin {
  Future<String?> getPlatformVersion() {
    return WiseaiSdkPluginPlatform.instance.getPlatformVersion();
  }

  /// Initialize the WiseAI SDK with client credentials
  Future<void> initSDK({required String clientId, required String baseUrl}) {
    return WiseaiSdkPluginPlatform.instance.initSDK(
      clientId: clientId,
      baseUrl: baseUrl,
    );
  }

  /// Set the language code for the SDK
  Future<void> setLanguageCode(String languageCode) {
    return WiseaiSdkPluginPlatform.instance.setLanguageCode(languageCode);
  }

  /// Start a new session with optional encryption
  Future<String?> startNewSession({bool withEncryption = false}) {
    return WiseaiSdkPluginPlatform.instance.startNewSession(
      withEncryption: withEncryption,
    );
  }

  /// Get the final session result
  Future<String?> getSessionResult() {
    return WiseaiSdkPluginPlatform.instance.getSessionResult();
  }
}
