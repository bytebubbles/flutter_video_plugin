import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

import 'video/control_widget.dart';
import 'video/video_delegate.dart';

void main() => runApp(MyApp());
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TencentPlayerController controller;
  Directory directory;
  int _counter = 0;
  String spe1 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4';
  String spe2 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4';
  String spe3 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4';
  void _incrementCounter() {
    //VolumeWatcher.setVolume(_counter*2.0);
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //controller = TencentPlayerController.network(spe3,playerConfig: PlayerConfig(autoPlay: false));
    initData();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil(width: 720, height: 1280, allowFontScaling: false)..init(context);
    return Scaffold(
      backgroundColor: Colors.red,
      body: MaterialApp(
        color: Colors.red,
        home: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(

                /* width: ScreenUtil.getInstance().setWidth(400),
              height: ScreenUtil.getInstance().setWidth(400),*/
                child: NetworkPlayerLifeCycle(
                    controller: controller,
                    childBuilder:(BuildContext context, TencentPlayerController controller) => AspectRatioVideo(controller)
                ),
              )

            ],
          ),
        ),
        navigatorObservers: [routeObserver],
      ) ,
      // r build methods.
    );
  }

  void initData()  {
    //directory = await getTemporaryDirectory();
    //print("cachePath:${directory.path}");
    //String coverImg = "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574011235663&di=05b1a7ca666d55316d19f16bf2c4ab2b&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fblog%2F201510%2F20%2F20151020193329_rjWfs.jpeg";
    String coverImg = null;
    controller = TencentPlayerController.network(spe3,playerConfig: PlayerConfig(autoPlay: false,switchCache: true, coverImgUrl: coverImg, defaultMute: true),);
    //controller.isMute(true);
  }
}
