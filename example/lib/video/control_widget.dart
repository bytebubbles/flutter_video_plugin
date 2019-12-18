

import 'dart:async';
import 'dart:io';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dimension.dart';
import 'fullscreen_route.dart';
import 'progress_slider.dart';
import 'video_delegate.dart';

class AspectRatioVideo extends StatefulWidget {
  AspectRatioVideo(this.controller,{this.aspectRatio = 1});

  final NetPlayerControl controller;
  final double aspectRatio;
  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  NetPlayerControl get controller => widget.controller;
  bool initialized = false;

  VoidCallback listener;

  @override
  void initState() {
    super.initState();
    listener = () {
      if (!mounted) {
        return;
      }
      if (initialized != controller.controller.value.initialized) {
        initialized = controller.controller.value.initialized;
        setState(() {});
      }
    };
    controller.controller.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: VideoFrame(controller),
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.black,
        ),
      );
    }
  }
}

class VideoFrame extends StatefulWidget {
  final NetPlayerControl controller;
  VideoFrame(this.controller);

  @override
  _VideoFrameState createState() => _VideoFrameState();
}

class _VideoFrameState extends State<VideoFrame>  with  SingleTickerProviderStateMixin  {

  NetPlayerControl get controller => widget.controller;
  //TencentPlayerController get txController => widget.controller.controller;
  TencentPlayerController txController;
  VoidCallback listener;
  FadeAnimation imageFadeAnim;
  Widget controlAni ;
  Timer resetHideCountDownTimer;
  bool isShowControl = true;
  bool isTiming = true;
  bool isLoading = false;
  bool isDispose = false;

  Widget playAllow = Image.asset("images/ic_play.png",width: setWidth(140),height: setWidth(140));
  Widget pauseAllow = Image.asset("images/ic_pause.png",width: setWidth(140),height: setWidth(140));
  //动画控制器
  AnimationController aniCtrl;
  Animation<Offset> downOffsetAnimation;
  Animation<Offset> rightOffsetAnimation;
  Animation<double> opacityAnimation;

  //重置隐藏控制面板的计时
  void resetHideCountDown(){

    if(isTiming){
      _clearTime();
      isTiming = false;
      //print("isTiming = true;");
      if(aniCtrl != null){
        if(!isDispose) aniCtrl.forward();
      }
    }else {
      isTiming = true;
      aniCtrl.reverse();
      _startTime();
    }
  }
  _startTime(){
    _clearTime();
    resetHideCountDownTimer = Timer(Duration(seconds: 2),(){
      setState(() {
        isTiming = false;
        if(!isDispose) aniCtrl.forward();
      });
    });
  }
  //隐藏控制面板
  void hideControlPanel(){
    _clearTime();
    if(!isDispose) aniCtrl.reverse();
  }

  _clearTime(){
    if(resetHideCountDownTimer != null){
      resetHideCountDownTimer.cancel();
      resetHideCountDownTimer = null;
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    //routeObserver.subscribe(this, ModalRoute.of(context));
  }
  @override
  void didUpdateWidget(VideoFrame oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    //oldWidget.controller.controller.removeListener(listener);
    txController = widget.controller.controller;
    txController.addListener(listener);
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    txController = controller.controller;
    listener = () {
      if(txController.value.reconnectCount > 0){
        //尝试重连
        isLoading = true;
        print("重连${txController.value.reconnectCount}");
      }else {
        if(txController.value.isLoading){
          isLoading = true;
        }else {
          isLoading = false;
        }
      }
      setState(() {});
    };
    imageFadeAnim = FadeAnimation(child: playAllow);
    txController.addListener(listener);
    _startTime();
    initAnimation();
  }
  initAnimation(){
    aniCtrl = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    aniCtrl.addListener((){
      if (mounted) {
        setState(() {});
      }
    });
    aniCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //AnimationStatus.completed 动画在结束时停止的状态
        //print("AnimationStatus.completed");
        setState(() {isShowControl = false;});
      } else if (status == AnimationStatus.dismissed) {
        //AnimationStatus.dismissed 表示动画在开始时就停止的状态
        //print("AnimationStatus.dismissed");
        setState(() {isShowControl = true;});
      }
    });
    downOffsetAnimation = Tween(begin: Offset(0, 0), end: Offset(0, 1)).animate(aniCtrl);
    rightOffsetAnimation = Tween(begin: Offset(0, 0), end: Offset(2, 0)).animate(aniCtrl);
    opacityAnimation =  Tween<double>(begin: 1, end: 0).animate(aniCtrl);
  }
  @override
  void deactivate() {
    // TODO: implement deactivate
    //controller.controller.removeListener(listener);
    aniCtrl.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    //routeObserver.unsubscribe(this);
    _clearTime();
    isDispose = true;
    aniCtrl.dispose();
    txController.removeListener(listener);
    widget.controller.controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    String position = txController.value.position.toString();
    if (position.lastIndexOf(".") > -1) {
      position = position.substring(position.indexOf(":")+1, position.lastIndexOf("."));
    }

    String duration = txController.value.duration.toString();
    if (duration.lastIndexOf(".") > -1) {
      duration = duration.substring(position.indexOf(":")+1, duration.lastIndexOf("."));
    }

    Widget control = Stack(
      children: <Widget>[
        //进度条

        Positioned(
          bottom: setWidth(28),
          child: SlideTransition(
            position: downOffsetAnimation,
            child:Opacity(
              opacity: 1.0 - aniCtrl.value,
              child: Container(
                padding: EdgeInsets.only(left: setWidth(20),right: setWidth(20)),
                //height: setWidth(40),
                width: setWidth(544),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: setWidth(16)),
                      child: GestureDetector(
                        onTap: (){
                          if (!txController.value.initialized) {
                            return;
                          }
                          if(!isShowControl) return;
                          if (txController.value.isPlaying) {
                            //imageFadeAnim = FadeAnimation(child: playAllow);
                            txController.pause();
                          } else {
                            //imageFadeAnim = FadeAnimation(child: pauseAllow);
                            txController.play();
                          }
                        },
                        child: Icon(txController.value.isPlaying ? Icons.pause : Icons.play_arrow,color: Colors.white, size: setWidth(32)),
                      ),
                    ),
                    Expanded(
                      child: ProgressWidget(controller,stateCallBack: (state){
                        if(state == ProgressState.dragging){
                          _clearTime();
                        }else {
                          _startTime();
                        }
                      },),
                    ),
                  ],
                ),
              ),
            )
          ),

        ),
        //右侧按钮
        Positioned(
          right: setWidth(26),
          bottom: setWidth(70),
          child: SlideTransition(
            position: rightOffsetAnimation,
            child: Opacity(
              opacity: 1.0 - aniCtrl.value,
              child: Column(
                children: <Widget>[
                  //音量按钮
                  GestureDetector(
                    onTap: (){
                      if (!txController.value.initialized) {
                        return;
                      }
                      if(!isShowControl) return;
                      if(txController.value.isMute){
                        txController.isMute(false);
                      }else {
                        txController.isMute(true);
                      }
                    },
                    child: Image.asset( txController.value.isMute ? "images/ic_mute.png" : "images/ic_noise.png", width: setWidth(76),height: setWidth(76)),
                  ),
                  //是否全屏
                  GestureDetector(
                    onTap: (){
                      print("${isShowControl}");
                      if(!isShowControl) return;
                      txController.removeListener(listener);
                      //hideControlPanel();
                      //_showFullScreenWithRotateBox(context,controller);
                      showFullScreenWithRotateScreen(context,controller,popCallBack: (){
                        resetHideCountDown();
                        //txController.addListener(listener);
                      });
                    },
                    child: Image.asset("images/ic_full_screen.png",width: setWidth(76),height: setWidth(76),),
                  )
                ],
              ),
            ),
          ),
        ),

        1.0 - aniCtrl.value > 0 ? Center(child: GestureDetector(
          onTap: (){
            if (!txController.value.initialized) {
              return;
            }
            if(!isShowControl) return;
            if (txController.value.isPlaying) {
              //imageFadeAnim = FadeAnimation(child: playAllow);
              txController.pause();
            } else {
              //imageFadeAnim = FadeAnimation(child: pauseAllow);
              txController.play();
            }
            resetHideCountDown();
          },
          child: Opacity(
            opacity: 1.0 - aniCtrl.value,
            child: txController.value.isPlaying ? pauseAllow :  playAllow,
          ),
        )):Container(),
      ],
    );

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        GestureDetector(
          child: TencentPlayer(txController),
          onTap: (){
            resetHideCountDown();
          },
        ),
        control,

        Center(child: isLoading   ? const CircularProgressIndicator() : null),
      ],
    );
  }
}

class FadeAnimation extends StatefulWidget {
  FadeAnimation(
      {this.child, this.duration = const Duration(milliseconds: 500)});

  final Widget child;
  final Duration duration;

  @override
  _FadeAnimationState createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: widget.duration, vsync: this);
    animationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    animationController.forward(from: 0.0);
  }

  @override
  void deactivate() {
    animationController.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return animationController.isAnimating
        ? Opacity(
      opacity: 1.0 - animationController.value,
      child: widget.child,
    )
        : Container();
  }
}

///全屏Navigator
_showFullScreenWithRotateBox(
    BuildContext context,
    NetPlayerControl controller, {
      VideoWidgetBuilder fullscreenControllerWidgetBuilder,
    }) async {
  var info = controller.controller.value.size;

  Axis axis;

  if (info.width == 0 || info.height == 0) {
    axis = Axis.horizontal;
  } else if (info.width > info.height) {

    axis = Axis.horizontal;
  } else {

    axis = Axis.vertical;
  }

  Navigator.push(
    context,
    FullScreenRoute(
      builder: (ctx) {
        var mediaQueryData = MediaQuery.of(ctx);

        int quarterTurns;

        if (axis == Axis.horizontal) {
          if (mediaQueryData.orientation == Orientation.landscape) {
            quarterTurns = 0;
          } else {
            quarterTurns = 1;
          }
        } else {
          quarterTurns = 0;
        }

        return SafeArea(
          child: RotatedBox(
            quarterTurns: 0,
            child: AspectRatio(
              aspectRatio: controller.controller.value.aspectRatio,
              child: TencentPlayer(controller.controller),
            ),
          ),
        );
      },
    ),
  );
}

showFullScreenWithRotateScreen(
    BuildContext context,
    NetPlayerControl controller,
    {VideoWidgetBuilder fullscreenControllerWidgetBuilder, VoidCallback popCallBack, Axis axis}) async {
  //VideoFrame(controller)
  //TencentPlayer(controller)


  var info = await controller.controller.value.size;

  //Axis axis;
  if(axis == null){
    if (info.width == 0 || info.height == 0) {
      axis = Axis.horizontal;
    } else if (info.width > info.height) {

      axis = Axis.horizontal;
    } else {

      axis = Axis.vertical;
    }
  }

  //AutoOrientation.portraitUpMode();
  if (axis == Axis.horizontal) {
    AutoOrientation.landscapeAutoMode();
  } else {
    AutoOrientation.portraitUpMode();
  }
  controller.controller.value = controller.controller.value.copyWith(isFullScreen: true);
  SystemChrome.setEnabledSystemUIOverlays([]);
  Navigator.push(
    context,
    FullScreenRoute(
      builder: (c) {
        return FullControl(controller,axis);
      },
    ),
  ).then((_) {
    popCallBack();
    controller.controller.value = controller.controller.value.copyWith(isFullScreen: false);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    AutoOrientation.portraitUpMode();
  });
}

///全屏控制面板
class FullControl extends StatefulWidget {
  final NetPlayerControl controller;
  final Axis axis;
  FullControl(this.controller, this.axis);
  @override
  _FullControlState createState() => _FullControlState();
}

class _FullControlState extends State<FullControl> with SingleTickerProviderStateMixin {

  NetPlayerControl get controller => widget.controller;
  Axis get axis => widget.axis;
  VoidCallback listener;
  FadeAnimation imageFadeAnim;
  Widget controlAni ;
  Timer resetHideCountDownTimer;
  bool isShowControl = true;
  bool isTiming = true;
  bool isReplay = false;
  bool isInitializing = false;
  double ic_play_width = setWidth(140);
  Directory directory;
  //动画控制器
  AnimationController aniCtrl;
  Animation<Offset> downOffsetAnimation;
  Animation<Offset> rightOffsetAnimation;
  Animation<double> opacityAnimation;

  Widget playAllow = Image.asset("images/ic_play.png",width: 70,height: 70);
  Widget pauseAllow = Image.asset("images/ic_pause.png",width: 70,height: 70);

  _setWidthDelegate(value){
    if(axis == Axis.horizontal){
      return setFullWidth(value);
    }else {
      return setWidth(value);
    }
  }
  _setSpDelegate(value){
    if(axis == Axis.horizontal){
      return setFullSp(value);
    }else {
      return setSp(value);
    }
  }


  //重置隐藏控制面板的计时
  void resetHideCountDown(){
    if(isTiming){
      _clearTime();
      isTiming = false;
      //print("isTiming = true;");
      if(aniCtrl != null){
        aniCtrl.forward();
      }
    }else {
      isTiming = true;
      //print("isTiming = false;");
      aniCtrl.reverse();
      _startTime();
    }
  }
  //隐藏控制面板
  void hideControlPanel(){
    _clearTime();
  }
  _startTime(){
    _clearTime();
    resetHideCountDownTimer = Timer(Duration(seconds: 2),(){
      setState(() {
        isTiming = false;
        aniCtrl.forward();
      });
    });
  }
  _clearTime(){
    if(resetHideCountDownTimer != null){
      resetHideCountDownTimer.cancel();
      resetHideCountDownTimer = null;
    }
  }

  initAnimation(){
    aniCtrl = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    aniCtrl.addListener((){
      if (mounted) {
        setState(() {});
      }
    });
    aniCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //AnimationStatus.completed 动画在结束时停止的状态
        //ontroller.reverse();
        setState(() {isShowControl = false;});
      } else if (status == AnimationStatus.dismissed) {
        //AnimationStatus.dismissed 表示动画在开始时就停止的状态
        //controller.controller.forward();
        setState(() {isShowControl = true;});
      }
    });
    downOffsetAnimation = Tween(begin: Offset(0, 0), end: Offset(0, 1)).animate(aniCtrl);
    rightOffsetAnimation = Tween(begin: Offset(0, 0), end: Offset(2, 0)).animate(aniCtrl);
    opacityAnimation =  Tween<double>(begin: 1, end: 0).animate(aniCtrl);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listener = () {
      if (!mounted) return;
      if(controller.controller.value.isDisconnect){
        isReplay = true;
      }
      setState(() {});
    };
    _startTime();
    imageFadeAnim = FadeAnimation(child: playAllow);
    controller.controller.addListener(listener);
    initAnimation();
    //controller.controller.play();
  }

  @override
  void deactivate() {
    // TODO: implement deactivate

    aniCtrl.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _clearTime();
    controller.controller.removeListener(listener);
    aniCtrl.dispose();
    super.dispose();
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
  _processController() async {
    if(controller.playerConfigDelegate.switchCache){
      directory = await getTemporaryDirectory();
      print("-------cache_path:${directory.path}");
      PlayerConfig playerConfig = controller.playerConfig.copyWith(cachePath: directory.path);
      controller.playerConfig = playerConfig;
    }
  }
  _initVideo()async{
    if(isInitializing){
      print("----已经初始化了-----");
      return ;
    }
    isInitializing = true;
    bool isWifiEnv = await _judgeNetState();
    if(!isWifiEnv){
      Fluttertoast.showToast(msg: "非wifi播放，请注意流量消耗");
    }
    //await _processController();
    controller?.controller?.initialize()?.then((_) {
      isInitializing = false;
      isReplay = false;
      setState(() {});
    });
    controller.controller.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    String position = controller.controller.value.position.toString();
    if (position.lastIndexOf(".") > -1) {
      position = position.substring(position.indexOf(":")+1, position.lastIndexOf("."));
    }

    String duration = controller.controller.value.duration.toString();
    if (duration.lastIndexOf(".") > -1) {
      duration = duration.substring(position.indexOf(":")+1, duration.lastIndexOf("."));
    }

    Widget control = Stack(
      children: <Widget>[
        //进度条
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: downOffsetAnimation,
              child:Container(
                padding: EdgeInsets.only(left: _setWidthDelegate(33),right: _setWidthDelegate(33),bottom: _setWidthDelegate(28)),
                //height: setFullWidth(40),
                //width: setFullWidth(544),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    Expanded(
                      child: ProgressWidget(controller,axis: axis,stateCallBack: (state){
                        if(state == ProgressState.dragging){
                          _clearTime();
                        }else {
                          _startTime();
                        }
                      },),
                    ),

                    axis==Axis.horizontal ? Padding(
                      padding: EdgeInsets.only(left: _setWidthDelegate(19)),
                      child: GestureDetector(
                        onTap: (){

                          Navigator.pop(context);
                        },
                        child: Image.asset("images/ic_small_screen.png",width: _setWidthDelegate(48),height: _setWidthDelegate(48)),
                      ),
                    ):Container(),
                    Padding(
                      padding: EdgeInsets.only(left: _setWidthDelegate(0)),
                      child: GestureDetector(
                        onTap: (){
                          if (!controller.controller.value.initialized) {
                            return;
                          }
                          if(!isShowControl) return;
                          if(controller.controller.value.isMute){
                            controller.controller.isMute(false);
                          }else {
                            controller.controller.isMute(true);
                          }
                        },
                        child: Image.asset( controller.controller.value.isMute ? "images/ic_mute.png" : "images/ic_noise.png", width: _setWidthDelegate(76),height: _setWidthDelegate(76)),
                      ),
                    ),
                    //音量按钮,
                  ],
                ),
              ),
            )


        ),

        1.0 - aniCtrl.value > 0 ?Center(child: GestureDetector(
          onTap: (){
            if (!controller.controller.value.initialized) return;
            if(!isShowControl) return;
            if (controller.controller.value.isPlaying) {
              //imageFadeAnim = FadeAnimation(child: playAllow);
              controller.controller.pause();
            } else {
              //imageFadeAnim = FadeAnimation(child: pauseAllow);
              controller.controller.play();
            }

          },
          child: Opacity(
            opacity: 1.0 - aniCtrl.value,
            child: controller.controller.value.isPlaying ? pauseAllow :  playAllow,
          ),
        )):Container(),

        Positioned(
          left: _setWidthDelegate(34),
          top: axis == Axis.horizontal ? _setWidthDelegate(34) : _setWidthDelegate(62),
          child: Opacity(
              opacity: 1.0 - aniCtrl.value,
              child: GestureDetector(
                onTap: (){
                  if(!isShowControl) return;
                  Navigator.pop(context);
                },
                child: Image.asset(
                  "images/ic_close2.png",
                  width: _setWidthDelegate(64),
                  height: _setWidthDelegate(64),
                ),
              )
          ),
        )

      ],
    );

    Widget playControl ;

    if(isReplay && controller.controller.value.isFullScreen){
      playControl = AspectRatio(
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
                    String url = controller.controller.dataSource;
                    PlayerConfig playerConfig = controller.controller.playerConfig.copyWith(autoPlay: true);
                    controller.controller.dispose();
                    controller.controller = null;
                    controller.controller = TencentPlayerController.network(url, playerConfig: playerConfig);
                    controller.controller.value = controller.controller.value.copyWith(isFullScreen: true);
                    //print("--------controller.value:${controller.controller.value}--controller.config:${controller.controller.playerConfig}");
                    isReplay = false;
                    isInitializing = false;
                    _initVideo();
                    setState(() {});
                  },
                  child: Image.asset("images/ic_play.png",width: ic_play_width,height: ic_play_width),
                ) ,
              ),
            )
          ],
        ),
      );
    }else {
      playControl = Container(
        color: Colors.black,
        child: GestureDetector(
          onTap: (){
            if (!controller.controller.value.initialized) {
              return;
            }
            resetHideCountDown();
          },
          child: Stack(
            //fit: StackFit.passthrough,
            children: <Widget>[
              controller.controller.value.initialized ? TencentPlayer(controller.controller) : Center(child: CircularProgressIndicator(),),
              control,

              Center(child: controller.controller.value.isLoading ? const CircularProgressIndicator() : null),
            ],
          ),
        ),
      )  ;
    }

    return playControl;
  }
}

enum ProgressState{
  dragging,
  dragend
}
typedef void ProgressStateCallback(ProgressState state);
///滑动条
class ProgressWidget extends StatefulWidget {
  final Axis axis;
  final ProgressStateCallback stateCallBack;
  ProgressWidget(this.controller, {this.axis = Axis.vertical, this.stateCallBack});

  final NetPlayerControl controller;

  @override
  _ProgressWidgetState createState() =>
      _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget>  {
  get axis => widget.axis;
  NetPlayerControl get controller => widget.controller;
  ProgressStateCallback get callback => widget.stateCallBack;
  double position = 0;
  double buffer = 0;
  VoidCallback listener;
  bool isDragging = false;

  _setWidthDelegate(value){
    if(axis == Axis.horizontal){
      return setFullWidth(value);
    }else {
      return setWidth(value);
    }
  }
  _setSpDelegate(value){
    if(axis == Axis.horizontal){
      return setFullSp(value);
    }else {
      return setSp(value);
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    //print(" hash:${this.hashCode}---ProgressWidget-didChangeDependencies");
    super.didChangeDependencies();
    //routeObserver.subscribe(this, ModalRoute.of(context));
  }
  @override
  void didUpdateWidget(ProgressWidget oldWidget) {
    // TODO: implement didUpdateWidget
    //print("-hash:${this.hashCode}--ProgressWidget-didUpdateWidget");
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.controller.removeListener(listener);
    widget.controller.controller.addListener(listener);
  }
  @override
  void initState() {
    super.initState();
    //print("-hash:${this.hashCode}--ProgressWidget-initState");
    listener = (){
      //print("--mounted:${mounted}---isDragging:${isDragging}");
      if (!mounted) return;
      if(isDragging) return;
      setState(() {
        position = controller.controller.value.position.inMilliseconds.toDouble();
        buffer = controller.controller.value.playable.inMilliseconds.toDouble();
      });
    };
    controller.controller.addListener(listener);
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    //print("-hash:${this.hashCode}--ProgressWidget-deactivate");
    super.deactivate();
  }

  @override
  void dispose() {

    // TODO: implement dispose
    //routeObserver.unsubscribe(this);
    controller.controller.removeListener(listener);
    //print("-hash:${this.hashCode}--ProgressWidget-dispose");
    super.dispose();
  }

  double get bufferRatio{
    double d = controller.controller.value.duration.inMilliseconds.toDouble();
    if(d <= 0) return 0;

    double b = buffer/d;
    //print("--bufferRatio:${b}");
    return b;
  }
  double get positionRatio{
    double d = controller.controller.value.duration.inMilliseconds.toDouble();
    if(d <= 0) return 0;
    double p = position/d;
    //print("--positionRatio:${p}");
    return p;
  }

  @override
  Widget build(BuildContext context) {
    //controller.controller.value.position.inMilliseconds.toDouble();
    //String positionStr = controller.controller.value.position.toString();
    String positionStr = Duration(milliseconds: position.toInt()).toString();
    if (positionStr.lastIndexOf(".") > -1) {
      positionStr = positionStr.substring(positionStr.indexOf(":")+1, positionStr.lastIndexOf("."));
    }

    String duration = controller.controller.value.duration.toString();
    if (duration.lastIndexOf(".") > -1) {
      duration = duration.substring(positionStr.indexOf(":")+1, duration.lastIndexOf("."));
    }
    return controller.controller.value.duration.inMilliseconds.toDouble() >= position
        ?  Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: _setWidthDelegate(16)),
          child: Text(
            "${positionStr}",
            style: TextStyle(
              color: Colors.white,
              fontSize: _setSpDelegate(22),
            ),
          ),
        ),
        Expanded(
          child: ProgressSlider(
            borderRadius:  BorderRadius.circular(setWidth(10)),
            inactiveColor: Colors.white24,
            bufferColor: Colors.white38,
            activeColor: Colors.white,
            value: positionRatio,
            bufferValue: bufferRatio,
            onChanged: (value){
              //print("-----------onChanged");
              if(!isDragging){
                isDragging = true;
                if(callback != null) callback(ProgressState.dragging);
              }
              setState(() {
                position = value * controller.controller.value.duration.inMilliseconds;
              });
            },
            onChangeEnd: (value){
             // print("-----------onChangeEnd");
              isDragging = false;
              if(callback != null) callback(ProgressState.dragend);
              setState(() {
                controller.controller.seekTo(Duration(milliseconds: position.toInt()));
              });
            },
            onTap: (value){
              //print("-----------onTap${value}");
              isDragging = false;
              if(callback != null) callback(ProgressState.dragend);
              setState(() {
                double pos = value * controller.controller.value.duration.inMilliseconds;
                controller.controller.seekTo(Duration(milliseconds: pos.toInt()));
              });
            },
            onVerticalDragCancel: (value){
              isDragging = false;
              if(callback != null) callback(ProgressState.dragend);
              setState(() {
                controller.controller.seekTo(Duration(milliseconds: position.toInt()));
              });
            },

          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: _setWidthDelegate(16)),
          child: Text(
            "${duration}",
            style: TextStyle(
              color: Colors.white,
              fontSize: _setSpDelegate(22),
            ),
          ),
        ),
      ],
    )
        : Container();

  }
}





