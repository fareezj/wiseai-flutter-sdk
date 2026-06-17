import Flutter
import UIKit
import WiseAISDK

/**
 * WiseAI Flutter Bridge
 *
 * Design contract (do not change without updating the Flutter side):
 *
 * The native bridge forwards SDK responses verbatim. It never parses the
 * SDK's `status` / `code` / `message` / `sessionId`, never reshapes the
 * JSON, and never decides what is "success" vs "error" — Flutter does that.
 *
 * The bridge always sends one of three event sources, plus an optional
 * event-level sessionId:
 *   { "source": "sdk",         "rawData": <verbatim SDK JSON, decrypted if needed>, "sessionId"?: "..." }
 *   { "source": "cancelled",   "rawData": "",                                       "sessionId"?: "..." }
 *   { "source": "bridgeError", "rawData": <human message — only when SDK never ran>, "sessionId"?: "..." }
 *
 * "bridgeError" means the SDK was never reached. SDK-reported errors
 * (session expired, OCR mismatch, etc.) come back via "sdk" because the
 * SDK itself produced them.
 */

/// `WiseaiSdkPlugin` is `@objc`-exported (it's a `FlutterPlugin`), which means
/// Xcode generates an Objective-C compatibility header for it that Runner
/// imports across the pod boundary. If that public class conformed directly
/// to `WiseAiDelegate`/`FaceVerifyDelegate`, the generated header would need
/// to reference those WiseAISDK protocol names — but WiseAISDK isn't
/// guaranteed to be visible at the point Runner consumes that header
/// (unlike Flutter.framework, which every pod can assume is imported),
/// causing "Cannot find protocol declaration for 'FaceVerifyDelegate'".
/// Keeping the SDK-protocol conformance on this private, non-exported
/// object instead avoids that entirely.
private class WiseAiDelegateHandler: NSObject, WiseAiDelegate, FaceVerifyDelegate {
  weak var plugin: WiseaiSdkPlugin?

  init(plugin: WiseaiSdkPlugin) {
    self.plugin = plugin
    super.init()
  }

  func getSessionIdAndEncryptionConfig(_ sessionIdAndEncryptionConfig: String) {
    plugin?.handleSessionIdAndEncryptionConfig(sessionIdAndEncryptionConfig)
  }

  func onEkycComplete(_ jsonResult: String)  { plugin?.handleEkycComplete(jsonResult) }
  func onEkycException(_ jsonResult: String) { plugin?.handleEkycException(jsonResult) }
  func onEkycCancelled()                     { plugin?.handleEkycCancelled() }

  func getFaceVerifySessionIdAndEncryptionConfig(_ sessionIdAndEncryptionConfig: String) {
    plugin?.handleFaceVerifySessionIdAndEncryptionConfig(sessionIdAndEncryptionConfig)
  }

  func onFaceVerifyComplete(_ jsonResult: String)  { plugin?.handleFaceVerifyComplete(jsonResult) }
  func onFaceVerifyException(_ jsonResult: String) { plugin?.handleFaceVerifyException(jsonResult) }
  func onFaceVerifyCancelled()                     { plugin?.handleFaceVerifyCancelled() }
}

@objc(WiseaiSdkPlugin)
public class WiseaiSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var wiseAiApp: WiseAiApp?
  private var encryptionConfig: [String: Any] = [:]
  private var eventSink: FlutterEventSink?
  private var delegateHandler: WiseAiDelegateHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = WiseaiSdkPlugin()
    instance.delegateHandler = WiseAiDelegateHandler(plugin: instance)

    let methodChannel = FlutterMethodChannel(name: "WiseAiMethods",
                                              binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler(instance.handle)

    let eventChannel = FlutterEventChannel(name: "com.wiseai.wiseai_sdk_plugin/events",
                                            binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  // MARK: - MethodChannel

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "performMykadEkyc":
      performMykadEkyc(args: args)
      result(nil)
    case "performPassportNFCEkyc":
      performPassportNFCEkyc(args: args)
      result(nil)
    case "performFaceVerify":
      performFaceVerify(args: args)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - SDK Operations

  private func performMykadEkyc(args: [String: Any]) {
    let apiToken = args["apiToken"] as? String ?? ""
    let apiURL = args["apiURL"] as? String ?? ""
    let language = args["language"] as? String ?? "EN"
    let isEncrypt = args["isEncrypt"] as? Bool ?? false

    wiseAiApp = WiseAiApp(ekycApiToken: apiToken, ekycApiURL: apiURL)
    // or initialize SDK with extraParam
    // let extraParam = buildExtraParamJson(args["extraParam"] as? [String: String])
    // wiseAiApp = WiseAiApp(ekycApiToken: apiToken, ekycApiURL: apiURL, extraParam: extraParam)
    wiseAiApp?.delegate = delegateHandler
    wiseAiApp?.setLanguage(language)
    wiseAiApp?.performEkyc(isEncrypt: isEncrypt)
  }

  private func performPassportNFCEkyc(args: [String: Any]) {
    let apiToken = args["apiToken"] as? String ?? ""
    let apiURL = args["apiURL"] as? String ?? ""
    let language = args["language"] as? String ?? "EN"
    let isNFC = args["isNFC"] as? Bool ?? false
    let isEncrypt = args["isEncrypt"] as? Bool ?? false

    wiseAiApp = WiseAiApp(ekycApiToken: apiToken, ekycApiURL: apiURL)
    // or initialize SDK with extraParam
    // let extraParam = buildExtraParamJson(args["extraParam"] as? [String: String])
    // wiseAiApp = WiseAiApp(ekycApiToken: apiToken, ekycApiURL: apiURL, extraParam: extraParam)
    wiseAiApp?.delegate = delegateHandler
    wiseAiApp?.setLanguage(language)
    wiseAiApp?.performPassportEkyc(isEncrypt: isEncrypt, isNFC: isNFC)
  }

  private func performFaceVerify(args: [String: Any]) {
    let apiToken = args["apiToken"] as? String ?? ""
    let apiURL = args["apiURL"] as? String ?? ""
    let language = args["language"] as? String ?? "EN"
    let isExportFace = args["isExportFace"] as? Bool ?? false
    let isActiveLiveness = args["isActiveLiveness"] as? Bool ?? false
    let isEncrypt = args["isEncrypt"] as? Bool ?? false

    guard let faceImageBase64 = args["faceImageBase64"] as? String else {
      sendBridgeError("Face Verify: faceImageBase64 is required")
      return
    }
    guard let rawBinaryImageData = Data(base64Encoded: faceImageBase64) else {
      sendBridgeError("Face Verify: failed to decode base64 image")
      return
    }

    wiseAiApp = WiseAiApp(ekycApiToken: apiToken, ekycApiURL: apiURL)
    wiseAiApp?.delegate = delegateHandler
    wiseAiApp?.faceVerifyDelegate = delegateHandler
    wiseAiApp?.setLanguage(language)
    wiseAiApp?.performImageFaceVerify(
      rawBinaryImageData: rawBinaryImageData,
      isExportFace: isExportFace,
      isActiveLiveness: isActiveLiveness,
      isEncrypt: isEncrypt
    )
  }

  // MARK: - Helpers

  private func buildExtraParamJson(_ map: [String: String]?) -> String {
    guard let map = map,
          let data = try? JSONSerialization.data(withJSONObject: map),
          let str = String(data: data, encoding: .utf8) else {
      return "{}"
    }
    return str
  }

  /// Decrypt if encrypted; on any failure, return the original string so the
  /// caller still has something with sessionId to forward. Never throws.
  private func decryptIfNeeded(_ result: String) -> String {
    guard let decrypted = wiseAiApp?.decryptResult(encryptedResult: result, encryptionConfig: encryptionConfig),
          !decrypted.isEmpty,
          decrypted != "Failed to decrypt data." else {
      return result
    }
    return decrypted
  }

  private func storeEncryptionConfig(from sessionData: Any) {
    if let configDict = sessionData as? [String: Any],
       let config = configDict["encryptionConfig"] as? [String: String] {
      encryptionConfig = config
      return
    }
    if let jsonString = sessionData as? String,
       let data = jsonString.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let config = json["encryptionConfig"] as? [String: String] {
      encryptionConfig = config
    }
  }

  // MARK: - Event Senders (the ONLY three exits to Flutter)

  private func sendSdkResult(_ rawData: String) { sendEvent(source: "sdk", rawData: rawData) }
  private func sendCancelled()                  { sendEvent(source: "cancelled", rawData: "") }
  private func sendBridgeError(_ message: String) {
    print("[WiseAiBridge] bridgeError: \(message)")
    sendEvent(source: "bridgeError", rawData: message)
  }

  private func sendEvent(source: String, rawData: String) {
    guard let sink = eventSink else {
      print("[WiseAiBridge] eventSink is nil — dropping event source=\(source)")
      return
    }
    sink(["source": source, "rawData": rawData])
  }

  // MARK: - Internal delegate callback handlers
  //
  // Called by WiseAiDelegateHandler (not exposed to Objective-C). Not
  // `private` — a sibling class in this file needs to call these.

  func handleSessionIdAndEncryptionConfig(_ sessionIdAndEncryptionConfig: String) {
    storeEncryptionConfig(from: sessionIdAndEncryptionConfig)
  }

  func handleEkycComplete(_ jsonResult: String)  { sendSdkResult(decryptIfNeeded(jsonResult)) }
  func handleEkycException(_ jsonResult: String) { sendSdkResult(jsonResult) }
  func handleEkycCancelled()                     { sendCancelled() }

  func handleFaceVerifySessionIdAndEncryptionConfig(_ sessionIdAndEncryptionConfig: String) {
    storeEncryptionConfig(from: sessionIdAndEncryptionConfig)
  }

  func handleFaceVerifyComplete(_ jsonResult: String)  { sendSdkResult(decryptIfNeeded(jsonResult)) }
  func handleFaceVerifyException(_ jsonResult: String) { sendSdkResult(jsonResult) }
  func handleFaceVerifyCancelled()                     { sendCancelled() }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
