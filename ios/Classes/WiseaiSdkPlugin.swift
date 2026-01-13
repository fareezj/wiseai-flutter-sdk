import Flutter
import UIKit
import WiseAISDK

public class WiseaiSdkPlugin: NSObject, FlutterPlugin, WiseAIAppDelegate {
  private var wiseAiApp: WiseAiApp?
  private var pendingResult: FlutterResult?
  private var pendingSessionResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example/wiseai_sdk", binaryMessenger: registrar.messenger())
    let instance = WiseaiSdkPlugin()
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
        wiseAiApp = WiseAiApp(apiToken: clientId, andApiURL: baseUrl)
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
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "Arguments are required",
                           details: nil))
        return
      }
      
      let withEncryption = args["withEncryption"] as? Bool ?? false
      
      // Store the result to return it when delegate callback is triggered
      pendingSessionResult = result
      wiseAiApp?.delegate = self
      
      if withEncryption {
        wiseAiApp?.startNewSessionWithEncryption()
      } else {
        wiseAiApp?.startNewSession()
      }
      // Result will be returned in getSessionIdAndEncryptionConfig delegate method
      
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
      
      let exportDoc = args["exportDoc"] as? Bool ?? true
      let exportFace = args["exportFace"] as? Bool ?? true
      let cameraFacing = args["cameraFacing"] as? String ?? "FRONT"
      
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                           message: "Could not find root view controller",
                           details: nil))
        return
      }
      
      pendingResult = result
      wiseAiApp?.delegate = self
      wiseAiApp?.performEkyc(withExportDoc: exportDoc, 
                            andExportFace: exportFace, 
                            andCameraFacing: cameraFacing)
      
    case "performPassportEkyc":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARG_ERROR",
                           message: "Arguments are required",
                           details: nil))
        return
      }
      
      let exportDoc = args["exportDoc"] as? Bool ?? true
      let exportFace = args["exportFace"] as? Bool ?? true
      let cameraFacing = args["cameraFacing"] as? String ?? "FRONT"
      
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                           message: "Could not find root view controller",
                           details: nil))
        return
      }
      
      pendingResult = result
      wiseAiApp?.delegate = self
      wiseAiApp?.performPassportEkyc(withExportDoc: exportDoc,
                                     andExportFace: exportFace,
                                     andCameraFacing: cameraFacing)
      
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
      wiseAiApp.delegate = self
      let decryptedResult = wiseAiApp.decryptResult(encryptedJson, withConfiguration: configDict)
      
      // Return both encrypted and decrypted results
      result([
        "encryptedResult": encryptedJson,
        "decryptedResult": decryptedResult ?? ""
      ])
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - WiseAIAppDelegate Methods
  
  public func onEkycComplete(_ jsonResult: String) {
    guard let pendingResult = self.pendingResult else { return }
    
    // Parse JSON string to dictionary
    if let data = jsonResult.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
      pendingResult(json)
    } else {
      // If parsing fails, return the raw string
      pendingResult(["result": jsonResult])
    }
    
    self.pendingResult = nil
  }
  
  public func onEkycException(_ jsonResult: String) {
    guard let pendingResult = self.pendingResult else { return }
    
    pendingResult(FlutterError(code: "EKYC_FAILED",
                               message: "eKYC process failed",
                               details: jsonResult))
    self.pendingResult = nil
  }
  
  public func onEkycCancelled() {
    guard let pendingResult = self.pendingResult else { return }
    
    pendingResult(FlutterError(code: "USER_CANCELLED",
                               message: "User cancelled eKYC process",
                               details: nil))
    self.pendingResult = nil
  }
  
  public func getSessionIdAndEncryptionConfig(_ sessionIDandConfig: String) {
    // This delegate method is called after startNewSession
    guard let pendingResult = self.pendingSessionResult else { return }
    
    // Parse the session data to extract sessionId
    if let data = sessionIDandConfig.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let sessionId = json["sessionId"] as? String {
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
