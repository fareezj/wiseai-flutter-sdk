import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Backend attachment type for MyKad document images.
///
/// `mykadFront` → AttachType `"1"`
/// `mykadBack` → AttachType `"2"`
enum EkycAttachType {
  mykadFront('1'),
  mykadBack('2');

  const EkycAttachType(this.code);
  final String code;

  String get defaultFileName => switch (this) {
        mykadFront => 'mykad_front',
        mykadBack => 'mykad_back',
      };

  String get label => switch (this) {
        mykadFront => 'MyKad Front',
        mykadBack => 'MyKad Back',
      };
}

/// Backend attachment payload derived from WiseAI SDK OCR data.
@immutable
class EkycAttachment {
  final EkycAttachType attachType;
  final String fileContent;
  final String fileType;
  final String fileName;
  final String fileSize;

  const EkycAttachment({
    required this.attachType,
    required this.fileContent,
    required this.fileType,
    required this.fileName,
    required this.fileSize,
  });

  /// Backend field names from the integration spec.
  Map<String, String> toBackendMap() => {
        'AttachType': attachType.code,
        'FileContent': fileContent,
        'FileType': fileType,
        'FileName': fileName,
        'FileSize': fileSize,
      };

  @override
  String toString() =>
      'EkycAttachment(attachType: ${attachType.code}, fileName: $fileName, '
      'fileType: $fileType, fileSize: $fileSize)';
}

/// Maps decoded WiseAI SDK JSON into backend [EkycAttachment] entries.
List<EkycAttachment> extractMykadAttachments(Map<String, dynamic> parsed) {
  final attachments = <EkycAttachment>[];

  _appendDocumentAttachment(
    attachments: attachments,
    section: parsed['idFront'],
    attachType: EkycAttachType.mykadFront,
  );
  _appendDocumentAttachment(
    attachments: attachments,
    section: parsed['idBack'],
    attachType: EkycAttachType.mykadBack,
  );

  return attachments;
}

void _appendDocumentAttachment({
  required List<EkycAttachment> attachments,
  required Object? section,
  required EkycAttachType attachType,
}) {
  if (section is! Map<String, dynamic>) return;

  final data = section['data'];
  if (data is! Map<String, dynamic>) return;

  final fileContent = data['documentImageBase64'];
  if (fileContent is! String || fileContent.isEmpty) return;

  final fileType = _inferMimeType(fileContent);
  final extension = _extensionForMimeType(fileType);

  attachments.add(
    EkycAttachment(
      attachType: attachType,
      fileContent: fileContent,
      fileType: fileType,
      fileName: '${attachType.defaultFileName}.$extension',
      fileSize: _fileSizeString(fileContent),
    ),
  );
}

String _inferMimeType(String base64Content) {
  final payload = _stripDataUriPrefix(base64Content);
  if (payload.startsWith('/9j/')) return 'image/jpeg';
  if (payload.startsWith('iVBOR')) return 'image/png';
  if (payload.startsWith('R0lG')) return 'image/gif';
  return 'image/jpeg';
}

String _extensionForMimeType(String mimeType) => switch (mimeType) {
      'image/png' => 'png',
      'image/gif' => 'gif',
      _ => 'jpg',
    };

String _stripDataUriPrefix(String base64Content) {
  final commaIndex = base64Content.indexOf(',');
  if (commaIndex == -1) return base64Content;
  return base64Content.substring(commaIndex + 1);
}

String _fileSizeString(String base64Content) {
  try {
    return base64Decode(_stripDataUriPrefix(base64Content)).length.toString();
  } catch (_) {
    return '0';
  }
}
