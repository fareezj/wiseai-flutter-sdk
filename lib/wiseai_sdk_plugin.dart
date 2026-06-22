import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ekyc_attachment.dart';
import 'ekyc_result.dart';
import 'wiseai_config.dart';
import 'wiseai_sdk_plugin_platform_interface.dart';

export 'ekyc_attachment.dart';
export 'ekyc_result.dart';
export 'wiseai_config.dart';

/// Owns all SDK response parsing and classification. The native bridge
/// forwards the SDK's response verbatim and never reshapes it. Event
/// contract from native:
///   `{ "source": "sdk" | "cancelled" | "bridgeError",`
///   `  "rawData": "<string>",`
///   `  "sessionId"?: "<string>" }`
class WiseaiSdkPlugin {
  final _resultStreamController = StreamController<EkycResult>.broadcast();

  /// Stream of classified eKYC / Face Verify results. Listen to this after
  /// constructing the plugin and before calling any `performXxx` method.
  Stream<EkycResult> get resultStream => _resultStreamController.stream;

  late final StreamSubscription _eventSubscription;

  WiseaiSdkPlugin() {
    _eventSubscription = WiseaiSdkPluginPlatform.instance.bridgeEvents.listen(
      _onEvent,
      onError: _onChannelError,
    );
  }

  Future<String?> getPlatformVersion() {
    return WiseaiSdkPluginPlatform.instance.getPlatformVersion();
  }

  Future<void> performEkyc(MyKadEkycConfig config) {
    return _invoke(
      'performMykadEkyc',
      () => WiseaiSdkPluginPlatform.instance
          .performMykadEkyc(_buildMyKadArgs(config)),
    );
  }

  Future<void> performPassportNFCEkyc(PassportEkycConfig config) {
    return _invoke(
      'performPassportNFCEkyc',
      () => WiseaiSdkPluginPlatform.instance
          .performPassportNFCEkyc(_buildPassportArgs(config)),
    );
  }

  Future<void> performFaceVerify(FaceVerifyConfig config) {
    return _invoke(
      'performFaceVerify',
      () => WiseaiSdkPluginPlatform.instance
          .performFaceVerify(_buildFaceVerifyArgs(config)),
    );
  }

  void dispose() {
    _eventSubscription.cancel();
    _resultStreamController.close();
  }

  Map<String, dynamic> _buildMyKadArgs(MyKadEkycConfig config) {
    final args = _commonArgs(config);
    if (config is AndroidMyKadEkycConfig) {
      args['isEncrypt'] = config.isEncrypt;
      args['isExportFace'] = config.isExportFace;
      args['isExportDoc'] = config.isExportDoc;
      args['isActiveLiveness'] = config.isActiveLiveness;
    } else if (config is IosMyKadEkycConfig) {
      args['isEncrypt'] = config.isEncrypt;
      args['isExportFace'] = config.isExportFace;
      args['isExportDoc'] = config.isExportDoc;
    }
    return args;
  }

  Map<String, dynamic> _buildPassportArgs(PassportEkycConfig config) {
    final args = _commonArgs(config);
    if (config is AndroidPassportEkycConfig) {
      args['isEncrypt'] = config.isEncrypt;
      args['isExportFace'] = config.isExportFace;
      args['isActiveLiveness'] = config.isActiveLiveness;
    } else if (config is IosPassportEkycConfig) {
      args['isNFC'] = config.isNFC;
      args['isEncrypt'] = config.isEncrypt;
      args['isExportDoc'] = config.isExportDoc;
      args['isExportFace'] = config.isExportFace;
    }
    return args;
  }

  Map<String, dynamic> _buildFaceVerifyArgs(FaceVerifyConfig config) {
    final args = _commonArgs(config);
    args['faceImageBase64'] = base64Encode(config.faceImageBytes);
    if (config is AndroidFaceVerifyConfig) {
      args['isExportFace'] = config.isExportFace;
      args['isActiveLiveness'] = config.isActiveLiveness;
      args['isEncrypt'] = config.isEncrypt;
    } else if (config is IosFaceVerifyConfig) {
      args['isExportFace'] = config.isExportFace;
      args['isActiveLiveness'] = config.isActiveLiveness;
      args['isEncrypt'] = config.isEncrypt;
    }
    return args;
  }

  Map<String, dynamic> _commonArgs(WiseAIConfig config) {
    final args = <String, dynamic>{
      'apiToken': config.apiToken,
      'apiURL': config.apiURL,
      'language': config.language,
    };
    if (config.extraParam != null) args['extraParam'] = config.extraParam;
    return args;
  }

  Future<void> _invoke(String method, Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException catch (e) {
      _emitBridgeError("PlatformException invoking '$method': ${e.message}");
    }
  }

  void _onEvent(dynamic event) {
    if (event is! Map) {
      _emitBridgeError('Native sent non-map event: $event');
      return;
    }
    final source = event['source'] as String?;
    final rawData = event['rawData'] as String? ?? '';
    final eventSessionId = event['sessionId'] as String? ?? '';

    switch (source) {
      case 'sdk':
        _classifySdkPayload(rawData, fallbackSessionId: eventSessionId);
        break;
      case 'cancelled':
        _resultStreamController.add(EkycResult(
          status: EkycStatus.cancelled,
          sessionId: eventSessionId,
          rawData: '',
        ));
        break;
      case 'bridgeError':
        _emitBridgeError(rawData, sessionId: eventSessionId);
        break;
      default:
        _emitBridgeError('Unknown event source: $source (raw=$rawData)');
    }
  }

  void _classifySdkPayload(String rawData, {String fallbackSessionId = ''}) {
    final Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is! Map<String, dynamic>) {
        _emitBridgeError('SDK payload is not a JSON object: $rawData',
            sessionId: fallbackSessionId);
        return;
      }
      parsed = decoded;
    } catch (e) {
      debugPrint('[WiseaiSdkPlugin] SDK payload not valid JSON: $rawData');
      _emitBridgeError('SDK payload not valid JSON: $e',
          sessionId: fallbackSessionId);
      return;
    }

    final rawSessionId = (parsed['sessionId'] as String?) ?? '';
    final sessionId =
        rawSessionId.isNotEmpty ? rawSessionId : fallbackSessionId;
    final status = parsed['status'] as String?;

    if (status == 'error') {
      _resultStreamController.add(EkycResult(
        status: EkycStatus.sdkError,
        sessionId: sessionId,
        errorCode: parsed['code'] as String?,
        errorMessage: parsed['message'] as String?,
        rawData: rawData,
        parsed: parsed,
      ));
      return;
    }

    _resultStreamController.add(EkycResult(
      status: EkycStatus.success,
      sessionId: sessionId,
      rawData: rawData,
      parsed: parsed,
      attachments: extractMykadAttachments(parsed),
    ));
  }

  void _emitBridgeError(String message, {String sessionId = ''}) {
    debugPrint('[WiseaiSdkPlugin] bridgeError: $message');
    _resultStreamController.add(EkycResult(
      status: EkycStatus.bridgeError,
      sessionId: sessionId,
      errorCode: 'BRIDGE_ERROR',
      errorMessage: message,
      rawData: message,
    ));
  }

  void _onChannelError(Object error) {
    _emitBridgeError('EventChannel error: $error');
  }
}
