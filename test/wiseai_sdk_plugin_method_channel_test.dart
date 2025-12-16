import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWiseaiSdkPlugin platform = MethodChannelWiseaiSdkPlugin();
  const MethodChannel channel = MethodChannel('wiseai_sdk_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
