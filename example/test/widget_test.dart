// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:wiseai_sdk_plugin_example/main.dart';

void main() {
  testWidgets('Home page shows the three demo entry points', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.text('Start MyKad EKYC'), findsOneWidget);
    expect(find.text('Start Passport NFC EKYC'), findsOneWidget);
    expect(find.text('Start Face Verify'), findsOneWidget);
  });
}
