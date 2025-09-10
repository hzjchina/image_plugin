import 'dart:async';

import 'package:flutter/services.dart';

class ImagePlugin {
  static const MethodChannel _channel = const MethodChannel('image_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<List<String>> pickImages({int maxImages}) async {
    List<dynamic> paths = await _channel.invokeMethod<List<dynamic>>('pickImages', {'maxImages': maxImages ?? 1});
    if (paths != null && paths is List) {
      return paths.map((item) => item.toString()).toList();
    }
    return null;
  }
}
