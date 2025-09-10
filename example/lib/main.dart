import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_plugin/image_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ImagePlugin.platformVersion;
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Expanded(child:  Container(child: _showImages(),))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async{
            List<String> paths = await ImagePlugin.pickImages(maxImages: 2);
            if(paths!=null){
              for(String path in paths){
                print(path);
              }
              setState(() {
                _imagePaths = paths;
              });
            }
          },
          child:const Icon(Icons.image),
        ),
      ),
    );
  }
  List<String> _imagePaths = [];
  Widget _showImages(){
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2列布局
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0, // 正方形显示
      ),
      itemCount: _imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = _imagePaths[index];
        // 获取文件名用于显示
        // final fileName = File(imagePath).uri.pathSegments.last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            // 图片加载错误处理
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
