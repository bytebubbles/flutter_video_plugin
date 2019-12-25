import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer/controller/tencent_player_controller.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter_tencentplayer_example/video/control_widget.dart';
import 'package:flutter_tencentplayer_example/video/video_delegate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

import 'utils/flutter_screenutil.dart';

void main() => runApp(MyApp());
//final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
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
  NetPlayerControl netPlayerControl;
  NetPlayerControl netPlayerControl2;
  Directory directory;
  int _counter = 0;
  String spe1 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4';
  String spe2 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4';
  String spe3 =
      'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4';
  String spe4 =
      'https://img.mc.titilife.com/uploads/20191112/ED9E3F1B2DDC93EE04ABBE2874AFFA8E.mp4';

  void _incrementCounter() {
    //VolumeWatcher.setVolume(_counter*2.0);
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    initData();
    super.initState();
    //controller = TencentPlayerController.network(spe3,playerConfig: PlayerConfig(autoPlay: false));

  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil(width: 720, height: 1280, allowFontScaling: false)..init(context);
    List<Widget> items = [];
    items.add(NetworkPlayerLifeCycle(
        netPlayerControl: netPlayerControl,
        childBuilder:(BuildContext context, NetPlayerControl controller) => AspectRatioVideo(netPlayerControl)
    ),);
    items.add(NetworkPlayerLifeCycle(
        netPlayerControl: netPlayerControl2,
        childBuilder:(BuildContext context, NetPlayerControl controller) => AspectRatioVideo(netPlayerControl2)
    ),);

    return Scaffold(
      body: MaterialApp(
        home: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                /*Container(
                  padding: EdgeInsets.only(top: 200),
                  child: NetworkPlayerLifeCycle(
                      netPlayerControl: netPlayerControl,
                      childBuilder:(BuildContext context, NetPlayerControl controller) => AspectRatioVideo(netPlayerControl)
                  ),
                ),*/
                Container(
                  width: getWidth(),
                  height: getWidth(),
                  child: PageView.custom(
                      childrenDelegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index){
                            return KeepAlive(
                              widget: items[index],
                              key: ValueKey<String>("1234"),
                            );
                          },
                        childCount: 2,
                      )
                  ),
                ),
                FlatButton(
                  child: Text("dialog"),
                  onPressed: (){
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (s) {
                          return NetworkPlayerList(spe3);
                        }
                    );
                  },
                ),
                FlatButton(
                  child: Text("销毁"),
                  onPressed: (){
                    if(netPlayerControl.controller != null){
                      netPlayerControl.controller.dispose();
                    }
                  },
                ),
                FlatButton(
                  child: Text("暂停"),

                  onPressed: (){
                    print("---------------------暂停:${controller.hashCode}");
                    if(controller != null){
                      controller.pause();
                    }
                  },
                ),
                FlatButton(
                  child: Text("缓存信息"),

                  onPressed: (){
                    print("---------------------缓存信息:${controller.hashCode}");
                    if(netPlayerControl.controller != null){
                      netPlayerControl.controller.getCacheState();
                    }
                  },
                ),

              ],
            ),
          ),
        ),
      ) ,
      // r build methods.
    );
  }

  void initData() async {
    //directory = await getTemporaryDirectory();
    //print("cachePath:${directory.path}");
    String coverImg = "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574011235663&di=05b1a7ca666d55316d19f16bf2c4ab2b&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fblog%2F201510%2F20%2F20151020193329_rjWfs.jpeg";
    //String coverImg = null;
/*    directory = await getExternalStorageDirectory();
    print("cachePath:${directory.path}");*/
    //netPlayerControl = NetPlayerControl(spe3,PlayerConfig(autoLoading: false,autoPlay: false,switchCache: true, haveCacheAutoPlay: true, coverImgUrl: coverImg,defaultMute: true),);
    netPlayerControl = NetPlayerControl(spe3,PlayerConfigDelegate(coverImgUrl: null,switchCache: true,haveCacheAutoPlay: false,haveWifiAutoPlay: false,txPlayerConfig: PlayerConfig(autoPlay: false,autoLoading: false,defaultMute: true)));
    netPlayerControl2 = NetPlayerControl(spe4,PlayerConfigDelegate(coverImgUrl: null,switchCache: true,haveCacheAutoPlay: true,haveWifiAutoPlay: false,txPlayerConfig: PlayerConfig(autoPlay: false,autoLoading: false)));
    //controller = TencentPlayerController.network(spe3,playerConfig: PlayerConfig(autoPlay: true,switchCache: true, coverImgUrl: coverImg,defaultMute: true),);
    /*netPlayerControl.controller.initialize().then((_){
      setState(() {
      });
    });*/
    print("---------------------initData:${controller.hashCode}");
  }
}

class KeepAlive extends StatefulWidget {
  final Widget widget;
  const KeepAlive({Key key,this.widget}) : super(key: key);
  @override
  _KeepAliveState createState() => _KeepAliveState();
}
class _KeepAliveState extends State<KeepAlive> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.widget;
  }
}

double setWidth(int value){
  return ScreenUtil.getInstance().setWidth(value);
}

double getWidth(){
  return ScreenUtil.screenWidthDp;
}