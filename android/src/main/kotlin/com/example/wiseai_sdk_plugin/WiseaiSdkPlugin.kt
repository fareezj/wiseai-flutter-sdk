package com.example.wiseai_sdk_plugin

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.wiseai.ekyc110.WiseAiApp
import com.wiseai.ekyc110.ekyc.Ekyc
import com.wiseai.ekyc110.ekyc.PassportNFCEkyc
import com.wiseai.ekyc110.ekyc.WiseAiFaceVerify
import com.wiseai.ekyc110.helper.SessionCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

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
 *   { "source": "bridgeError", "rawData": <verbatim message — no SDK eKYC payload>, "sessionId"?: "..." }
 *
 * The event-level "sessionId" is captured from WiseAiApp.startNewSession
 * (SDK v2.7.7+ returns it immediately upon session creation, regardless
 * of encryption). It lets Flutter correlate cancelled / bridgeError events
 * to a session even when no SDK eKYC payload is produced.
 *
 * "sdk" carries the SDK's structured eKYC response from getResult() — both
 * the success and the error variant.
 *
 * "bridgeError" covers every case where there is no structured SDK response
 * to forward — bridge-side failures (missing args, decode errors), SDK
 * callbacks that return only a String (SessionCallback.onError), or the SDK
 * activity exiting without a payload. The rawData carries whatever message
 * we have, verbatim. The bridge never invents JSON.
 */
class WiseaiSdkPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private val METHOD_CHANNEL = "WiseAiMethods"
    private val EVENT_CHANNEL = "com.wiseai.wiseai_sdk_plugin/events"
    private val ACTIVITY_EKYC = 1001
    private val ACTIVITY_PASSPORT_NFC_EKYC = 1002
    private val ACTIVITY_FACE_VERIFY = 1003
    private val TAG = "WiseAiBridge"

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null

    private val wiseAiApp: WiseAiApp = WiseAiApp()

    private lateinit var encryptionAlgorithm: String
    private lateinit var key: String
    private lateinit var iv: String
    private lateinit var padding: String
    private lateinit var mode: String
    private var ifEncryption: Boolean = false

    /**
     * SessionId returned by WiseAiApp.startNewSession (SDK v2.7.7+ returns it
     * regardless of encryption). Reset at the start of each flow; attached to
     * cancelled / bridgeError events so Flutter can correlate them to the
     * session even when no SDK eKYC payload is produced.
     */
    private var currentSessionId: String = ""

    // --- FlutterPlugin ---

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // --- ActivityAware ---

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

    // --- EventChannel.StreamHandler ---

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        Log.d(TAG, "EventChannel: Flutter started listening")
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        Log.d(TAG, "EventChannel: Flutter stopped listening")
    }

    // --- MethodCallHandler ---

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "performMykadEkyc" -> {
                performMykadEkyc(call.arguments as? Map<String, Any> ?: emptyMap())
                result.success(null)
            }
            "performPassportNFCEkyc" -> {
                performPassportNFCEkyc(call.arguments as? Map<String, Any> ?: emptyMap())
                result.success(null)
            }
            "performFaceVerify" -> {
                performFaceVerify(call.arguments as? Map<String, Any> ?: emptyMap())
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // MARK: - SDK Operations

    private fun performMykadEkyc(args: Map<String, Any>) {
        val currentActivity = activity
        if (currentActivity == null) {
            sendBridgeError("Activity not available")
            return
        }
        currentSessionId = ""

        val apiToken = args["apiToken"] as? String ?: ""
        val apiURL = args["apiURL"] as? String ?: ""
        val language = args["language"] as? String ?: "EN"
        ifEncryption = args["isEncrypt"] as? Boolean ?: false
        val extraParamMap = args["extraParam"] as? Map<String, String>

        val extraParam = JsonObject()
        extraParamMap?.forEach { (k, v) -> extraParam.addProperty(k, v) }

        wiseAiApp.init(currentActivity, apiToken, apiURL)
        // or initialize SDK with extraParam
        //wiseAiApp.initWithExtraParam(currentActivity, apiToken, apiURL, extraParam)

        val intent = Intent(currentActivity, Ekyc::class.java).apply {
            putExtra("COUNTRY_CODE", "MYS")
            putExtra("ID_TYPE", "ID")
            putExtra("EXPORT_FACE", true)
            putExtra("CAMERA_FACING", "FRONT")
            putExtra("IF_ENCRYPTION", ifEncryption)
            putExtra("LANGUAGE_CODE", language)
        }

        WiseAiApp.startNewSession(ifEncryption, object : SessionCallback {
            override fun onComplete(data: Any?) {
                handleSessionCallback(data)
                currentActivity.startActivityForResult(intent, ACTIVITY_EKYC)
            }
            override fun onError(exception: String) {
                // Session never started → no structured SDK eKYC response exists.
                // Forward the SDK's message verbatim; bridge does not invent JSON.
                sendBridgeError(exception)
            }
        })
    }

    private fun performPassportNFCEkyc(args: Map<String, Any>) {
        val currentActivity = activity
        if (currentActivity == null) {
            sendBridgeError("Activity not available")
            return
        }
        currentSessionId = ""
        val apiToken = args["apiToken"] as? String ?: ""
        val apiURL = args["apiURL"] as? String ?: ""
        val language = args["language"] as? String ?: "EN"
        ifEncryption = args["isEncrypt"] as? Boolean ?: false
        val extraParamMap = args["extraParam"] as? Map<String, String>

        val extraParam = JsonObject()
        extraParamMap?.forEach { (k, v) -> extraParam.addProperty(k, v) }

        wiseAiApp.init(currentActivity, apiToken, apiURL)
        // or initialize SDK with extraParam
        // wiseAiApp.initWithExtraParam(currentActivity, apiToken, apiURL, extraParam)

        val intent = Intent(currentActivity, PassportNFCEkyc::class.java).apply {
            putExtra("COUNTRY_CODE", "")
            putExtra("ID_TYPE", "PASSPORT")
            putExtra("EXPORT_FACE", true)
            putExtra("TIMEOUT_PERIOD", 15)
            putExtra("CAMERA_FACING", "FRONT")
            putExtra("IF_ENCRYPTION", ifEncryption)
            putExtra("LANGUAGE_CODE", language)
        }

        WiseAiApp.startNewSession(ifEncryption, object : SessionCallback {
            override fun onComplete(data: Any?) {
                handleSessionCallback(data)
                currentActivity.startActivityForResult(intent, ACTIVITY_PASSPORT_NFC_EKYC)
            }
            override fun onError(exception: String) {
                sendBridgeError(exception)
            }
        })
    }

    private fun performFaceVerify(args: Map<String, Any>) {
        val currentActivity = activity
        if (currentActivity == null) {
            sendBridgeError("Activity not available")
            return
        }
        currentSessionId = ""
        val apiToken = args["apiToken"] as? String ?: ""
        val apiURL = args["apiURL"] as? String ?: ""
        val language = args["language"] as? String ?: "EN"
        val isExportFace = args["isExportFace"] as? Boolean ?: false
        ifEncryption = args["isEncrypt"] as? Boolean ?: false
        val faceImageBase64 = args["faceImageBase64"] as? String
        val isActiveLiveness = args["isActiveLiveness"] as? Boolean ?: false

        if (faceImageBase64 == null) {
            sendBridgeError("Face Verify: faceImageBase64 is required")
            return
        }

        try {
            val faceImageBytes = Base64.decode(faceImageBase64, Base64.DEFAULT)
            android.graphics.BitmapFactory.decodeByteArray(faceImageBytes, 0, faceImageBytes.size)
                ?: throw Exception("Failed to decode image bytes to Bitmap")

            wiseAiApp.init(currentActivity, apiToken, apiURL)
            WiseAiApp.storeFaceImage(faceImageBytes)

            val intent = Intent(currentActivity, WiseAiFaceVerify::class.java).apply {
                putExtra("EXPORT_FACE", isExportFace)
                putExtra("CAMERA_FACING", "FRONT")
                putExtra("IF_ENCRYPTION", ifEncryption)
                putExtra("LANGUAGE_CODE", language)
                putExtra("ACTIVATE_ACTIVE_LIVENESS", isActiveLiveness)
            }

            WiseAiApp.startNewSession(ifEncryption, object : SessionCallback {
                override fun onComplete(data: Any?) {
                    handleSessionCallback(data)
                    currentActivity.startActivityForResult(intent, ACTIVITY_FACE_VERIFY)
                }
                override fun onError(exception: String) {
                    sendBridgeError(exception)
                }
            })
        } catch (e: Exception) {
            sendBridgeError("Face Verify init failed: ${e.message}")
        }
    }

    // MARK: - Activity Result Handling

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            ACTIVITY_EKYC,
            ACTIVITY_PASSPORT_NFC_EKYC,
            ACTIVITY_FACE_VERIFY -> {
                handleSdkActivityResult(resultCode, data)
                return true
            }
            else -> return false
        }
    }

    private fun handleSdkActivityResult(resultCode: Int, data: Intent?) {
        if (resultCode == Activity.RESULT_OK) {
            // Step 1: get the SDK's raw result string. If getResult() throws,
            // there is no SDK response to forward — emit a bridge error.
            val raw: String
            try {
                raw = WiseAiApp.getResult()
            } catch (e: Exception) {
                sendBridgeError("getResult() threw: ${e.message}")
                return
            }

            // Step 2: decrypt if needed. On any decryption failure, fall back
            // to the original raw string so the backend still sees something
            // with sessionId. Do NOT replace it with a custom envelope.
            var payload: String
            try {
                payload = decryptResultIfNeeded(raw)
            } catch (e: Exception) {
                Log.w(TAG, "Decryption failed, forwarding original: ${e.message}")
                payload = raw
            }

            sendSdkResult(payload)
        } else {
            // Non-OK result from the SDK activity: cancellation or internal abort.
            val status = data?.getStringExtra("STATUS")
            if (status == "CANCELLED") {
                sendCancelled()
            } else {
                // SDK activity exited without a structured response — nothing to forward.
                sendBridgeError("SDK activity ended with non-OK result, status=$status")
            }
        }
    }

    // MARK: - Session Callback Helpers
    private fun handleSessionCallback(data: Any?) {
        if (data == null) return
        try {
            val obj = JsonParser.parseString(data.toString()).asJsonObject
            // SDK v2.7.7+: sessionId returned immediately upon session creation
            // regardless of encryption.
            if (obj.has("sessionId")) {
                currentSessionId = obj.get("sessionId").asString ?: ""
            }
            // Encryption keys are only present when isEncrypt = true.
            if (obj.has("key")) {
                key = obj["key"].asString
                iv = obj["iv"].asString
                padding = obj["padding"].asString
                mode = obj["mode"].asString
                encryptionAlgorithm = obj["alg"].asString
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse session callback data: ${e.message}")
        }
    }

    private fun decryptResultIfNeeded(result: String): String {
        var jsonObject = JsonParser.parseString(result).asJsonObject
        if (jsonObject.has("encryptedResult")) {
            val sessionId = jsonObject["sessionId"].asString
            val encryptedText = jsonObject["encryptedResult"].asString
            val decryptedString = decryptString(encryptedText, key, iv, padding, mode, encryptionAlgorithm)
            val decryptedJson = JsonParser.parseString(decryptedString).asJsonObject
            decryptedJson.addProperty("sessionId", sessionId)
            jsonObject = decryptedJson
        }
        return jsonObject.toString()
    }

    @Throws(Exception::class)
    private fun decryptString(
        encryptedText: String,
        key: String,
        initVector: String,
        padding: String,
        mode: String,
        algorithm: String
    ): String {
        val ivSpec = IvParameterSpec(Base64.decode(initVector, Base64.DEFAULT))
        val updatedAlgorithm = if (algorithm == "AES256") "AES" else algorithm
        val sKeySpec = SecretKeySpec(Base64.decode(key, Base64.DEFAULT), updatedAlgorithm)
        val cipher = Cipher.getInstance("$updatedAlgorithm/$mode/$padding")
        cipher.init(Cipher.DECRYPT_MODE, sKeySpec, ivSpec)
        return String(cipher.doFinal(Base64.decode(encryptedText, Base64.DEFAULT)), Charsets.UTF_8)
    }

    // MARK: - Event Senders (the ONLY three exits to Flutter)

    private fun sendSdkResult(rawData: String) = sendEvent("sdk", rawData)
    private fun sendCancelled() = sendEvent("cancelled", "")
    private fun sendBridgeError(message: String) {
        Log.e(TAG, "bridgeError: $message")
        sendEvent("bridgeError", message)
    }

    private fun sendEvent(source: String, rawData: String) {
        eventSink?.let { sink ->
            val event = mutableMapOf<String, Any>(
                "source" to source,
                "rawData" to rawData
            )
            // Attach early sessionId (SDK v2.7.7+) so cancelled / bridgeError
            // events can still be correlated to the session. For "sdk" events,
            // sessionId is also inside rawData; the duplicate is harmless.
            if (currentSessionId.isNotEmpty()) {
                event["sessionId"] = currentSessionId
            }
            sink.success(event)
        } ?: Log.w(TAG, "EventSink is null — dropping event source=$source")
    }
}
