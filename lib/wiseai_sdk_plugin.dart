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

  /// Start a new session without encryption
  ///
  /// Returns a Map containing:
  /// - 'sessionId': The session ID (String, or null if not available)
  /// - 'fullData': The complete JSON response as a string
  Future<Map<String, dynamic>?> startNewSession() {
    return WiseaiSdkPluginPlatform.instance.startNewSession();
  }

  /// Start a new session with encryption
  ///
  /// Returns a Map containing:
  /// - 'sessionId': The session ID (String, or null if not available)
  /// - 'fullData': The complete JSON response as a string
  /// - 'encryptionConfig': The encryption configuration (if applicable)
  Future<Map<String, dynamic>?> startNewSessionWithEncryption() {
    return WiseaiSdkPluginPlatform.instance.startNewSessionWithEncryption();
  }

  /// Get the final session result
  Future<String?> getSessionResult() {
    return WiseaiSdkPluginPlatform.instance.getSessionResult();
  }

  /// Perform MyKad eKYC
  ///
  /// Parameters:
  /// - [exportDoc]: Set to true to get the base64 document image (default: true)
  /// - [exportFace]: Set to true to get the base64 face image (default: true)
  /// - [cameraFacing]: Camera facing direction, either "FRONT" or "BACK" (default: "FRONT")
  ///
  /// Returns a map containing the eKYC result data
  Future<Map<String, dynamic>> performEkyc({
    bool exportDoc = true,
    bool exportFace = true,
    String cameraFacing = "FRONT",
  }) {
    return WiseaiSdkPluginPlatform.instance.performEkyc(
      exportDoc: exportDoc,
      exportFace: exportFace,
      cameraFacing: cameraFacing,
    );
  }

  /// Perform Passport eKYC
  ///
  /// Parameters:
  /// - [exportDoc]: Set to true to get the base64 document image (default: true)
  /// - [exportFace]: Set to true to get the base64 face image (default: true)
  /// - [cameraFacing]: Camera facing direction, either "FRONT" or "BACK" (default: "FRONT")
  ///
  /// Returns a map containing the eKYC result data
  Future<Map<String, dynamic>> performPassportEkyc({
    bool exportDoc = true,
    bool exportFace = true,
    String cameraFacing = "FRONT",
  }) {
    return WiseaiSdkPluginPlatform.instance.performPassportEkyc(
      exportDoc: exportDoc,
      exportFace: exportFace,
      cameraFacing: cameraFacing,
    );
  }
}
