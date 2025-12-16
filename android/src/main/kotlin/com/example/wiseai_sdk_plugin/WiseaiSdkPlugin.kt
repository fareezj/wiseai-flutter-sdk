package com.example.wiseai_sdk_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.util.Log // For debugging
import com.wiseai.ekyc110.WiseAiApp // 1. IMPORT THE WISEAI SDK CLASS
import com.wiseai.ekyc110.helper.SessionCallback // 2. IMPORT THE ASYNCHRONOUS CALLBACK

/** WiseaiSdkPlugin */
class WiseaiSdkPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that links Flutter to the native code.
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var wiseAiAppInstance: WiseAiApp? = null // Instance for calling non-static methods

  // --- FlutterPlugin IMPLEMENTATION ---
  
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // 3. Establish the MethodChannel connection using the same name as the Dart side
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example/wiseai_sdk")
    channel.setMethodCallHandler(this)
    // Store the application context, needed for the WiseAiApp().init() call
    applicationContext = flutterPluginBinding.applicationContext
    
    // Instantiate the WiseAiApp object here to call its non-static methods later
    wiseAiAppInstance = WiseAiApp()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    // Clean up the instance
    wiseAiAppInstance = null
  }

  // --- MethodCallHandler IMPLEMENTATION ---

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d("WiseaiPlugin", "Received method call: ${call.method}")
    
    when (call.method) {
        "getPlatformVersion" -> {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        
        "initSDK" -> {
            // Retrieve arguments from Dart
            val clientId = call.argument<String>("clientId")
            val baseUrl = call.argument<String>("baseUrl")
            
            if (clientId.isNullOrEmpty() || baseUrl.isNullOrEmpty()) {
                result.error("ARG_ERROR", "clientId and baseUrl are required for initialization.", null)
                return
            }
            
            try {
                // Call the native non-static init function
                wiseAiAppInstance?.init(applicationContext, clientId, baseUrl)
                result.success(null) // Return success (void in Dart)
            } catch (e: Exception) {
                // Return platform exception if initialization fails
                result.error("SDK_INIT_FAILED", "Native WiseAI initialization failed.", e.localizedMessage)
            }
        }
        
        "setLanguageCode" -> {
            val languageCode = call.argument<String>("languageCode")
            
            if (languageCode.isNullOrEmpty()) {
                 result.error("ARG_ERROR", "languageCode is required.", null)
                 return
            }
            
            // Call the native static setLanguageCode function
            WiseAiApp.setLanguageCode(languageCode)
            result.success(null)
        }

        "startNewSession" -> {
            // Retrieve arguments
            val withEncryption = call.argument<Boolean>("withEncryption") ?: false

            // IMPORTANT: Bridge the native asynchronous SessionCallback to the Flutter Result
            WiseAiApp.startNewSession(withEncryption, object : SessionCallback {
                override fun onComplete(var1: Any?) {
                    // This is called when the session request succeeds
                    // var1 should be the JSON String/Object containing session keys
                    Log.d("WiseaiPlugin", "Session onComplete: $var1")
                    
                    // The native code automatically calls WiseAiApp.setKeys(var1.toString()) inside
                    // the encrypted startNewSession, so we just return the raw result.
                    result.success(var1.toString()) 
                }

                override fun onError(var1: String?) {
                    // This is called when the session request fails
                    Log.e("WiseaiPlugin", "Session onError: $var1")
                    result.error("SESSION_FAILED", "WiseAI Session Error: $var1", null)
                }
            })
            // NOTE: We do NOT call result.success() here, as the result is returned later
            // inside the onComplete/onError methods of the SessionCallback.
        }
        
        "getSessionResult" -> {
             // Call the native static function to get the final result string
             val finalResult = WiseAiApp.getResult()
             result.success(finalResult)
        }
        
        else -> {
            result.notImplemented()
        }
    }
  }
}