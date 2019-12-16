
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/controller/tencent_player_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tencentplayer/model/player_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'control_widget.dart';
import 'dimension.dart';
import 'fullscreen_route.dart';

typedef Widget VideoWidgetBuilder(
    BuildContext context,   NetPlayerControl controller);

class VideoControl{

}

abstract class PlayerLifeCycle extends StatefulWidget {
  PlayerLifeCycle(this.childBuilder);
  final VideoWidgetBuilder childBuilder;
}

abstract class _PlayerLifeCycleState extends State<PlayerLifeCycle> {
  TencentPlayerController controller;
  NetPlayerControl netPlayerControl;
  Directory directory;
  bool isInitializing = false;
  Widget controlWidget;
  bool isReplay = false;
  VoidCallback _linster;
  int count = 0;
  double ic_play_width = setWidth(140);
  @override
  void initState() {
    //controller = createVideoPlayerController();
    netPlayerControl = createNetPlayerControl();
    controller = netPlayerControl.controller;
    _linster = (){
      if(controller.value.isDisconnect && !controller.value.isFullScreen){

        isReplay = true;
      }
      setState(() {});
    };
    _haveWifiAutoPlay();
    super.initState();
  }

  @override
  void didUpdateWidget(PlayerLifeCycle oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    //controller.removeListener(_linster);
    controller = netPlayerControl.controller;
    controller.addListener(_linster);
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    print("---layerLifeCycleState--dispose");
    //controller.dispose();
    netPlayerControl.controller.dispose();
    super.dispose();
  }

  _processController() async {
    if(controller.playerConfig.switchCache){
      directory = await getTemporaryDirectory();
      print("-------cache_path:${directory.path}");
      PlayerConfig playerConfig = controller.playerConfig.copyWith(cachePath: directory.path);
      controller.playerConfig = playerConfig;
    }
  }

  _haveWifiAutoPlay()async{
    if(controller.playerConfig.haveWifiAutoPlay){
      print("---------haveWifiAutoPlay");
      bool isWifiEnv = await _judgeNetState();
      bool autoPlay = controller.playerConfig.autoPlay;
      PlayerConfig playerConfig = controller.playerConfig.copyWith(autoPlay: isWifiEnv,haveWifiAutoPlay: false);
      controller.playerConfig = playerConfig;
      setState(() {});
    }
  }

  _judgeNetState()async{
    bool isWifiEnv = false;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
    } else if (connectivityResult == ConnectivityResult.wifi) {
      isWifiEnv = true;
    }
    return Future.value(isWifiEnv);
  }

  _initVideo()async{
    if(isInitializing){
      print("----已经初始化了-----");
      return ;
    }
    isInitializing = true;
    bool isWifiEnv = await _judgeNetState();
    if(!isWifiEnv){
      Fluttertoast.showToast(msg: "非wifi播放，请注意流量消耗",gravity: ToastGravity.CENTER);
    }
    await _processController();
    controller?.initialize()?.then((_) {
      isInitializing = false;
      setState(() {});
    });
    controller.addListener(_linster);
  }
  @override
  Widget build(BuildContext context) {
    if(isReplay){
      controlWidget = AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.black,
            ),
            Align(
              alignment: Alignment.center,
              child: Center(
                child: GestureDetector(
                  onTap: (){
                    String url = controller.dataSource;
                    PlayerConfig playerConfig = controller.playerConfig.copyWith(autoPlay: true);
                    controller.dispose();
                    controller = null;
                    controller = TencentPlayerController.network(url, playerConfig: playerConfig);
                    isReplay = false;
                    controller.addListener(_linster);
                    netPlayerControl.controller = controller;
                    isInitializing = false;
                    setState(() {});
                  },
                  child: Image.asset("images/ic_play.png",width: ic_play_width,height: ic_play_width),
                ) ,
              ),
            )
          ],
        ),
      );
    } else if(controller.playerConfig.haveWifiAutoPlay){
      controlWidget = Image.asset("halfoff/images/img_place_hold.png",fit: BoxFit.cover,);
    }else {
      if(!controller.playerConfig.autoPlay && !controller.value.initialized){
        if(!controller.value.initialized){
          _initVideo();
        }
        controlWidget = Stack(
          children: <Widget>[

            Material(child: widget.childBuilder(context, netPlayerControl),),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 0,
              child:  Center(
                child: Offstage(
                  offstage: controller.value.initialized,
                  child: Center(child: const CircularProgressIndicator(),),
                ),
              ),
            ),
          ],
        );
        /*Widget coverImg;
        if(controller.playerConfig.coverImgUrl != null && controller.playerConfig.coverImgUrl != ""){
          coverImg = CachedNetworkImage(
            imageUrl: controller.playerConfig.coverImgUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }else {
          coverImg = Container(
            color: Colors.black,
          );
        }
        controlWidget = AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: <Widget>[
              coverImg,
              Align(
                alignment: Alignment.center,
                child: Center(
                  child: GestureDetector(
                    onTap: (){
                      PlayerConfig playerConfig = controller.playerConfig.copyWith(autoPlay: true);
                      controller.playerConfig = playerConfig;
                      _initVideo();
                    },
                    child: Image.asset("images/ic_play.png",width: setWidth(140),height: setWidth(140)),
                  ) ,
                ),
              )
            ],
          ),
        );*/
      }else {
        if(!controller.value.initialized){
          _initVideo();
        }
        controlWidget = Stack(
          children: <Widget>[

            Material(child: widget.childBuilder(context, netPlayerControl),),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 0,
              child:  Center(
                child: Offstage(
                  offstage: controller.value.initialized,
                  child: Center(child: const CircularProgressIndicator(),),
                ),
              ),
            ),
          ],
        );
      }
    }
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        controlWidget,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: 0,
          child:  (controller.playerConfig.coverImgUrl != null && controller.value.playend ) ? Stack(
            children: <Widget>[

              CachedNetworkImage(
                imageUrl: controller.playerConfig.coverImgUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Align(
                alignment: Alignment.center,
                child: Center(
                  child: GestureDetector(
                    onTap: (){
                      controller.play();
                    },
                    child: Image.asset("images/ic_play.png",width: setWidth(140),height: setWidth(140)),
                  ) ,
                ),
              )

            ],
          ):Container(),
        ),

      ],
    ) ;
  }

  TencentPlayerController createVideoPlayerController();
  NetPlayerControl createNetPlayerControl();
}


class NetworkPlayerLifeCycle extends PlayerLifeCycle {
  //final TencentPlayerController controller;
  final NetPlayerControl netPlayerControl;
  NetworkPlayerLifeCycle({VideoWidgetBuilder childBuilder, this.netPlayerControl})
      : super(childBuilder);

  @override
  _NetworkPlayerLifeCycleState createState() => _NetworkPlayerLifeCycleState(netPlayerControl);
}

class _NetworkPlayerLifeCycleState extends _PlayerLifeCycleState {
  //TencentPlayerController controller;
  final NetPlayerControl netPlayerControl;
  _NetworkPlayerLifeCycleState(this.netPlayerControl);
  @override
  TencentPlayerController createVideoPlayerController() {
    return controller;
    //return TencentPlayerController.network(widget.dataSource);
  }

  @override
  NetPlayerControl createNetPlayerControl() {
    // TODO: implement createNetPlayerControl
    return netPlayerControl;
  }
}

class NetworkPlayerList extends PlayerLifeCycle{
  final String url;
  final PlayerConfig playerConfig;
  NetworkPlayerList(this.url,{this.playerConfig = const PlayerConfig(autoPlay: true,switchCache: true, coverImgUrl: null,defaultMute: true)}):
        super((BuildContext context,   NetPlayerControl controller){
    return FullControl(controller,Axis.vertical);
  });
  @override
  _NetworkPlayerListState createState() => _NetworkPlayerListState(url,playerConfig);
}

class _NetworkPlayerListState extends _PlayerLifeCycleState{
  final String url;
  final PlayerConfig playerConfig;
  NetPlayerControl netPlayerControl;
  _NetworkPlayerListState(this.url,this.playerConfig);
  @override
  TencentPlayerController createVideoPlayerController() {
    //String coverImg = null;
    controller = TencentPlayerController.network(url,playerConfig: playerConfig,);
    return controller;
  }

  @override
  NetPlayerControl createNetPlayerControl() {
    // TODO: implement createNetPlayerControl
    return NetPlayerControl(url, playerConfig);
  }
}

class NetPlayerControl{
  String url;
  PlayerConfig playerConfig;
  TencentPlayerController _controller;

  TencentPlayerController get controller {
    return _controller;
  }
  set controller (TencentPlayerController controller){
    _controller = controller;
  }

  NetPlayerControl(this.url,this.playerConfig){

    controller = TencentPlayerController.network(url,playerConfig: playerConfig,);
  }

}