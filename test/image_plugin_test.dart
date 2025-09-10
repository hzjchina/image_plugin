import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_plugin/image_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('image_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ImagePlugin.platformVersion, '42');
  });
}
