import Flutter
import UIKit
import WiseAISDK

public class WiseaiSdkPlugin: NSObject, FlutterPlugin {
  private var wiseAiApp: WiseAiApp?
  
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
      
      if withEncryption {
        wiseAiApp?.startNewSessionWithEncryption()
      } else {
        wiseAiApp?.startNewSession()
      }
      
      // Return success immediately - actual session result will be available later
      result("Session started")
      
    case "getSessionResult":
      // Note: In iOS SDK, results are typically obtained through delegate callbacks
      // This is a placeholder - actual implementation depends on how results are stored
      result("iOS result retrieval needs delegate implementation")
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
