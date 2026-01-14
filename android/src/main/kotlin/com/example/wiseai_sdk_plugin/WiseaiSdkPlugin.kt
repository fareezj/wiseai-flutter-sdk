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
import android.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/** WiseaiSdkPlugin */
class WiseaiSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that links Flutter to the native code.
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var wiseAiAppInstance: WiseAiApp? = null
  private var activity: Activity? = null
  private var pendingResult: Result? = null
  private val gson = Gson()
  private var encryptionConfig: JSONObject? = null // Store encryption config for auto-decryption
  
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
                        val sessionData = JSONObject(var1.toString())
                        
                        // Store encryption config if present for auto-decryption
                        // The encryption params are at the root level when encryption is enabled
                        if (withEncryption && sessionData.has("key")) {
                            encryptionConfig = sessionData
                        }
                        
                        // Convert entire JSON to map for Flutter
                        val resultMap = jsonToMap(sessionData)
                        
                        result.success(resultMap)
                    } catch (e: Exception) {
                        Log.e("WiseaiPlugin", "Could not parse session data: ${e.message}", e)
                        // Fallback: return raw data wrapped in map
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
        
        "startNewSessionWithEncryption" -> {
            // Convenience method that always uses encryption
            WiseAiApp.startNewSession(true, object : SessionCallback {
                override fun onComplete(var1: Any?) {
                    Log.d("WiseaiPlugin", "Encrypted session onComplete: $var1")
                    
                    try {
                        val sessionData = JSONObject(var1.toString())
                        val sessionId = sessionData.getString("sessionId")
                        
                        // Store encryption config for auto-decryption
                        // The encryption params are at the root level, not nested
                        encryptionConfig = sessionData
                        
                        // Convert entire JSON to map for Flutter
                        val resultMap = jsonToMap(sessionData)
                        
                        result.success(resultMap)
                    } catch (e: Exception) {
                        Log.e("WiseaiPlugin", "Could not parse session data: ${e.message}", e)
                        // Fallback: return raw data wrapped in map
                        result.success(mapOf("fullData" to var1.toString()))
                    }
                }

                override fun onError(var1: String?) {
                    Log.e("WiseaiPlugin", "Encrypted session onError: $var1")
                    result.error("SESSION_FAILED", "WiseAI Session Error: $var1", null)
                }
            })
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
                
                // Use existing session - user must call startNewSession before performEkyc
                Log.d("WiseaiPlugin", "Launching eKYC with existing session")
                currentActivity?.startActivityForResult(intent, REQUEST_CODE_EKYC)
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
                
                // Use existing session - user must call startNewSession before performPassportEkyc
                Log.d("WiseaiPlugin", "Launching passport eKYC with existing session")
                currentActivity?.startActivityForResult(intent, REQUEST_CODE_PASSPORT_EKYC)
            } catch (e: Exception) {
                Log.e("WiseaiPlugin", "Passport eKYC exception: ${e.message}", e)
                result.error("EKYC_ERROR", "Failed to start passport eKYC: ${e.message}", null)
                pendingResult = null
            }
        }
        
        "decryptResult" -> {
            // Get arguments
            val encryptedJson = call.argument<String>("encryptedJson")
            val encryptionConfigJson = call.argument<String>("encryptionConfig")
            
            if (encryptedJson.isNullOrEmpty() || encryptionConfigJson.isNullOrEmpty()) {
                result.error("ARG_ERROR", "encryptedJson and encryptionConfig are required", null)
                return
            }
            
            // Check if SDK is initialized
            if (wiseAiAppInstance == null) {
                result.error("SDK_NOT_INITIALIZED", "WiseAI SDK not initialized. Call initSDK first.", null)
                return
            }
            
            try {
                // Parse encryption config from JSON string to JSONObject
                val configObject = JSONObject(encryptionConfigJson)
                
                // Extract decryption parameters from config
                val key = configObject.getString("key")
                val initVector = configObject.getString("iv")
                val padding = configObject.getString("padding")
                val mode = configObject.getString("mode")
                var algorithm = configObject.getString("alg")
                
                // Perform decryption using the decryptString method
                val decryptedResult = decryptString(encryptedJson, key, initVector, padding, mode, algorithm)
                
                // Return both encrypted and decrypted results
                val resultMap = mapOf(
                    "encryptedResult" to encryptedJson,
                    "decryptedResult" to decryptedResult
                )
                result.success(resultMap)
            } catch (e: Exception) {
                Log.e("WiseaiPlugin", "Decryption failed: ${e.message}", e)
                result.error("DECRYPTION_ERROR", "Failed to decrypt result: ${e.message}", null)
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
                      
                      // If we have encryption config, decrypt the result automatically
                      val finalResultString = if (encryptionConfig != null) {
                          try {
                              // Extract decryption parameters from stored encryption config
                              val key = encryptionConfig!!.getString("key")
                              val initVector = encryptionConfig!!.getString("iv")
                              val padding = encryptionConfig!!.getString("padding")
                              val mode = encryptionConfig!!.getString("mode")
                              val algorithm = encryptionConfig!!.getString("alg")
                              
                              // Decrypt using the decryptString method
                              val decryptedResult = decryptString(resultString, key, initVector, padding, mode, algorithm)
                              Log.d("WiseaiPlugin", "Decrypted result: $decryptedResult")
                              decryptedResult
                          } catch (e: Exception) {
                              Log.e("WiseaiPlugin", "Decryption failed: ${e.message}", e)
                              resultString // Fallback to encrypted result if decryption fails
                          }
                      } else {
                          resultString // No encryption, use result as-is
                      }
                      
                      // Parse result
                      val jsonObject = JsonParser.parseString(finalResultString).asJsonObject
                      val jsonOrgObject = JSONObject(finalResultString)
                      
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
  
  // --- Decryption Helper Method ---
  
  /**
   * Decrypts an encrypted string using AES encryption with the provided parameters.
   * This method follows the WiseAI SDK documentation for manual decryption.
   * 
   * @param encryptedText The Base64 encoded encrypted text
   * @param key The Base64 encoded encryption key
   * @param initVector The Base64 encoded initialization vector (IV)
   * @param padding The padding mode (e.g., "PKCS5Padding")
   * @param mode The cipher mode (e.g., "CBC")
   * @param algorithm The encryption algorithm (e.g., "AES256" or "AES")
   * @return The decrypted string
   * @throws Exception if decryption fails
   */
  private fun decryptString(
      encryptedText: String,
      key: String,
      initVector: String,
      padding: String,
      mode: String,
      algorithm: String
  ): String {
      // Create IV parameter spec from Base64 decoded init vector
      val iv = IvParameterSpec(Base64.decode(initVector, Base64.DEFAULT))
      
      // Handle AES256 algorithm name - convert to standard "AES"
      var actualAlgorithm = algorithm
      if (algorithm == "AES256") {
          actualAlgorithm = "AES"
      }
      
      // Create secret key spec from Base64 decoded key
      val sKeySpec = SecretKeySpec(Base64.decode(key, Base64.DEFAULT), actualAlgorithm)
      
      // Create transformation string (e.g., "AES/CBC/PKCS5Padding")
      val transformation = "$actualAlgorithm/$mode/$padding"
      
      // Initialize cipher for decryption
      val cipher = Cipher.getInstance(transformation)
      cipher.init(Cipher.DECRYPT_MODE, sKeySpec, iv)
      
      // Decrypt the Base64 decoded encrypted text
      val original = cipher.doFinal(Base64.decode(encryptedText, Base64.DEFAULT))
      
      // Return decrypted string in UTF-8 encoding
      return String(original, Charsets.UTF_8)
  }
}