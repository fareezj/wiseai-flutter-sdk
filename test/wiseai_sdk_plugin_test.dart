import 'package:flutter_test/flutter_test.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin_platform_interface.dart';
import 'package:wiseai_sdk_plugin/wiseai_sdk_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWiseaiSdkPluginPlatform
    with MockPlatformInterfaceMixin
    implements WiseaiSdkPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WiseaiSdkPluginPlatform initialPlatform = WiseaiSdkPluginPlatform.instance;

  test('$MethodChannelWiseaiSdkPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWiseaiSdkPlugin>());
  });

  test('getPlatformVersion', () async {
    WiseaiSdkPlugin wiseaiSdkPlugin = WiseaiSdkPlugin();
    MockWiseaiSdkPluginPlatform fakePlatform = MockWiseaiSdkPluginPlatform();
    WiseaiSdkPluginPlatform.instance = fakePlatform;

    expect(await wiseaiSdkPlugin.getPlatformVersion(), '42');
  });
}
