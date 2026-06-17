import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin.dart';

class MyKadResultPage extends StatefulWidget {
  final String language;

  const MyKadResultPage({super.key, required this.language});

  @override
  State<MyKadResultPage> createState() => _MyKadResultPageState();
}

class _MyKadResultPageState extends State<MyKadResultPage> {
  final WiseaiSdkPlugin _wiseaiSdkPlugin = WiseaiSdkPlugin();
  StreamSubscription<EkycResult>? _resultSubscription;
  EkycResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _resultSubscription = _wiseaiSdkPlugin.resultStream.listen((result) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
      _showResultDialog(result);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startEkyc();
    });
  }

  void _startEkyc() {
    // Platform-specific config (Android vs iOS parameters)
    final config = Platform.isAndroid
        ? AndroidMyKadEkycConfig(
            apiToken: "YOUR_API_TOKEN",
            apiURL: "YOUR_API_URL",
            language: widget.language,
            isEncrypt: false,
            isExportFace: true,
            isActiveLiveness: false,
            //extraParam: extraParam,
          )
        : IosMyKadEkycConfig(
            apiToken: "YOUR_API_TOKEN",
            apiURL: "YOUR_API_URL",
            language: widget.language,
            isEncrypt: false,
            isExportFace: true,
            isExportDoc: false,
            //extraParam: extraParam,
          );
    _wiseaiSdkPlugin.performEkyc(config);
  }

  void _showResultDialog(EkycResult result) {
    final (title, color) = switch (result.status) {
      EkycStatus.success => ('✅ EKYC COMPLETE', Colors.green),
      EkycStatus.sdkError => ('❌ EKYC EXCEPTION', Colors.red),
      EkycStatus.cancelled => ('⚠️ EKYC CANCELLED', Colors.orange),
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
            const Text(
              'Session ID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(result.sessionId.isEmpty ? 'N/A' : result.sessionId),
            const SizedBox(height: 10),
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
    if (base64Image == null || base64Image.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Image.memory(
            base64Decode(base64Image),
            height: 200,
            fit: BoxFit.contain,
          ),
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
        ? value
              .whereType<Object>()
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .join(', ')
        : value.toString();

    if (displayValue.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(displayValue, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(
    EkycResult result, {
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (result.errorCode != null)
              Text(
                'Error Code: ${result.errorCode}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (result.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                result.errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
            if (result.sessionId.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Session ID: ${result.sessionId}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text('Raw Response'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey[900],
                  child: SelectableText(
                    _formatJson(result.rawData),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Processing MyKad eKYC...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return const Center(child: Text('No result available'));
    }

    switch (result.status) {
      case EkycStatus.sdkError:
        return _buildErrorView(
          result,
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'eKYC Error',
        );
      case EkycStatus.bridgeError:
        return _buildErrorView(
          result,
          icon: Icons.warning_amber,
          color: Colors.red,
          title: 'Bridge Error',
        );
      case EkycStatus.cancelled:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_outlined, size: 64, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                'eKYC Cancelled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final idFront = parsed['idFront']?['data'] as Map<String, dynamic>?;
    final matching = parsed['matchingResult']?['data'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (idFront?['faceImageBase64'] != null)
            _buildImageSection(idFront!['faceImageBase64'], 'Face Image'),
          if (idFront?['documentImageBase64'] != null)
            _buildImageSection(
              idFront!['documentImageBase64'],
              'Document Image',
            ),
          const Text(
            'MyKad Information',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Divider(),
          _buildInfoRow('Session ID', result.sessionId),
          _buildInfoRow('Status', result.status.name.toUpperCase()),
          if (idFront != null) ...[
            _buildInfoRow('Name', idFront['name']),
            _buildInfoRow('IC Number', idFront['icNumber']),
            _buildInfoRow('Date of Birth', idFront['birthDateISO']),
            _buildInfoRow('Gender', idFront['gender']),
            _buildInfoRow('Religion', idFront['religion']),
            _buildInfoRow('Address', idFront['fullAddress']),
          ],
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Verification Results',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Liveness Detected',
            parsed['livenessDetected']?.toString(),
          ),
          _buildInfoRow('Face Match', parsed['faceIsMatch']?.toString()),
          _buildInfoRow('ID Front Valid', parsed['idFrontIsValid']?.toString()),
          _buildInfoRow('ID Back Valid', parsed['idBackIsValid']?.toString()),
          if (matching?['confidence'] != null)
            _buildInfoRow(
              'Face Matching Score',
              '${(matching!['confidence'] as num).toStringAsFixed(2)}%',
            ),
          const SizedBox(height: 30),
          ExpansionTile(
            title: const Text(
              'Raw JSON Response',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
      appBar: AppBar(title: const Text('MyKad eKYC Result')),
      body: _buildResultContent(),
    );
  }
}
