import 'package:flutter/foundation.dart';

/// Base configuration class for WiseAI SDK operations.
@immutable
abstract class WiseAIConfig {
  final String apiToken;
  final String apiURL;
  final String language;
  final Map<String, String>? extraParam;

  const WiseAIConfig({
    required this.apiToken,
    required this.apiURL,
    this.language = 'EN',
    this.extraParam,
  });
}

// ============================================================================
// MyKad eKYC Configurations
// ============================================================================

/// Base MyKad eKYC configuration.
@immutable
abstract class MyKadEkycConfig extends WiseAIConfig {
  const MyKadEkycConfig({
    required super.apiToken,
    required super.apiURL,
    super.language = 'EN',
    super.extraParam,
  });
}

/// MyKad eKYC configuration for Android.
@immutable
class AndroidMyKadEkycConfig extends MyKadEkycConfig {
  final bool isEncrypt;
  final bool isExportFace;
  final bool isExportDoc;
  final bool isActiveLiveness;

  const AndroidMyKadEkycConfig({
    required super.apiToken,
    required super.apiURL,
    super.language = 'EN',
    super.extraParam,
    this.isEncrypt = false,
    this.isExportFace = true,
    this.isExportDoc = false,
    this.isActiveLiveness = false,
  });

  AndroidMyKadEkycConfig copyWith({
    String? apiToken,
    String? apiURL,
    String? language,
    Map<String, String>? extraParam,
    bool? isEncrypt,
    bool? isExportFace,
    bool? isExportDoc,
    bool? isActiveLiveness,
  }) {
    return AndroidMyKadEkycConfig(
      apiToken: apiToken ?? this.apiToken,
      apiURL: apiURL ?? this.apiURL,
      language: language ?? this.language,
      extraParam: extraParam ?? this.extraParam,
      isEncrypt: isEncrypt ?? this.isEncrypt,
      isExportFace: isExportFace ?? this.isExportFace,
      isExportDoc: isExportDoc ?? this.isExportDoc,
      isActiveLiveness: isActiveLiveness ?? this.isActiveLiveness,
    );
  }
}

/// MyKad eKYC configuration for iOS.
@immutable
class IosMyKadEkycConfig extends MyKadEkycConfig {
  final bool isEncrypt;
  final bool isExportFace;
  final bool isExportDoc;
  final bool isActiveLiveness;

  const IosMyKadEkycConfig({
    required super.apiToken,
    required super.apiURL,
    super.language = 'EN',
    super.extraParam,
    this.isEncrypt = false,
    this.isExportFace = true,
    this.isExportDoc = false,
    this.isActiveLiveness = false,
  });

  IosMyKadEkycConfig copyWith({
    String? apiToken,
    String? apiURL,
    String? language,
    Map<String, String>? extraParam,
    bool? isEncrypt,
    bool? isExportFace,
    bool? isExportDoc,
    bool? isActiveLiveness,
  }) {
    return IosMyKadEkycConfig(
      apiToken: apiToken ?? this.apiToken,
      apiURL: apiURL ?? this.apiURL,
      language: language ?? this.language,
      extraParam: extraParam ?? this.extraParam,
      isEncrypt: isEncrypt ?? this.isEncrypt,
      isExportFace: isExportFace ?? this.isExportFace,
      isExportDoc: isExportDoc ?? this.isExportDoc,
      isActiveLiveness: isActiveLiveness ?? this.isActiveLiveness,
    );
  }
}

// ============================================================================
// Passport eKYC Configurations
// ============================================================================

/// Base Passport eKYC configuration.
@immutable
abstract class PassportEkycConfig extends WiseAIConfig {
  const PassportEkycConfig({
    required super.apiToken,
    required super.apiURL,
    super.language = 'EN',
    super.extraParam,
  });
}

/// Passport eKYC configuration for Android.
@immutable
class AndroidPassportEkycConfig extends PassportEkycConfig {
  final bool isEncrypt;
  final bool isExportFace;
  final bool isActiveLiveness;

  const AndroidPassportEkycConfig({
    required super.apiToken,
    required super.apiURL,
    super.language = 'EN',
    super.extraParam,
    this.isEncrypt = false,
    this.isExportFace = true,
    this.isActiveLiveness = false,
  });

  AndroidPassportEkycConfig copyWith({
    String? apiToken,
    String? apiURL,
    String? language,
    Map<String, String>? extraParam,
    bool? isEncrypt,
    bool? isExportFace,
    bool? isActiveLiveness,
  }) {
    return AndroidPassportEkycConfig(
      apiToken: apiToken ?? this.apiToken,
      apiURL: apiURL ?? this.apiURL,
      language: language ?? this.language,
      extraParam: extraParam ?? this.extraParam,
      isEncrypt: isEncrypt ?? this.isEncrypt,
      isExportFace: isExportFace ?? this.isExportFace,
      isActiveLiveness: isActiveLiveness ?? this.isActiveLiveness,
    );
  }
}

/// Passport eKYC configuration for iOS.
@immutable
class IosPassportEkycConfig extends PassportEkycConfig {
  final bool isNFC;
  final bool isEncrypt;
  final bool isExportDoc;
  final bool isExportFace;

  const IosPassportEkycConfig({
    required super.apiToken,
    required super.apiURL,
    super.language = 'EN',
    super.extraParam,
    this.isNFC = false,
    this.isEncrypt = false,
    this.isExportDoc = false,
    this.isExportFace = true,
  });

  IosPassportEkycConfig copyWith({
    String? apiToken,
    String? apiURL,
    String? language,
    Map<String, String>? extraParam,
    bool? isNFC,
    bool? isEncrypt,
    bool? isExportDoc,
    bool? isExportFace,
  }) {
    return IosPassportEkycConfig(
      apiToken: apiToken ?? this.apiToken,
      apiURL: apiURL ?? this.apiURL,
      language: language ?? this.language,
      extraParam: extraParam ?? this.extraParam,
      isNFC: isNFC ?? this.isNFC,
      isEncrypt: isEncrypt ?? this.isEncrypt,
      isExportDoc: isExportDoc ?? this.isExportDoc,
      isExportFace: isExportFace ?? this.isExportFace,
    );
  }
}

// ============================================================================
// Face Verify Configurations
// ============================================================================

/// Base Face Verify configuration.
@immutable
abstract class FaceVerifyConfig extends WiseAIConfig {
  final Uint8List faceImageBytes;

  const FaceVerifyConfig({
    required super.apiToken,
    required super.apiURL,
    required this.faceImageBytes,
    super.language = 'EN',
  });
}

/// Face Verify configuration for Android.
@immutable
class AndroidFaceVerifyConfig extends FaceVerifyConfig {
  final bool isExportFace;
  final bool isActiveLiveness;
  final bool isEncrypt;

  const AndroidFaceVerifyConfig({
    required super.apiToken,
    required super.apiURL,
    required super.faceImageBytes,
    super.language = 'EN',
    this.isExportFace = false,
    this.isActiveLiveness = false,
    this.isEncrypt = false,
  });

  AndroidFaceVerifyConfig copyWith({
    String? apiToken,
    String? apiURL,
    String? language,
    Uint8List? faceImageBytes,
    bool? isExportFace,
    bool? isActiveLiveness,
    bool? isEncrypt,
  }) {
    return AndroidFaceVerifyConfig(
      apiToken: apiToken ?? this.apiToken,
      apiURL: apiURL ?? this.apiURL,
      language: language ?? this.language,
      faceImageBytes: faceImageBytes ?? this.faceImageBytes,
      isExportFace: isExportFace ?? this.isExportFace,
      isActiveLiveness: isActiveLiveness ?? this.isActiveLiveness,
      isEncrypt: isEncrypt ?? this.isEncrypt,
    );
  }
}

/// Face Verify configuration for iOS.
@immutable
class IosFaceVerifyConfig extends FaceVerifyConfig {
  final bool isExportFace;
  final bool isActiveLiveness;
  final bool isEncrypt;

  const IosFaceVerifyConfig({
    required super.apiToken,
    required super.apiURL,
    required super.faceImageBytes,
    super.language = 'EN',
    this.isExportFace = false,
    this.isActiveLiveness = false,
    this.isEncrypt = false,
  });

  IosFaceVerifyConfig copyWith({
    String? apiToken,
    String? apiURL,
    String? language,
    Uint8List? faceImageBytes,
    bool? isExportFace,
    bool? isActiveLiveness,
    bool? isEncrypt,
  }) {
    return IosFaceVerifyConfig(
      apiToken: apiToken ?? this.apiToken,
      apiURL: apiURL ?? this.apiURL,
      language: language ?? this.language,
      faceImageBytes: faceImageBytes ?? this.faceImageBytes,
      isExportFace: isExportFace ?? this.isExportFace,
      isActiveLiveness: isActiveLiveness ?? this.isActiveLiveness,
      isEncrypt: isEncrypt ?? this.isEncrypt,
    );
  }
}
