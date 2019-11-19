
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  TencentPlayerController _controller;
  VoidCallback listener;

  Directory directory;
  String spe1 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4';
  String spe2 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4';
  String spe3 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4';
  var urls = [
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4',
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4',
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4',
    "http://file.jinxianyun.com/testhaha.mp4"
  ];
  int count = 0;
  _MyAppState(){
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initPlatformState();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      home: Scaffold(
        body: Container(
          child: Column(
            children: <Widget>[
              Center(
                child: _controller.value.initialized
                    ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: TencentPlayer(_controller),
                )
                    : Container(),
              ),

              FlatButton(
                onPressed: () {
                  String url;
                  if(count < 3){
                    count++;
                    url = urls[count];
                  }else {
                    count = 0;
                    url = urls[count];
                  }
                  _controller = TencentPlayerController.network(url);
                  _controller.initialize().then((_) {
                    setState(() {});
                  });
                  _controller.addListener(listener);
                },
                child: Text(
                  '更换',
                  style: TextStyle(
                      color: Colors.blue),
                ),
              ),
            ],
          )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  void initPlatformState() async {
    //directory = await getTemporaryDirectory();
    //print("-------${directory.path}");
   /* _controller = TencentPlayerController.network(spe3, playerConfig: PlayerConfig(
        cachePath: directory.path
    ))

//        _controller = TencentPlayerController.asset('static/tencent1.mp4')
//        _controller = TencentPlayerController.file('/storage/emulated/0/test.mp4')
      ..initialize().then((_) {
        setState(() {});
      });*/
    _controller = TencentPlayerController.network('http://file.jinxianyun.com/testhaha.mp4', playerConfig: PlayerConfig())
      ..initialize().then((_) {
        setState(() {});
      });
    _controller.addListener(listener);
  }
}
