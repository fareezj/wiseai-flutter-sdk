import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wiseai_sdk_plugin/ekyc_attachment.dart';

void main() {
  group('extractMykadAttachments', () {
    test('returns empty list when documentImageBase64 is blank', () {
      final parsed = jsonDecode(sampleSuccessResponse) as Map<String, dynamic>;

      final attachments = extractMykadAttachments(parsed);

      expect(attachments, isEmpty);
    });

    test('maps front and back document images to backend attachment fields', () {
      const frontBase64 =
          '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a'
          'HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIy'
          'MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEB'
          'AxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEB'
          'AQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAB//2Q==';
      const backBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      final parsed = jsonDecode(sampleSuccessResponse) as Map<String, dynamic>;
      final frontData = (parsed['idFront'] as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      final backData = (parsed['idBack'] as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      frontData['documentImageBase64'] = frontBase64;
      backData['documentImageBase64'] = backBase64;

      final attachments = extractMykadAttachments(parsed);

      expect(attachments, hasLength(2));

      final front = attachments.first;
      expect(front.attachType, EkycAttachType.mykadFront);
      expect(front.toBackendMap()['AttachType'], '1');
      expect(front.fileContent, frontBase64);
      expect(front.fileType, 'image/jpeg');
      expect(front.fileName, 'mykad_front.jpg');
      expect(int.parse(front.fileSize), greaterThan(0));

      final back = attachments.last;
      expect(back.attachType, EkycAttachType.mykadBack);
      expect(back.toBackendMap()['AttachType'], '2');
      expect(back.fileContent, backBase64);
      expect(back.fileType, 'image/png');
      expect(back.fileName, 'mykad_back.png');
      expect(int.parse(back.fileSize), greaterThan(0));
    });
  });
}

const sampleSuccessResponse = '''
{
    "idFront": {
        "meta": {
            "reqTs": 1754288996185,
            "respTs": 1754288999094,
            "reqId": "ef562230-0a6e-4ff8-aff3-f0a2bfdd06bb"
        },
        "code": "SUCCESS",
        "subcode": 0,
        "status": "success",
        "data": {
            "documentImageBase64": "",
            "name": "AISYAH ALYIA BINTI DIN",
            "type": "FRONT",
            "icNumber": "090429-12-0294"
        },
        "hashData": "099D16C496225D30AE56D080F80A766CC195631564D477C7B705AC9ABDF12059",
        "sessionId": "1115c5cc-8e1c-4d28-85b8-d3a8fed5bc98"
    },
    "idBack": {
        "data": {
            "documentImageBase64": "",
            "icNumber": "090429-12-0294",
            "type": "BACK"
        },
        "code": "SUCCESS",
        "hashData": "D6E87DFCA776688DBA66C14F738BC235F2A5BA143FDFB696B0448F51F2A40CB7",
        "sessionId": "1115c5cc-8e1c-4d28-85b8-d3a8fed5bc98",
        "meta": {
            "reqTs": 1754289005315,
            "respTs": 1754289007714,
            "reqId": "150fccfa-74af-4c51-a916-00517dc5be12"
        },
        "subcode": 0,
        "status": "success"
    },
    "sessionId": "1115c5cc-8e1c-4d28-85b8-d3a8fed5bc98",
    "idFrontIsValid": false,
    "idBackIsValid": true,
    "livenessDetected": true,
    "faceIsMatch": false,
    "ekycSuccess": false,
    "isPending": false
}
''';
