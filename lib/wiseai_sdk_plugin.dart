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
  ///
  /// Returns a Map containing:
  /// - 'sessionId': The session ID (String)
  /// - 'fullData': The complete JSON response as a string
  /// - 'encryptionConfig': The encryption configuration (if withEncryption is true)
  Future<Map<String, dynamic>?> startNewSession({bool withEncryption = false}) {
    return WiseaiSdkPluginPlatform.instance.startNewSession(
      withEncryption: withEncryption,
    );
  }

  /// Start a new session with encryption enabled
  ///
  /// This is a convenience method equivalent to calling:
  /// ```dart
  /// startNewSession(withEncryption: true)
  /// ```
  ///
  /// Returns a Map containing:
  /// - 'sessionId': The session ID (String)
  /// - 'encryptionConfig': The encryption configuration (String)
  /// - 'fullData': The complete JSON response as a string
  ///
  /// Example:
  /// ```dart
  /// final sessionData = await wiseaiSdkPlugin.startNewSessionWithEncryption();
  /// final sessionId = sessionData['sessionId'];
  /// final encryptionConfig = sessionData['encryptionConfig'];
  ///
  /// // Later, decrypt results using the encryption config
  /// final decrypted = await wiseaiSdkPlugin.decryptResult(
  ///   encryptedJson: encryptedResult,
  ///   encryptionConfig: encryptionConfig,
  /// );
  /// ```
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

  /// Decrypt encrypted result from WiseAI SDK
  ///
  /// This method decrypts an encrypted JSON result using the provided encryption configuration.
  /// Use this after receiving an encrypted result from the SDK (e.g., from startNewSessionWithEncryption).
  ///
  /// Parameters:
  /// - [encryptedJson]: The encrypted JSON string result from the SDK
  /// - [encryptionConfig]: The encryption configuration as JSON string (obtained from startNewSessionWithEncryption)
  ///
  /// Returns a map containing both encrypted and decrypted results:
  /// - 'encryptedResult': The original encrypted result
  /// - 'decryptedResult': The decrypted result as a JSON string
  ///
  /// Example:
  /// ```dart
  /// final sessionData = await wiseaiSdkPlugin.startNewSessionWithEncryption();
  /// final encryptionConfig = sessionData['encryptionConfig'];
  ///
  /// // After performing eKYC and getting encrypted result
  /// final result = await wiseaiSdkPlugin.decryptResult(
  ///   encryptedJson: encryptedResult,
  ///   encryptionConfig: encryptionConfig,
  /// );
  ///
  /// print('Encrypted: ${result['encryptedResult']}');
  /// print('Decrypted: ${result['decryptedResult']}');
  /// ```
  Future<Map<String, dynamic>> decryptResult({
    required String encryptedJson,
    required String encryptionConfig,
  }) {
    return WiseaiSdkPluginPlatform.instance.decryptResult(
      encryptedJson: encryptedJson,
      encryptionConfig: encryptionConfig,
    );
  }
}
