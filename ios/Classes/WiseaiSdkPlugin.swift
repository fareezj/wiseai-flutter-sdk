import Flutter
import UIKit
import WiseAISDK

// Private delegate handler to avoid exposing WiseAiDelegate to Objective-C
private class WiseAiDelegateHandler: NSObject, WiseAiDelegate {
  weak var plugin: WiseaiSdkPlugin?
  
  init(plugin: WiseaiSdkPlugin) {
    self.plugin = plugin
    super.init()
  }
  
  func onEkycComplete(_ jsonResult: String) {
    plugin?.handleEkycComplete(jsonResult)
  }
  
  func onEkycException(_ jsonResult: String) {
    plugin?.handleEkycException(jsonResult)
  }
  
  func onEkycCancelled() {
    plugin?.handleEkycCancelled()
  }
  
  func getSessionIdAndEncryptionConfig(_ sessionIDandConfig: String) {
    plugin?.handleSessionIdAndEncryptionConfig(sessionIDandConfig)
  }
}

@objc(WiseaiSdkPlugin)
public class WiseaiSdkPlugin: NSObject, FlutterPlugin {
  private var wiseAiApp: WiseAiApp?
  private var pendingResult: FlutterResult?
  private var pendingSessionResult: FlutterResult?
  private var encryptionConfig: [String: Any]? // Store encryption config for auto-decryption
  private var delegateHandler: WiseAiDelegateHandler?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example/wiseai_sdk", binaryMessenger: registrar.messenger())
    let instance = WiseaiSdkPlugin()
    instance.delegateHandler = WiseAiDelegateHandler(plugin: instance)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      
    case "initSDK":
      guard let args = call.arguments as? [String: Any],
            let clientId = args["clientId"] as? String,
            let baseUrl = args["baseUrl"] as? String else {
        result(FlutterError(code: "ARG_ERROR", 
                           message: "clientId and baseUrl are required", 
                           details: nil))
        return
      }
      
      do {
        wiseAiApp = WiseAiApp(apiToken: clientId, apiURL: baseUrl)
        result(nil)
      } catch {
        result(FlutterError(code: "SDK_INIT_FAILED",
                           message: "Failed to initialize WiseAI SDK",
                           details: error.localizedDescription))
      }
      
    case "setLanguageCode":
      guard let args = call.arguments as? [String: Any],
            let languageCode = args["languageCode"] as? String else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "languageCode is required",
                           details: nil))
        return
      }
      
      wiseAiApp?.setLanguage(languageCode)
      result(nil)
      
    case "startNewSession":
      // Note: In SDK v2.0.4+, sessions are managed internally by performEkyc methods
      // The isEncrypt flag triggers automatic session creation
      // Return a placeholder response for backwards compatibility
      result(["sessionId": "auto-managed", "message": "Sessions are now managed internally by the SDK"])
      
    case "startNewSessionWithEncryption":
      // Note: In SDK v2.0.4+, sessions are managed internally by performEkyc methods
      // The isEncrypt flag triggers automatic session creation and encryption config callback
      result(["sessionId": "auto-managed", "message": "Sessions are now managed internally by the SDK"])
      
    case "getSessionResult":
      // Note: In iOS SDK, results are typically obtained through delegate callbacks
      // This is a placeholder - actual implementation depends on how results are stored
      result("iOS result retrieval needs delegate implementation")
      
    case "performEkyc":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "Arguments are required",
                           details: nil))
        return
      }
      
      let exportDoc = args["exportDoc"] as? Bool ?? false
      let exportFace = args["exportFace"] as? Bool ?? false
      let isEncrypt = args["isEncrypt"] as? Bool ?? false
      let isQualityCheck = args["isQualityCheck"] as? Bool ?? false
      let isActiveLiveness = args["isActiveLiveness"] as? Bool ?? false
      
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                           message: "Could not find root view controller",
                           details: nil))
        return
      }
      
      pendingResult = result
      wiseAiApp?.delegate = delegateHandler
      wiseAiApp?.performEkyc(isQualityCheck: isQualityCheck,
                            isEncrypt: isEncrypt,
                            isActiveLiveness: isActiveLiveness,
                            isExportDoc: exportDoc,
                            isExportFace: exportFace)
      
    case "performPassportEkyc":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "Arguments are required",
                           details: nil))
        return
      }
      
      let exportDoc = args["exportDoc"] as? Bool ?? false
      let exportFace = args["exportFace"] as? Bool ?? false
      let isEncrypt = args["isEncrypt"] as? Bool ?? false
      let isNFC = args["isNFC"] as? Bool ?? true
      let isActiveLiveness = args["isActiveLiveness"] as? Bool ?? false
      
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                           message: "Could not find root view controller",
                           details: nil))
        return
      }
      
      pendingResult = result
      wiseAiApp?.delegate = delegateHandler
      wiseAiApp?.performPassportEkyc(isEncrypt: isEncrypt,
                                     isNFC: isNFC,
                                     isActiveLiveness: isActiveLiveness,
                                     isExportDoc: exportDoc,
                                     isExportFace: exportFace)
      
    case "performEkycForCountry":
      guard let args = call.arguments as? [String: Any],
            let countryCode = args["countryCode"] as? String,
            let idType = args["idType"] as? String else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "countryCode and idType are required",
                           details: nil))
        return
      }
      
      let exportDoc = args["exportDoc"] as? Bool ?? false
      let exportFace = args["exportFace"] as? Bool ?? false
      let isEncrypt = args["isEncrypt"] as? Bool ?? false
      let isActiveLiveness = args["isActiveLiveness"] as? Bool ?? false
      
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                           message: "Could not find root view controller",
                           details: nil))
        return
      }
      
      pendingResult = result
      wiseAiApp?.delegate = delegateHandler
      wiseAiApp?.performEkycForCountry(isEncrypt: isEncrypt,
                                       countryCode: countryCode,
                                       IDType: idType,
                                       isActiveLiveness: isActiveLiveness,
                                       isExportDoc: exportDoc,
                                       isExportFace: exportFace)
      
    case "decryptResult":
      guard let args = call.arguments as? [String: Any],
            let encryptedJson = args["encryptedJson"] as? String,
            let encryptionConfigJson = args["encryptionConfig"] as? String else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "encryptedJson and encryptionConfig are required",
                           details: nil))
        return
      }
      
      guard let wiseAiApp = wiseAiApp else {
        result(FlutterError(code: "SDK_NOT_INITIALIZED",
                           message: "WiseAI SDK not initialized. Call initSDK first.",
                           details: nil))
        return
      }
      
      // Parse encryption config from JSON string to dictionary
      guard let configData = encryptionConfigJson.data(using: .utf8),
            let configDict = try? JSONSerialization.jsonObject(with: configData, options: []) as? [String: Any] else {
        result(FlutterError(code: "INVALID_CONFIG",
                           message: "Invalid encryption config JSON",
                           details: nil))
        return
      }
      
      // Perform decryption using the SDK's decryptResult method
      wiseAiApp.delegate = delegateHandler
      let decryptedResult = wiseAiApp.decryptResult(encryptedResult: encryptedJson, encryptionConfig: configDict)
      
      // Return both encrypted and decrypted results
      result([
        "encryptedResult": encryptedJson,
        "decryptedResult": decryptedResult ?? ""
      ])
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Internal delegate callback handlers
  
  func handleEkycComplete(_ jsonResult: String) {
    guard let pendingResult = self.pendingResult else { return }
    
    // If we have encryption config, decrypt the result automatically
    if let encryptionConfig = self.encryptionConfig,
       let wiseAiApp = self.wiseAiApp {
      
      // Decrypt the encrypted result
      let decryptedResult = wiseAiApp.decryptResult(encryptedResult: jsonResult, encryptionConfig: encryptionConfig)
      
      // Return both encrypted and decrypted results
      var response: [String: Any] = [
        "encryptedResult": jsonResult,
        "decryptedResult": decryptedResult ?? ""
      ]
      
      // Also parse the decrypted JSON if possible for convenience
      if let decryptedResult = decryptedResult,
         let data = decryptedResult.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        response["decryptedData"] = json
      }
      
      pendingResult(response)
    } else {
      // No encryption - parse JSON string to dictionary directly
      if let data = jsonResult.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        pendingResult(json)
      } else {
        // If parsing fails, return the raw string
        pendingResult(["result": jsonResult])
      }
    }
    
    self.pendingResult = nil
  }
  
  func handleEkycException(_ jsonResult: String) {
    guard let pendingResult = self.pendingResult else { return }
    
    pendingResult(FlutterError(code: "EKYC_FAILED",
                               message: "eKYC process failed",
                               details: jsonResult))
    self.pendingResult = nil
  }
  
  func handleEkycCancelled() {
    guard let pendingResult = self.pendingResult else { return }
    
    pendingResult(FlutterError(code: "USER_CANCELLED",
                               message: "User cancelled eKYC process",
                               details: nil))
    self.pendingResult = nil
  }
  
  func handleSessionIdAndEncryptionConfig(_ sessionIDandConfig: String) {
    // This delegate method is called after startNewSession
    guard let pendingResult = self.pendingSessionResult else { return }
    
    // Parse the session data to extract sessionId and encryption config
    if let data = sessionIDandConfig.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let sessionId = json["sessionId"] as? String {
      
      // Store encryption config if present for auto-decryption
      if let config = json["encryptionConfig"] as? [String: Any] {
        self.encryptionConfig = config
      }
      
      // Return structured response with explicit sessionId (matching Android format)
      pendingResult([
        "sessionId": sessionId,
        "fullData": sessionIDandConfig
      ])
    } else {
      // Fallback: return raw data if parsing fails
      pendingResult([
        "fullData": sessionIDandConfig
      ])
    }
    
    self.pendingSessionResult = nil
  }
}
