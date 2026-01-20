//
//  WiseAiApp.swift
//  WiseAISDK
//
//  Created by Chang Fu Tong on 20/04/2024.
//

import Foundation
import UIKit
import CommonCrypto

@objc public protocol WiseAiDelegate: NSObjectProtocol {
    func onEkycComplete(_ jsonResult: String)
    func onEkycException(_ jsonResult: String)
    func onEkycCancelled()
    func getSessionIdAndEncryptionConfig(_ sessionIdAndEncryptionConfig: String)
}

@objcMembers public class WiseAiApp: NSObject {
    let dataService = DataService()
    let apiToken: String
    let apiURL: String
    let extraParam: String
    
    public weak var delegate: WiseAiDelegate?
    
    private var actionType: Action?
    
    public init(apiToken: String, apiURL: String) {
        self.apiToken = apiToken
        self.apiURL = Self.ensureTrailingSlash(apiURL)
        self.extraParam = ""
        
        Assets.sharedInstance.WS_API_KEY = apiToken
        Assets.sharedInstance.WS_URL = Self.ensureTrailingSlash(apiURL)
    }
    
    public init(apiToken: String, apiURL: String, extraParam: String) {
        self.apiToken = apiToken
        self.apiURL = Self.ensureTrailingSlash(apiURL)
        self.extraParam = extraParam
        
        Assets.sharedInstance.WS_API_KEY = apiToken
        Assets.sharedInstance.WS_URL = Self.ensureTrailingSlash(apiURL)
        Assets.sharedInstance.extraParam = extraParam
    }
    
    // type 1 = initial, 2 = start ekyc
    private func validate(type: Int, requestUrl: String) -> Bool {
        // fail and return
        guard let apiKey = Assets.sharedInstance.WS_API_KEY, !apiKey.isEmpty else {
            let invalidAPIKeyMessage = Assets.getErrorResponse(message: "Please provide API token before proceed.")
            delegate?.onEkycException(invalidAPIKeyMessage)
            return false
        }
        
        // fail and return
        guard let url = Assets.sharedInstance.WS_URL, !url.isEmpty else {
            let invalidURLStringMessage = Assets.getErrorResponse(message: "Please provide API URL before proceed.")
            delegate?.onEkycException(invalidURLStringMessage)
            return false
        }
        
        // fail and return
        guard URL(string: apiURL + requestUrl) != nil else {
            let invalidEndpointMessage = Assets.getErrorResponse(message: "Invalid endpoint.")
            delegate?.onEkycException(invalidEndpointMessage)
            
            return false
        }
        
        if (type == 2) {
            guard Assets.sharedInstance.sessionID != nil else {
                let invalidSessionMessage = Assets.getErrorResponse(message: "Please start a new session before proceed.")
                delegate?.onEkycException(invalidSessionMessage)
                
                return false
            }
        }
        
        return true
    }
    
    private func startNewSession(isEncrypt: Bool = false) async -> Bool {
        if Assets.sharedInstance.languageDictionary.isEmpty {
            self.setLanguage("EN")
        }
        
        // Set encryption mode flag
        Assets.sharedInstance.isEncryptMode = isEncrypt
        
        // Choose the correct endpoint
        let endpoint = isEncrypt
        ? Assets.sharedInstance.START_SESSION_ENCRYPTION
        : Assets.sharedInstance.START_SESSION
        
        // Validate
        guard validate(type: 1, requestUrl: endpoint) else {
            return false
        }
        
        // Create URL
        guard let url = URL(string: apiURL + endpoint) else {
            let invalidEndpointMessage = Assets.getErrorResponse(message: "Invalid endpoint.")
            delegate?.onEkycException(invalidEndpointMessage)
            return false
        }
        
        // Call service
        let res = await dataService.startSession(url: url)
        
        guard res.success else {
            delegate?.onEkycException(res.message)
            return false
        }
        
        // If not encryption mode, we’re done
        if !isEncrypt {
            return true
        }
        
        // If encryption mode, prepare session + encryption config
        do {
            if let encryptionDict = Assets.toDictionary(Assets.sharedInstance.sessionEncryptModel) {
                let sessionIdAndEncryptionConfig: [String: Any] = [
                    "sessionId": Assets.sharedInstance.sessionID ?? "N/A",
                    "encryptionConfig": encryptionDict
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: sessionIdAndEncryptionConfig, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    if Assets.sharedInstance.isDebug {
                        print("Final JSON: \(jsonString)")
                    }
                    delegate?.getSessionIdAndEncryptionConfig(jsonString)
                }
                
                return true
            } else {
                let invalidEncryptionMessage = Assets.getErrorResponse(message: "Failed to convert Encryption to dictionary")
                delegate?.onEkycException(invalidEncryptionMessage)
                return false
            }
        } catch {
            let serializationErrorMessage = Assets.getErrorResponse(message: "Failed to serialize JSON in encryption: \(error)")
            delegate?.onEkycException(serializationErrorMessage)
            return false
        }
    }
    
    public func performEkyc(isQualityCheck: Bool = false, isEncrypt: Bool = false, isActiveLiveness: Bool = false, isExportDoc: Bool = false, isExportFace: Bool = false, completion: (() -> Void)? = nil) {
        Task {
            await self.performEkyc(isQualityCheck: isQualityCheck, isEncrypt: isEncrypt, isActiveLiveness: isActiveLiveness, isExportDoc: isExportDoc, isExportFace: isExportFace)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public func performPassportEkyc(isEncrypt: Bool = false, isNFC: Bool = false, isActiveLiveness: Bool = false, isExportDoc: Bool = false, isExportFace: Bool = false, completion: (() -> Void)? = nil) {
        Task {
            await self.performPassportEkyc(isEncrypt: isEncrypt, isNFC: isNFC, isActiveLiveness: isActiveLiveness, isExportDoc: isExportDoc, isExportFace: isExportFace)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public func performEkycForCountry(isEncrypt: Bool = false, countryCode: String, IDType: String, isActiveLiveness: Bool = false, isExportDoc: Bool = false, isExportFace: Bool = false, completion: (() -> Void)? = nil) {
        Task {
            await self.performEkycForCountry(isEncrypt: isEncrypt, countryCode: countryCode, IDType: IDType, isActiveLiveness: isActiveLiveness, isExportDoc: isExportDoc, isExportFace: isExportFace)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public func setLanguage(_ language: String) {
        guard let bundlePath = Bundle(for: type(of: self)).path(forResource: "LanguageData", ofType: "json") else {
            delegate?.onEkycException("JSON file not found.")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: bundlePath))
            if let languageDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: String]] {
                let uppercasedLanguage = language.uppercased()
                let selectedLanguage = languageDictionary[uppercasedLanguage] != nil ? uppercasedLanguage : "EN"
                Assets.sharedInstance.languageDictionary = languageDictionary[selectedLanguage] ?? [:]
                
                if Assets.sharedInstance.isDebug {
                    print("LANGUAGE USED: \(selectedLanguage)")
                    print("\(selectedLanguage) Dictionary: \(Assets.sharedInstance.languageDictionary)")
                }
            } else {
                delegate?.onEkycException("Invalid JSON structure.")
            }
        } catch {
            delegate?.onEkycException("Error reading JSON: \(error.localizedDescription)")
        }
    }
    
    public func decryptResult(encryptedResult: String, encryptionConfig: Dictionary<String, Any>) -> String? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: encryptedResult.data(using: .utf8)!, options: [])
            
            if let jsonDict = jsonObject as? [String: Any],
               let encryptedString = jsonDict["encrypted_result"] as? String {
                
                let decryptedResult = self.decryptResult(encryptedBase64String: encryptedString, encryptionConfig: encryptionConfig)
                
                guard !decryptedResult.isEmpty else {
                    delegate?.onEkycException("Exception in decrypting result")
                    return nil
                }
                
                if (Assets.sharedInstance.isDebug) {
                    print("Decrypted result: \(decryptedResult)")
                }
                return decryptedResult
                
            } else {
                if (Assets.sharedInstance.isDebug) {
                    print("Missing 'encrypted_result' or 'encryption' in response.")
                }
            }
        } catch {
            print("Error parsing JSON: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func decryptResult(encryptedBase64String: String, encryptionConfig: Dictionary<String, Any>) -> String {
        // Decode encrypted base64 input
        guard let encryptedData = Data(base64Encoded: encryptedBase64String) else {
            print("❌ Failed to decode base64 encrypted string.")
            return ""
        }
        
        // Decode key and IV
        guard let keyString = encryptionConfig["key"] as? String,
              let ivString = encryptionConfig["iv"] as? String,
              let keyData = Data(base64Encoded: keyString),
              let ivData = Data(base64Encoded: ivString) else {
            print("❌ Failed to decode key or IV.")
            return ""
        }
        
        let paddingOption = CCOptions(kCCOptionPKCS7Padding)
        let keySize = kCCKeySizeAES256
        
        let bufferSize = encryptedData.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = encryptedData.withUnsafeBytes { encryptedBytes in
            keyData.withUnsafeBytes { keyBytes in
                ivData.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        paddingOption,
                        keyBytes.baseAddress, keySize,
                        ivBytes.baseAddress,
                        encryptedBytes.baseAddress, encryptedData.count,
                        &buffer, bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        if cryptStatus == kCCSuccess {
            let decryptedData = Data(bytes: buffer, count: numBytesDecrypted)
            if let decryptedString = String(data: decryptedData, encoding: .utf8) {
                return decryptedString
            } else {
                print("❌ Failed to decode UTF-8 from decrypted data.")
                return ""
            }
        } else {
            print("❌ Decryption failed with status: \(cryptStatus)")
            return ""
        }
    }
    
    // MARK: ekyc
    private func performEkyc(isQualityCheck: Bool = false, isEncrypt: Bool = false, isActiveLiveness: Bool = false, isExportDoc: Bool = false, isExportFace: Bool = false) async {
        guard await startNewSession(isEncrypt: isEncrypt) else {
            return
        }
        
        guard validate(type: 2, requestUrl: Assets.sharedInstance.DO_OCR) else {
            return
        }
        
        actionType = .EKYC
        
        if isExportFace {
            Assets.sharedInstance.isExportFace = isExportFace
        }
        
        if isActiveLiveness {
            Assets.sharedInstance.isActiveLiveness = isActiveLiveness
        }
        
        await MainActor.run {
            let ekycViewController: UIViewController
            
            if isQualityCheck {
                let controller = HybridQualityViewController()
                controller.delegate = self
                controller.isExportDoc = isExportDoc
                controller.isExportFace = isExportFace
                ekycViewController = controller
            } else {
                let controller = EKYCViewController()
                controller.delegate = self
                controller.isExportDoc = isExportDoc
                controller.isExportFace = isExportFace
                ekycViewController = controller
            }
            
            ekycViewController.modalPresentationStyle = .fullScreen
            
            if let topVC = topMostViewController(), topVC.presentedViewController == nil {
                topVC.present(ekycViewController, animated: false)
            }
        }
    }
    
    private func performPassportEkyc(isEncrypt: Bool = false, isNFC: Bool = false, isActiveLiveness: Bool = false, isExportDoc: Bool = false, isExportFace: Bool = false) async {
        guard await startNewSession(isEncrypt: isEncrypt) else {
            return
        }
        
        guard validate(type: 2, requestUrl: Assets.sharedInstance.DO_PASSPORT) else {
            return
        }
        
        actionType = .PASSPORT
        
        if isExportFace {
            Assets.sharedInstance.isExportFace = isExportFace
        }
        
        if isActiveLiveness {
            Assets.sharedInstance.isActiveLiveness = isActiveLiveness
        }
        
        await MainActor.run {
            let passportOCRViewController = PassportOCRViewController()
            passportOCRViewController.delegate = self
            passportOCRViewController.isExportDoc = isExportDoc
            passportOCRViewController.isExportFace = isExportFace
            passportOCRViewController.isNFC = isNFC
            passportOCRViewController.modalPresentationStyle = .fullScreen
            
            if let topVC = topMostViewController(), topVC.presentedViewController == nil {
                topVC.present(passportOCRViewController, animated: false)
            }
        }
    }
    
    private func performEkycForCountry(isEncrypt: Bool = false, countryCode: String, IDType: String, isActiveLiveness: Bool = false, isExportDoc: Bool = false, isExportFace: Bool = false) async {
        guard await startNewSession(isEncrypt: isEncrypt) else {
            return
        }
        
        let countryCodeUrl = "\(Assets.sharedInstance.countryCode)_\(Assets.sharedInstance.idType)"
        guard validate(type: 2, requestUrl: Assets.sharedInstance.DO_ID_OCR + countryCodeUrl) else {
            return
        }
        
        actionType = .OTHER_EKYC
        Assets.sharedInstance.idType = IDType.lowercased()
        Assets.sharedInstance.countryCode = countryCode.lowercased()
        
        if isExportFace {
            Assets.sharedInstance.isExportFace = isExportFace
        }
        
        if isActiveLiveness {
            Assets.sharedInstance.isActiveLiveness = isActiveLiveness
        }
        
        await MainActor.run {
            let viewController: UIViewController
            
            if (Assets.sharedInstance.idType == "passport") {
                actionType = .PASSPORT
                let controller = PassportOCRViewController()
                controller.delegate = self
                controller.isExportDoc = isExportDoc
                controller.isExportFace = isExportFace
                viewController = controller
            } else {
                actionType = .OTHER_EKYC
                let controller = OtherEKYCViewController()
                controller.delegate = self
                controller.isExportDoc = isExportDoc
                controller.isExportFace = isExportFace
                viewController = controller
            }
            
            viewController.modalPresentationStyle = .fullScreen
            
            if let topVC = topMostViewController(), topVC.presentedViewController == nil {
                topVC.present(viewController, animated: false)
            }
        }
    }
    
    private func performPassportNFC() {
        actionType = .PASSPORT_NFC
        let passportNFCViewController = PassportNFCViewController()
        passportNFCViewController.delegate = self
        passportNFCViewController.modalPresentationStyle = .fullScreen
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        if scene is UIWindowScene {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let top = self.topMostViewController() {
                    top.present(passportNFCViewController, animated: false, completion: nil)
                }
            }
        }
    }
    
    // MARK: FaceLiveness
    private func performFaceLiveness() {
        let activeMode = Assets.sharedInstance.isActiveLiveness
        
        DispatchQueue.main.async {
            let faceLivenessViewController: UIViewController
            
            if activeMode {
                let controller = ActiveFaceLivenessMediapipeViewController()
                controller.delegate = self
                controller.actionType = self.actionType
                faceLivenessViewController = controller
            } else {
                let controller = FaceLivenessViewController()
                controller.delegate = self
                controller.actionType = self.actionType
                faceLivenessViewController = controller
            }
            
            faceLivenessViewController.modalPresentationStyle = .fullScreen
            
            if let top = self.topMostViewController(), top.presentedViewController == nil {
                top.present(faceLivenessViewController, animated: false)
            }
        }
    }
    
    private func topMostViewController(base: UIViewController? = {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    }()) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
    
    private static func ensureTrailingSlash(_ url: String) -> String {
        return url.hasSuffix("/") ? url : url + "/"
    }
}

extension WiseAiApp: ResultDelegate {
    func onResultComplete(_ jsonResult: String, type action: Action) {
        switch action {
        case .EKYC, .PASSPORT, .OTHER_EKYC, .OTHEREKYCIDQUALITYHYBRID, .PASSPORTQUALITYHYBRID:
            self.performFaceLiveness()
        case .PASSPORT_NFC:
            self.performPassportNFC()
        case .FACELIVENESS:
            // actionType = null
            delegate?.onEkycComplete(Assets.sharedInstance.wrapInJSONWithSessionID(result: "", type: actionType!))
        }
    }
    
    func onResultException(_ jsonResult: String, controller view: UIViewController) {
        delegate?.onEkycException(jsonResult)
        view.dismiss(animated: false)
    }
    
    func onCancelled(controller view: UIViewController) {
        delegate?.onEkycCancelled()
        view.dismiss(animated: false)
    }
}
