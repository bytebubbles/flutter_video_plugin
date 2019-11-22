import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';



class TencentPlayerController extends ValueNotifier<TencentPlayerValue> {
  int _textureId;
  final String dataSource;
  final DataSourceType dataSourceType;
  PlayerConfig _playerConfig = PlayerConfig();
  MethodChannel channel = TencentPlayer.channel;
  // ignore: unnecessary_getters_setters
  set playerConfig(PlayerConfig playerConfig) {
    assert ((){
      if(value.initialized) {
        throw FlutterError(
            "-------不可以在初始化后更改配置(PlayerConfig)-------"
        );
      }
      return true;
    }());
    _playerConfig = playerConfig;
  }
  // ignore: unnecessary_getters_setters
  PlayerConfig get playerConfig{
    return _playerConfig;
  }
  TencentPlayerController.asset(this.dataSource,
      {playerConfig = const PlayerConfig()})
      : dataSourceType = DataSourceType.asset,
        super(TencentPlayerValue()){
    _playerConfig = playerConfig;
  }

  TencentPlayerController.network(this.dataSource, {PlayerConfig playerConfig = const PlayerConfig()}) : dataSourceType = DataSourceType.network, super(TencentPlayerValue()){
    _playerConfig = playerConfig;
  }

  TencentPlayerController.file(String filePath,
      {playerConfig = const PlayerConfig()})
      : dataSource = filePath,
        dataSourceType = DataSourceType.file,
        super(TencentPlayerValue()){
    _playerConfig = playerConfig;
  }

  bool _isDisposed = false;
  get isDisposed {
    return _isDisposed;
  }
  Completer<void> _creatingCompleter;
  StreamSubscription<dynamic> _eventSubscription;
  _VideoAppLifeCycleObserver _lifeCycleObserver;

  @visibleForTesting
  int get textureId => _textureId;

  Future<void> initialize() async {
    _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    _lifeCycleObserver.initialize();
    _creatingCompleter = Completer<void>();
    Map<dynamic, dynamic> dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = <String, dynamic>{'asset': dataSource};
        break;
      case DataSourceType.network:
      case DataSourceType.file:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
        break;
    }
    value = value.copyWith(isPlaying: playerConfig.autoPlay,playend: false, isMute: playerConfig.defaultMute);
    dataSourceDescription.addAll(playerConfig.toJson());
    final Map<String, dynamic> response =
    await channel.invokeMapMethod<String, dynamic>(
      'create',
      dataSourceDescription,
    );
    _textureId = response['textureId'];
    _creatingCompleter.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(dynamic event) {
      if (_isDisposed) {
        return;
      }
      final Map<dynamic, dynamic> map = event;
      switch (map['event']) {
        case 'initialized':
          value = value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0),
          );
          if(!initializingCompleter.isCompleted) initializingCompleter.complete(null);
          break;
        case 'progress':
          value = value.copyWith(
            position: Duration(milliseconds: map['progress']),
            duration: Duration(milliseconds: map['duration']),
            playable: Duration(milliseconds: map['playable']),
          );
          break;
        case 'loading':
          value = value.copyWith(isLoading: true);
          break;
        case 'loadingend':
          value = value.copyWith(isLoading: false);
          break;
        case 'playend':
          value = value.copyWith(isPlaying: false, position: value.duration,playend: true);
          break;
        case 'netStatus':
          value = value.copyWith(netSpeed: map['netSpeed']);
          break;
        case 'error':
          value = value.copyWith(errorDescription: map['errorInfo']);
          break;
        case 'reconnect':
          print("-------reconnect--------");
          value = value.copyWith(isReconnect: true);
          break;
        case 'playBegin':
          print("-------playBegin--------");
          value = value.copyWith(isReconnect: false);
          break;
        case 'disconnect':
          print("-------disconnect--------");
          value = value.copyWith(isReconnect: false, isDisconnect: true);
          break;

      }
    }

    _eventSubscription = _eventChannelFor(_textureId)
        .receiveBroadcastStream()
        .listen(eventListener);
    return initializingCompleter.future;
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter_tencentplayer/videoEvents$textureId');
  }

  @override
  Future dispose() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      if (!_isDisposed) {
        _isDisposed = true;
        await _eventSubscription?.cancel();
        await channel.invokeListMethod(
            'dispose', <String, dynamic>{'textureId': _textureId});
        _lifeCycleObserver.dispose();
      }
    }
    _isDisposed = true;
    super.dispose();
  }

  Future<void> play() async {
    value = value.copyWith(isPlaying: true,playend: false);
    await _applyPlayPause();
  }

  Future<void> pause() async {
    value = value.copyWith(isPlaying: false,playend: false);
    await _applyPlayPause();
  }

  Future<void> isMute(bool isMute) async {
    value = value.copyWith(isMute: isMute);
    await _applyIsMute(isMute);
  }

  Future<void> _applyPlayPause() async {
    if (!value.initialized || _isDisposed) {
      return;
    }
    if (value.isPlaying) {
      await channel
          .invokeMethod('play', <String, dynamic>{'textureId': _textureId});
    } else {
      await channel
          .invokeMethod('pause', <String, dynamic>{'textureId': _textureId});
    }
  }

  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment == null) {
      return;
    }
    if (moment > value.duration) {
      moment = value.duration;
    } else if (moment < const Duration()) {
      moment = const Duration();
    }
    await channel.invokeMethod('seekTo', <String, dynamic>{
      'textureId': _textureId,
      'location': moment.inSeconds,
    });
    value = value.copyWith(position: moment);
  }

  //点播为m3u8子流，会自动无缝seek
  Future<void> setBitrateIndex(int index) async {
    if (_isDisposed) {
      return;
    }
    await channel.invokeMethod('setBitrateIndex', <String, dynamic>{
      'textureId': _textureId,
      'index': index,
    });
    print('hahaha');
    value = value.copyWith(bitrateIndex: index);
  }

  Future<void> setRate(double rate) async {
    if (_isDisposed) {
      return;
    }
    if (rate > 2.0) {
      rate = 2.0;
    } else if (rate < 1.0) {
      rate = 1.0;
    }
    await channel.invokeMethod('setRate', <String, dynamic>{
      'textureId': _textureId,
      'rate': rate,
    });
    value = value.copyWith(rate: rate);
  }

  Future<void> _applyIsMute(bool isMute) async {
    if(_isDisposed){
      return ;
    }
    await channel.invokeMethod("mute", <String,dynamic>{
      'textureId': _textureId,
      "isMute":isMute
    });
  }

}

class _VideoAppLifeCycleObserver with WidgetsBindingObserver {
  bool _wasPlayingBeforePause = false;
  final TencentPlayerController _controller;

  _VideoAppLifeCycleObserver(this._controller);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.play();
        }
        break;
      default:
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}