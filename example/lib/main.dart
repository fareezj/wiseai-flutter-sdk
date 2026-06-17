import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'face_verify_result_page.dart';
import 'mykad_result_page.dart';
import 'passport_result_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WiseAI SDK Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _language = 'EN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiseAI SDK Flutter Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyKadResultPage(language: _language),
                  ),
                );
              },
              child: const Text('Start MyKad EKYC'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PassportResultPage(language: _language),
                  ),
                );
              },
              child: const Text('Start Passport NFC EKYC'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FaceVerifyResultPage(language: _language),
                  ),
                );
              },
              child: const Text('Start Face Verify'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: _language,
          backgroundColor: Colors.grey.shade800,
          thumbColor: Colors.green,
          onValueChanged: (String? value) {
            if (value != null) {
              setState(() {
                _language = value;
              });
            }
          },
          children: const {
            'EN': Text('EN', style: TextStyle(color: Colors.white)),
            'BM': Text('BM', style: TextStyle(color: Colors.white)),
          },
        ),
      ),
    );
  }
}
