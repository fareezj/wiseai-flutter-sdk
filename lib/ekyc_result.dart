import 'package:flutter/foundation.dart';

/// Outcome of an eKYC / Face Verify flow. Pattern-match on [status].
///
/// `success` — SDK returned a successful result. `rawData` holds the full SDK
/// JSON (sessionId, OCR data, etc.).
///
/// `sdkError` — SDK returned a structured error (session expired, OCR
/// mismatch, etc.). `rawData` holds the full SDK error JSON; `errorCode` and
/// `errorMessage` are extracted for convenience. `sessionId` is included.
///
/// `cancelled` — User cancelled the flow. No SDK eKYC payload was produced.
/// On Android, `sessionId` is populated when a session was created before
/// cancellation.
///
/// `bridgeError` — Bridge could not produce or receive a structured SDK
/// response (missing args, decode error, session-start failure, etc.).
/// `rawData` holds the bridge-side message.
///
/// **Send `rawData` to your backend verbatim** for `success` and `sdkError`.
enum EkycStatus { success, sdkError, cancelled, bridgeError }

@immutable
class EkycResult {
  final EkycStatus status;
  final String sessionId;
  final String? errorCode;
  final String? errorMessage;
  final String rawData;
  final Map<String, dynamic>? parsed;

  const EkycResult({
    required this.status,
    required this.sessionId,
    required this.rawData,
    this.errorCode,
    this.errorMessage,
    this.parsed,
  });

  bool get isSuccess => status == EkycStatus.success;
  bool get isSdkError => status == EkycStatus.sdkError;
  bool get isCancelled => status == EkycStatus.cancelled;
  bool get isBridgeError => status == EkycStatus.bridgeError;

  @override
  String toString() =>
      'EkycResult(status: $status, sessionId: $sessionId, '
      'errorCode: $errorCode, errorMessage: $errorMessage)';
}
