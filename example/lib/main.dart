import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _wiseaiSdkPlugin = WiseaiSdkPlugin();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _wiseaiSdkPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    final plugin = WiseaiSdkPlugin();

    // Initialize
    await plugin.initSDK(
      clientId: '',
      baseUrl: 'https://wiseconsole-demo.wiseai.tech/',
    );

    // Set language
    await plugin.setLanguageCode('en');

    // Option 1: Start session without encryption (simpler, plain results)
    final sessionResult = await plugin.startNewSessionWithEncryption();

    // Option 2: Start session with encryption (more secure, requires decryption)
    // final sessionResult = await plugin.startNewSessionWithEncryption();

    if (sessionResult != null) {
      print('Session ID: ${sessionResult['sessionId']}');
      print('Full Data: ${sessionResult['fullData']}');
      if (sessionResult.containsKey('encryptionConfig')) {
        print('Encryption Config available for decryption');
      }
    }

    // Perform MyKad eKYC
    try {
      final result = await plugin.performEkyc(
        exportDoc: true,
        exportFace: true,
        cameraFacing: "FRONT",
      );
      print('eKYC Result: $result');
    } catch (e) {
      print('eKYC Error: $e');
    }

    // Or perform Passport eKYC
    // try {
    //   final result = await plugin.performPassportEkyc(
    //     exportDoc: true,
    //     exportFace: true,
    //     cameraFacing: "FRONT",
    //   );
    //   print('Passport eKYC Result: $result');
    // } catch (e) {
    //   print('Passport eKYC Error: $e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(child: Text('Running on: $_platformVersion\n')),
      ),
    );
  }
}
