package com.example.wiseai_sdk_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import com.wiseai.ekyc110.WiseAiApp
import com.wiseai.ekyc110.helper.SessionCallback
import com.google.gson.Gson
import com.google.gson.JsonParser
import org.json.JSONObject
import org.json.JSONArray

/** WiseaiSdkPlugin */
class WiseaiSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that links Flutter to the native code.
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var wiseAiAppInstance: WiseAiApp? = null
  private var activity: Activity? = null
  private var pendingResult: Result? = null
  private val gson = Gson()
  
  companion object {
    private const val REQUEST_CODE_EKYC = 1001
    private const val REQUEST_CODE_PASSPORT_EKYC = 1002
  }

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
    wiseAiAppInstance = null
  }

  // --- ActivityAware IMPLEMENTATION ---
  
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
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
                    
                    try {
                        val dataString = var1.toString()
                        
                        // Parse the response to extract sessionId
                        if (withEncryption && dataString.isNotEmpty()) {
                            val jsonObject = JsonParser.parseString(dataString).asJsonObject
                            val sessionId = if (jsonObject.has("sessionId")) {
                                jsonObject.get("sessionId").asString
                            } else null
                            
                            // Return structured response with explicit sessionId
                            val response = mapOf(
                                "sessionId" to sessionId,
                                "fullData" to dataString
                            )
                            result.success(response)
                        } else {
                            // For non-encrypted sessions, just return the raw data
                            result.success(mapOf("fullData" to dataString))
                        }
                    } catch (e: Exception) {
                        Log.e("WiseaiPlugin", "Error parsing session data: ${e.message}", e)
                        // Fallback: return raw data if parsing fails
                        result.success(mapOf("fullData" to var1.toString()))
                    }
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
        
        "performEkyc" -> {
            if (activity == null) {
                result.error("NO_ACTIVITY", "Activity not available", null)
                return
            }
            
            // Get parameters
            val exportDoc = call.argument<Boolean>("exportDoc") ?: true
            val exportFace = call.argument<Boolean>("exportFace") ?: true
            val cameraFacing = call.argument<String>("cameraFacing") ?: "FRONT"
            
            // Store pending result
            pendingResult = result
            
            // Create local reference for smart cast
            val currentActivity = activity
            
            try {
                // Create Intent for eKYC - activity is in SDK but runs in app's context
                val intent = Intent(currentActivity, Class.forName("com.wiseai.ekyc110.ekyc.Ekyc"))
                
                // Set configurations
                intent.putExtra("COUNTRY_CODE", "MYS")
                intent.putExtra("ID_TYPE", "ID")
                intent.putExtra("EXPORT_DOC", exportDoc)
                intent.putExtra("EXPORT_FACE", exportFace)
                intent.putExtra("CAMERA_FACING", cameraFacing)
                intent.putExtra("QUALITY_MODE", "HYBRID")
                intent.putExtra("LANGUAGE_CODE", "en")
                
                // Start session and launch eKYC
                WiseAiApp.startNewSession(true, object : SessionCallback {
                    override fun onComplete(data: Any?) {
                        Log.d("WiseaiPlugin", "Session started for eKYC")
                        currentActivity?.startActivityForResult(intent, REQUEST_CODE_EKYC)
                    }
                    
                    override fun onError(error: String?) {
                        Log.e("WiseaiPlugin", "Session start failed: $error")
                        pendingResult?.error("SESSION_FAILED", "Failed to start session: $error", null)
                        pendingResult = null
                    }
                })
            } catch (e: Exception) {
                Log.e("WiseaiPlugin", "eKYC exception: ${e.message}", e)
                result.error("EKYC_ERROR", "Failed to start eKYC: ${e.message}", null)
                pendingResult = null
            }
        }
        
        "performPassportEkyc" -> {
            if (activity == null) {
                result.error("NO_ACTIVITY", "Activity not available", null)
                return
            }
            
            // Get parameters
            val exportDoc = call.argument<Boolean>("exportDoc") ?: true
            val exportFace = call.argument<Boolean>("exportFace") ?: true
            val cameraFacing = call.argument<String>("cameraFacing") ?: "FRONT"
            
            // Store pending result
            pendingResult = result
            
            // Create local reference for smart cast
            val currentActivity = activity
            
            try {
                // Create Intent for Passport NFC eKYC - activity is in SDK but runs in app's context
                val intent = Intent(currentActivity, Class.forName("com.wiseai.ekyc110.ekyc.PassportNFCEkyc"))
                
                // Set configurations
                intent.putExtra("TIMEOUT_PERIOD", 15)
                intent.putExtra("CAMERA_FACING", cameraFacing)
                intent.putExtra("QUALITY_MODE", "HYBRID")
                intent.putExtra("ACTIVATE_ACTIVE_LIVENESS", true)
                
                // Start session and launch passport eKYC
                WiseAiApp.startNewSession(object : SessionCallback {
                    override fun onComplete(data: Any?) {
                        Log.d("WiseaiPlugin", "Session started for passport eKYC")
                        currentActivity?.startActivityForResult(intent, REQUEST_CODE_PASSPORT_EKYC)
                    }
                    
                    override fun onError(error: String?) {
                        Log.e("WiseaiPlugin", "Session start failed: $error")
                        pendingResult?.error("SESSION_FAILED", "Failed to start session: $error", null)
                        pendingResult = null
                    }
                })
            } catch (e: Exception) {
                Log.e("WiseaiPlugin", "Passport eKYC exception: ${e.message}", e)
                result.error("EKYC_ERROR", "Failed to start passport eKYC: ${e.message}", null)
                pendingResult = null
            }
        }
        
        else -> {
            result.notImplemented()
        }
    }
  }
  
  // --- Helper Methods ---
  
  private fun jsonToMap(json: JSONObject): Map<String, Any?> {
      val map = mutableMapOf<String, Any?>()
      val keys = json.keys()
      while (keys.hasNext()) {
          val key = keys.next()
          var value = json.get(key)
          when (value) {
              is JSONObject -> value = jsonToMap(value)
              is JSONArray -> value = jsonArrayToList(value)
              JSONObject.NULL -> value = null
          }
          map[key] = value
      }
      return map
  }
  
  private fun jsonArrayToList(array: JSONArray): List<Any?> {
      val list = mutableListOf<Any?>()
      for (i in 0 until array.length()) {
          var value = array.get(i)
          when (value) {
              is JSONObject -> value = jsonToMap(value)
              is JSONArray -> value = jsonArrayToList(value)
              JSONObject.NULL -> value = null
          }
          list.add(value)
      }
      return list
  }
  
  // --- ActivityResultListener IMPLEMENTATION ---
  
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
      Log.d("WiseaiPlugin", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
      
      when (requestCode) {
          REQUEST_CODE_EKYC, REQUEST_CODE_PASSPORT_EKYC -> {
              if (resultCode == Activity.RESULT_OK) {
                  try {
                      // Get result from WiseAiApp
                      val resultString = WiseAiApp.getResult()
                      Log.d("WiseaiPlugin", "eKYC result: $resultString")
                      
                      // Parse result
                      val jsonObject = JsonParser.parseString(resultString).asJsonObject
                      val jsonOrgObject = JSONObject(resultString)
                      
                      // Check for errors
                      if (jsonObject.has("status") && jsonObject.get("status").asString == "error") {
                          val code = if (jsonObject.has("code")) jsonObject.get("code").asString else "UNKNOWN"
                          val message = if (jsonObject.has("message")) jsonObject.get("message").asString else "Unknown error"
                          pendingResult?.error(code, message, null)
                      } else {
                          // Convert to map and return success
                          val resultMap = jsonToMap(jsonOrgObject)
                          pendingResult?.success(resultMap)
                      }
                  } catch (e: Exception) {
                      Log.e("WiseaiPlugin", "Error parsing result: ${e.message}", e)
                      pendingResult?.error("PARSE_ERROR", "Failed to parse result: ${e.message}", null)
                  } finally {
                      pendingResult = null
                  }
              } else {
                  // Check if cancelled
                  val status = data?.getStringExtra("STATUS")
                  if (status == "CANCELLED") {
                      pendingResult?.error("CANCELLED", "User cancelled eKYC", null)
                  } else {
                      pendingResult?.error("UNEXPECTED_ERROR", "eKYC failed with unexpected error", null)
                  }
                  pendingResult = null
              }
              return true
          }
      }
      return false
  }
}