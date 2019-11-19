

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter/widgets.dart';
import 'package:auto_orientation/auto_orientation.dart';
import '../control_main.dart';
import 'dimension.dart';
import 'fullscreen_route.dart';
import 'progress_slider.dart';
import 'video_delegate.dart';

class AspectRatioVideo extends StatefulWidget {
  AspectRatioVideo(this.controller);

  final TencentPlayerController controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  TencentPlayerController get controller => widget.controller;
  bool initialized = false;

  VoidCallback listener;

  @override
  void initState() {
    super.initState();
    listener = () {
      if (!mounted) {
        return;
      }
      if (initialized != controller.value.initialized) {
        initialized = controller.value.initialized;
        setState(() {});
      }
    };
    controller.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: VideoFrame(controller),
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.black,
        ),
      );
    }
  }
}

class VideoFrame extends StatefulWidget {
  final TencentPlayerController controller;
  VideoFrame(this.controller);

  @override
  _VideoFrameState createState() => _VideoFrameState();
}

class _VideoFrameState extends State<VideoFrame>  with RouteAware, SingleTickerProviderStateMixin  {

  TencentPlayerController get controller => widget.controller;
  VoidCallback listener;
  FadeAnimation imageFadeAnim;
  Widget controlAni ;
  Timer resetHideCountDownTimer;
  bool isShowControl = true;
  bool isTiming = true;

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
      print("isTiming = true;");
      if(aniCtrl != null){
        aniCtrl.forward();
      }
    }else {
      isTiming = true;
      print("isTiming = false;");
      aniCtrl.reverse();
      _startTime();
    }
  }
  _startTime(){
    _clearTime();
    resetHideCountDownTimer = Timer(Duration(seconds: 2),(){
      setState(() {
        isTiming = false;
        aniCtrl.forward();
        //isShowControl = false;
      });
    });
  }
  //隐藏控制面板
  void hideControlPanel(){
    _clearTime();
    setState(() {
      isShowControl = false;
    });
  }

  _clearTime(){
    if(resetHideCountDownTimer != null){
      resetHideCountDownTimer.cancel();
      resetHideCountDownTimer = null;
    }
  }

  @override
  void didPushNext() {
    print("TicketDtl Route: didPushNext");
    controller.removeListener(listener);
    super.didPushNext();
  }

  @override
  void didPop() {
    print("TicketDtl Route: didPop");
    super.didPop();
  }

  @override
  void didPopNext() {
    print("TicketDtl Route: didPopNext");
    controller.addListener(listener);
    super.didPopNext();
  }
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listener = () {
      setState(() {});
    };
    imageFadeAnim = FadeAnimation(child: playAllow);
    controller.addListener(listener);
    _startTime();
    initAnimation();
  }
  initAnimation(){
    aniCtrl = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    aniCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //AnimationStatus.completed 动画在结束时停止的状态
        //ontroller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        //AnimationStatus.dismissed 表示动画在开始时就停止的状态
        //controller.forward();
      }
    });
    downOffsetAnimation = Tween(begin: Offset(0, 0), end: Offset(0, 1)).animate(aniCtrl);
    rightOffsetAnimation = Tween(begin: Offset(0, 0), end: Offset(1, 0)).animate(aniCtrl);
    opacityAnimation =  Tween<double>(begin: 1, end: 0).animate(aniCtrl);
  }
  @override
  void deactivate() {
    // TODO: implement deactivate
    //controller.removeListener(listener);
    super.deactivate();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    routeObserver.unsubscribe(this);
    _clearTime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    String position = controller.value.position.toString();
    if (position.lastIndexOf(".") > -1) {
      position = position.substring(position.indexOf(":")+1, position.lastIndexOf("."));
    }

    String duration = controller.value.duration.toString();
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
              opacity: opacityAnimation.value,
              child: Container(
                padding: EdgeInsets.only(left: setWidth(20),right: setWidth(20)),
                //height: setWidth(40),
                width: setWidth(544),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: setWidth(16)),
                      child: InkWell(
                        onTap: (){
                          if (!controller.value.initialized) {
                            return;
                          }
                          if (controller.value.isPlaying) {
                            //imageFadeAnim = FadeAnimation(child: playAllow);
                            controller.pause();
                          } else {
                            //imageFadeAnim = FadeAnimation(child: pauseAllow);
                            controller.play();
                          }
                        },
                        child: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow,color: Colors.white, size: setWidth(32)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: setWidth(16)),
                      child: Text(
                        "${position}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: setSp(22),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ProgressWidget(controller),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: setWidth(16)),
                      child: Text(
                        "${duration}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: setSp(22),
                        ),
                      ),
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
              opacity: opacityAnimation.value,
              child: Column(
                children: <Widget>[
                  //音量按钮
                  InkWell(
                    onTap: (){
                      if (!controller.value.initialized) {
                        return;
                      }
                      if(controller.value.isMute){
                        controller.isMute(false);
                      }else {
                        controller.isMute(true);
                      }
                    },
                    child: Image.asset( controller.value.isMute ? "images/ic_mute.png" : "images/ic_noise.png", width: setWidth(76),height: setWidth(76)),
                  ),
                  //是否全屏
                  InkWell(
                    onTap: (){
                      //_showFullScreenWithRotateBox(context,controller);
                      showFullScreenWithRotateScreen(context,controller);
                    },
                    child: Image.asset("images/ic_full_screen.png",width: setWidth(76),height: setWidth(76),),
                  )
                ],
              ),
            ),
          ),
        ),

        Center(child: InkWell(
          onTap: (){
            if (!controller.value.initialized) {
              return;
            }
            if (controller.value.isPlaying) {
              //imageFadeAnim = FadeAnimation(child: playAllow);
              controller.pause();
            } else {
              //imageFadeAnim = FadeAnimation(child: pauseAllow);
              controller.play();
            }
            resetHideCountDown();
          },
          child: Opacity(
            opacity: opacityAnimation.value,
            child: controller.value.isPlaying ? pauseAllow :  playAllow,
          ),
        )),
      ],
    );

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        GestureDetector(
          child: TencentPlayer(controller),
          onTap: (){
            if (!controller.value.initialized) {
              return;
            }
            resetHideCountDown();
          },
        ),
        Offstage(
          offstage: !isShowControl,
          child: control,
        ),
        (controller.playerConfig.coverImgUrl != null && controller.value.playend ) ? Stack(
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
                child: InkWell(
                  onTap: (){
                    controller.play();
                  },
                  child: Image.asset("images/ic_play.png",width: setWidth(140),height: setWidth(140)),
                ) ,
              ),
            )

          ],
        ):Container(),

        Center(child: controller.value.isLoading ? const CircularProgressIndicator() : null),
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
    TencentPlayerController controller, {
      VideoWidgetBuilder fullscreenControllerWidgetBuilder,
    }) async {
  var info = controller.value.size;

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
              aspectRatio: controller.value.aspectRatio,
              child: TencentPlayer(controller),
            ),
          ),
        );
      },
    ),
  );
}

showFullScreenWithRotateScreen(
    BuildContext context,
    TencentPlayerController controller,
    {VideoWidgetBuilder fullscreenControllerWidgetBuilder}) async {
  //VideoFrame(controller)
  //TencentPlayer(controller)


  var info = await controller.value.size;

  Axis axis;

  if (info.width == 0 || info.height == 0) {
    axis = Axis.horizontal;
  } else if (info.width > info.height) {

    axis = Axis.horizontal;
  } else {

    axis = Axis.vertical;
  }
  //AutoOrientation.portraitUpMode();
  if (axis == Axis.horizontal) {
    AutoOrientation.landscapeAutoMode();
  } else {
    AutoOrientation.portraitUpMode();
  }
  SystemChrome.setEnabledSystemUIOverlays([]);
  Navigator.push(
    context,
    FullScreenRoute(
      builder: (c) {
        return FullControl(controller,axis);
      },
    ),
  ).then((_) {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    AutoOrientation.portraitUpMode();
  });
}

///全屏控制面板
class FullControl extends StatefulWidget {
  final TencentPlayerController controller;
  final Axis axis;
  FullControl(this.controller, this.axis);
  @override
  _FullControlState createState() => _FullControlState();
}

class _FullControlState extends State<FullControl> {

  TencentPlayerController get controller => widget.controller;
  Axis get axis => widget.axis;
  VoidCallback listener;
  FadeAnimation imageFadeAnim;
  Widget controlAni ;
  Timer resetHideCountDownTimer;
  bool isShowControl = true;

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

  _FullControlState(){
    listener = () {
      setState(() {});
    };
  }

  //重置隐藏控制面板的计时
  void resetHideCountDown(){
    _clearTime();
    setState(() {
      isShowControl = true;
    });
    resetHideCountDownTimer = Timer(Duration(seconds: 2),(){
      setState(() {
        isShowControl = false;
      });

    });
  }
  //隐藏控制面板
  void hideControlPanel(){
    _clearTime();
    setState(() {
      isShowControl = false;
    });
  }

  _clearTime(){
    if(resetHideCountDownTimer != null){
      resetHideCountDownTimer.cancel();
      resetHideCountDownTimer = null;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    resetHideCountDown();
    imageFadeAnim = FadeAnimation(child: playAllow);
    controller.addListener(listener);
    //controller.play();
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _clearTime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String position = controller.value.position.toString();
    if (position.lastIndexOf(".") > -1) {
      position = position.substring(position.indexOf(":")+1, position.lastIndexOf("."));
    }

    String duration = controller.value.duration.toString();
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
          child: Container(
            padding: EdgeInsets.only(left: _setWidthDelegate(33),right: _setWidthDelegate(33),bottom: _setWidthDelegate(28)),
            //height: setFullWidth(40),
            //width: setFullWidth(544),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[

                Padding(
                  padding: EdgeInsets.only(right: _setWidthDelegate(16)),
                  child: Text(
                    "${position}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _setSpDelegate(22),
                    ),
                  ),
                ),
                Expanded(
                  child: ProgressWidget(controller,screenHorizontal: true,),
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
                Padding(
                  padding: EdgeInsets.only(left: _setWidthDelegate(19)),
                  child: InkWell(
                    onTap: (){
                      Navigator.pop(context);
                    },
                    child: Image.asset("images/ic_small_screen.png",width: _setWidthDelegate(48),height: _setWidthDelegate(48)),
                  ),
                ),
              ],
            ),
          ),

        ),

        Center(child: InkWell(
          onTap: (){
            if (!controller.value.initialized) {
              return;
            }
            if (controller.value.isPlaying) {
              //imageFadeAnim = FadeAnimation(child: playAllow);
              controller.pause();
            } else {
              //imageFadeAnim = FadeAnimation(child: pauseAllow);
              controller.play();
            }
            setState(() {

            });
          },
          child: controller.value.isPlaying ? pauseAllow :  playAllow,
        )),
      ],
    );

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        GestureDetector(
          child: TencentPlayer(controller),
          onTap: (){
            if (!controller.value.initialized) {
              return;
            }
            resetHideCountDown();
          },
        ),
        Offstage(
          offstage: !isShowControl,
          child: control,
        ),

        Center(child: controller.value.isLoading ? const CircularProgressIndicator() : null),
      ],
    );
  }
}


///滑动条
class ProgressWidget extends StatefulWidget {
  final bool screenHorizontal;
  ProgressWidget(this.controller, {this.screenHorizontal = false});

  final TencentPlayerController controller;

  @override
  _ProgressWidgetState createState() =>
      _ProgressWidgetState(controller.value.position.inMilliseconds.toDouble());
}

class _ProgressWidgetState extends State<ProgressWidget>  with RouteAware {
  _ProgressWidgetState(this.position);
  TencentPlayerController get controller => widget.controller;

  double position;
  double buffer = 0;
  VoidCallback listener;

  @override
  void didPushNext() {
    print("TicketDtl Route: didPushNext");
    controller.removeListener(listener);
    super.didPushNext();
  }

  @override
  void didPop() {
    print("TicketDtl Route: didPop");
    super.didPop();
  }

  @override
  void didPopNext() {
    print("TicketDtl Route: didPopNext");
    controller.addListener(listener);
    super.didPopNext();
  }
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }
  @override
  void initState() {
    super.initState();
    listener = (){
      if (!mounted) return;
      setState(() {
        position = controller.value.position.inMilliseconds.toDouble();
        buffer = controller.value.playable.inMilliseconds.toDouble();
      });
    };
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    //widget.controller.removeListener(listener);
    super.deactivate();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return widget.controller.value.duration.inMilliseconds.toDouble() >= position
        ? ProgressSlider(
      borderRadius:  BorderRadius.circular(setWidth(10)),
      inactiveColor: Colors.white24,
      bufferColor: Colors.white38,
      activeColor: Colors.white,
      value: position/widget.controller.value.duration.inMilliseconds.toDouble(),
      bufferValue: buffer/widget.controller.value.duration.inMilliseconds.toDouble(),
      onChanged: (value){
        setState(() {
          position = value * widget.controller.value.duration.inMilliseconds;
          widget.controller.seekTo(Duration(milliseconds: position.toInt()));
        });
      },
    )
        : Container();

  }
}





