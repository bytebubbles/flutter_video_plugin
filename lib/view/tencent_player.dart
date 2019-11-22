
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';


class TencentPlayer extends StatefulWidget {
  static MethodChannel channel = const MethodChannel('flutter_tencentplayer')
    ..invokeMethod<void>('init');

  final TencentPlayerController controller;

  TencentPlayer(this.controller);

  @override
  _TencentPlayerState createState() => new _TencentPlayerState();
}

class _TencentPlayerState extends State<TencentPlayer> {
  VoidCallback _listener;
  int _textureId;

  _TencentPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(TencentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.controller.isDisposed) return;
    if (oldWidget.controller.dataSource != widget.controller.dataSource) {
//      oldWidget.controller.dispose();
    }
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    //return _textureId == null ? Container() : Texture(textureId: _textureId);
    return _textureId == null ? Container() : DefaultVideoWrapper(controller: widget.controller,textureId: _textureId);
  }
}

//视频包裹
class DefaultVideoWrapper extends StatelessWidget {
  final TencentPlayerController controller;
  final int textureId;
  const DefaultVideoWrapper({
    Key key,
    this.controller, this.textureId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double ratio = controller.value?.aspectRatio ?? 1280 / 720;

    var id = textureId;

    if (id == null) {
      return AspectRatio(
        aspectRatio: ratio,
        child: Container(
          color: Colors.black,
        ),
      );
    }

    Widget w = Container(
      color: Colors.black,
      child: Texture(
        textureId: id,
      ),
    );


    if (ratio == 0) {
      ratio = 1280 / 720;
    }

    w = AspectRatio(
      aspectRatio: ratio,
      child: w,
    );


    return Container(
      child: w,
      alignment: Alignment.center,
      color: Colors.black,
    );
  }
}