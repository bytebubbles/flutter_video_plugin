
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'dimension.dart';

typedef Widget VideoWidgetBuilder(
    BuildContext context,   TencentPlayerController controller);

class VideoControl{

}

abstract class PlayerLifeCycle extends StatefulWidget {
  PlayerLifeCycle(this.childBuilder);
  final VideoWidgetBuilder childBuilder;
}

abstract class _PlayerLifeCycleState extends State<PlayerLifeCycle> {
  TencentPlayerController controller;
  Directory directory;
  @override
  void initState() {
    super.initState();
    _handlingController();

  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  _handlingController() async {
    controller = createVideoPlayerController();
    if(controller.playerConfig.switchCache){
      directory = await getTemporaryDirectory();
      print("-------directory.path:${directory.path}");
      PlayerConfig playerConfig = controller.playerConfig.copyWith(cachePath: directory.path);
      controller = TencentPlayerController.network(controller.dataSource, playerConfig: playerConfig);
    }
  }
  _initVideo(){

    controller?.initialize().then((_) {
      setState(() {});
    });
    controller.addListener(() {
      if (controller.value.hasError) {
        print(controller.value.errorDescription);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    Widget controlWidget;
    if(!controller.playerConfig.autoPlay && !controller.value.initialized){
      Widget coverImg;
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
                child: InkWell(
                  onTap: (){
                    PlayerConfig playerConfig = controller.playerConfig.copyWith(autoPlay: true);
                    controller = TencentPlayerController.network(controller.dataSource, playerConfig: playerConfig);

                    _initVideo();
                  },
                  child: Image.asset("images/ic_play.png",width: setWidth(140),height: setWidth(140)),
                ) ,
              ),
            )

          ],
        ),
      );
    }else {
      if(!controller.value.initialized){
        _initVideo();
      }
      controlWidget = widget.childBuilder(context, controller);
    }
    return controlWidget;
  }

  TencentPlayerController createVideoPlayerController();
}


class NetworkPlayerLifeCycle extends PlayerLifeCycle {
  final TencentPlayerController controller;
  NetworkPlayerLifeCycle({VideoWidgetBuilder childBuilder, this.controller})
      : super(childBuilder);

  @override
  _NetworkPlayerLifeCycleState createState() => _NetworkPlayerLifeCycleState(controller);
}

class _NetworkPlayerLifeCycleState extends _PlayerLifeCycleState {
  TencentPlayerController controller;
  _NetworkPlayerLifeCycleState(this.controller);
  @override
  TencentPlayerController createVideoPlayerController() {
    return controller;
    //return TencentPlayerController.network(widget.dataSource);
  }
}
