import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin.dart';

class FaceVerifyResultPage extends StatefulWidget {
  final String language;

  const FaceVerifyResultPage({super.key, required this.language});

  @override
  State<FaceVerifyResultPage> createState() => _FaceVerifyResultPageState();
}

class _FaceVerifyResultPageState extends State<FaceVerifyResultPage> {
  final WiseaiSdkPlugin _wiseaiSdkPlugin = WiseaiSdkPlugin();
  final ImagePicker _picker = ImagePicker();
  StreamSubscription<EkycResult>? _resultSubscription;
  EkycResult? _result;
  File? _selectedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _resultSubscription = _wiseaiSdkPlugin.resultStream.listen((result) {
      setState(() {
        _result = result;
        _isProcessing = false;
      });
      _showResultDialog(result);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _startFaceVerify() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      final config = Platform.isAndroid
          ? AndroidFaceVerifyConfig(
              apiToken: "YOUR_API_TOKEN",
              apiURL: "YOUR_API_URL",
              faceImageBytes: imageBytes,
              language: widget.language,
              isExportFace: false,
              isActiveLiveness: true,
              isEncrypt: false,
            )
          : IosFaceVerifyConfig(
              apiToken: "YOUR_API_TOKEN",
              apiURL: "YOUR_API_URL",
              faceImageBytes: imageBytes,
              language: widget.language,
              isExportFace: false,
              isActiveLiveness: false,
              isEncrypt: false,
            );

      await _wiseaiSdkPlugin.performFaceVerify(config);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start face verify: $e')),
      );
    }
  }

  void _showResultDialog(EkycResult result) {
    final (title, color) = switch (result.status) {
      EkycStatus.success => ('✅ FACE VERIFY COMPLETE', Colors.green),
      EkycStatus.sdkError => ('❌ FACE VERIFY EXCEPTION', Colors.red),
      EkycStatus.cancelled => ('⚠️ FACE VERIFY CANCELLED', Colors.orange),
      EkycStatus.bridgeError => ('⚠️ BRIDGE ERROR', Colors.red),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Session ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result.sessionId.isEmpty ? 'N/A' : result.sessionId),
            const SizedBox(height: 10),
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result.status.name.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _resultSubscription?.cancel();
    _wiseaiSdkPlugin.dispose();
    super.dispose();
  }

  Widget _buildImageSection(String? base64Image, String label) {
    if (base64Image == null || base64Image.isEmpty) return const SizedBox.shrink();
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Image.memory(base64Decode(base64Image), height: 200, fit: BoxFit.contain),
          const SizedBox(height: 20),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    final String displayValue = value is List
        ? value.whereType<Object>().map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ')
        : value.toString();

    if (displayValue.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(child: Text(displayValue, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildErrorView(EkycResult result, {required IconData icon, required Color color, required String title}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (result.errorCode != null)
              Text('Error Code: ${result.errorCode}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (result.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(result.errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ],
            if (result.sessionId.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Session ID: ${result.sessionId}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _result = null;
                  _selectedImage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    if (_result == null && !_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              const Text('Selected Image',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 30),
            ],
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startFaceVerify,
                icon: const Icon(Icons.verified_user),
                label: const Text('Start Face Verify'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Processing Face Verification...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) return const Center(child: Text('No result available'));

    switch (result.status) {
      case EkycStatus.sdkError:
        return _buildErrorView(result,
            icon: Icons.error_outline, color: Colors.red, title: 'Face Verify Error');
      case EkycStatus.bridgeError:
        return _buildErrorView(result,
            icon: Icons.warning_amber, color: Colors.red, title: 'Bridge Error');
      case EkycStatus.cancelled:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 20),
              const Text('Face Verify Cancelled',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _result = null;
                    _selectedImage = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      case EkycStatus.success:
        return _buildSuccessView(result);
    }
  }

  Widget _buildSuccessView(EkycResult result) {
    final parsed = result.parsed ?? {};
    final faceData = parsed['faceResult']?['data'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImage != null) ...[
            const Text('Selected Reference Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_selectedImage!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (faceData?['faceImageBase64'] != null)
            _buildImageSection(faceData!['faceImageBase64'], 'Captured Face Image'),

          const Text('Face Verification Results',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Divider(),

          _buildInfoRow('Session ID', result.sessionId),
          _buildInfoRow('Status', result.status.name.toUpperCase()),

          if (faceData != null) ...[
            _buildInfoRow('Face Verify Session ID', faceData['faceVerifySessionId']),
            _buildInfoRow('Liveness Detected', faceData['livenessDetected']?.toString()),
            _buildInfoRow('Face Match', faceData['faceIsMatch']?.toString()),
            if (faceData['confidence'] != null)
              _buildInfoRow('Face Matching Score',
                  '${(faceData['confidence'] as num).toStringAsFixed(2)}%'),
            _buildInfoRow('Nonce', faceData['nonce']),
            _buildInfoRow('URL', faceData['url']),
          ],

          const SizedBox(height: 30),

          ExpansionTile(
            title: const Text('Raw JSON Response',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.grey[900],
                child: SelectableText(
                  _formatJson(result.rawData),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _result = null;
                  _selectedImage = null;
                });
              },
              child: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(String jsonString) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(jsonString));
    } catch (e) {
      return jsonString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Verify')),
      body: _buildResultContent(),
    );
  }
}
