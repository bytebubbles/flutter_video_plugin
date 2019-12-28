import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter_tencentplayer/model/TxCache.dart';
//import 'package:xml2json/xml2json.dart';
import 'dart:convert';

typedef void NewStartPlayCallback();
class TencentPlayerController extends ValueNotifier<TencentPlayerValue> {
  int _textureId;
  final String dataSource;
  final DataSourceType dataSourceType;
  PlayerConfig _playerConfig = PlayerConfig();
  MethodChannel channel = TencentPlayer.channel;
  Map<dynamic, dynamic> dataSourceDescription;
  NewStartPlayCallback newStartPlayCallback;
  bool isNewStartPlay;
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
    //await getCacheState();
    dataSourceDescription.addAll(playerConfig.toJson());
    final Map<String, dynamic> response =
    await channel.invokeMapMethod<String, dynamic>(
      'create',
      dataSourceDescription,
    );
    _textureId = response['textureId'];
    print("textureID:${_textureId}");
    _creatingCompleter.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    Future eventListener(dynamic event) async {
      if (_isDisposed) {
        return;
      }
      final Map<dynamic, dynamic> map = event;
      switch (map['event'])  {
        case 'initialized':
          await _initialized(map);

          print("-----initialized:${value}");
          if(!initializingCompleter.isCompleted) initializingCompleter.complete(null);
          break;
        case 'prepared':
          print("-----myPlayer:prepared-${value}");
          value = value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0),
            reconnectCount: 0,
            prepared: true,
          );
          break;
        case 'progress':
          value = value.copyWith(
            position: Duration(milliseconds: map['progress']),
            duration: Duration(milliseconds: map['duration']),
            playable: Duration(milliseconds: map['playable']),
          );
          //print("-----myPlayer:progress-${value}");
          break;
        case 'loading':
          print("-----myPlayer:loading-${value}");
          value = value.copyWith(isLoading: true);
          break;
        case 'loadingend':
          print("-----myPlayer:loadingend-${value}");
          value = value.copyWith(isLoading: false);
          break;
        case 'playend':
          print("-----myPlayer:playend-${value}");
          value = value.copyWith(isPlaying: false, position: value.duration,playend: true);
          break;
        case 'netStatus':
          //print("-----myPlayer:netStatus-netSpeed:${map['netSpeed']}-cacheSize:${map['cacheSize']}");
          value = value.copyWith(netSpeed: map['netSpeed']);
          break;
        case 'error':
          print("-----myPlayer:error-${ map['errorInfo']}");
          value = value.copyWith(errorDescription: map['errorInfo']);
          break;
        case 'reconnect':
          print("-------myPlayer:reconnect--------");
          value = value.copyWith(reconnectCount: value.reconnectCount+1);
          break;
        case 'playBegin':
          print("-------myPlayer:playBegin--------");
          value = value.copyWith(reconnectCount: 0);
          break;
        case 'disconnect':
          print("-------myPlayer:disconnect--------");
          value = value.copyWith(isDisconnect: true);
          break;
        case 'snapshot':
          print("------snapshot:${map['snapshot']}");
          //coverFrame = map['snapshot'];
          break;
        case 'firstFrame':
          print("------snapshot:${map.length}");
          value = value.copyWith(firstFrame: map['snapshot']);
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
    if(value.playend) isNewStartPlay = true;
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
    print("-----_applyPlayPause");
    dataSourceDescription["textureId"] = _textureId;
    if (value.isPlaying) {
      print("-----isPlaying");
      //await channel.invokeMethod('play', <String, dynamic>{'textureId': _textureId, 'config':dataSourceDescription});

      if(isNewStartPlay == null || isNewStartPlay){
        getCacheState();
        //if(newStartPlayCallback != null) newStartPlayCallback();
      }

      await channel.invokeMethod('play', dataSourceDescription);
    } else {
      //await channel.invokeMethod('pause', <String, dynamic>{'textureId': _textureId,'config':dataSourceDescription});
      await channel.invokeMethod('pause',dataSourceDescription);
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

  Future<void> getCacheState()async{
    var videoCacheInfoAry =  await channel.invokeMethod('getCacheState', <String, dynamic>{
      'textureId': _textureId,
    });
    print("videoCacheInfoAry:${videoCacheInfoAry}");
    int totalCache = 0;
    int currCache = 0;
    if(videoCacheInfoAry != null && videoCacheInfoAry is List && videoCacheInfoAry.length >= 3){
      totalCache = int.parse(videoCacheInfoAry[1]);
      currCache = int.parse(videoCacheInfoAry[2]);
    }
    value = value.copyWith(videoFileSize: totalCache, cacheDiskSize: currCache);
    if(newStartPlayCallback != null) newStartPlayCallback();
    isNewStartPlay = false;
  }

  bool _judgeCacheState(var videoCacheInfoAry) {
      print("_judgeCacheState:${videoCacheInfoAry}");
      if(videoCacheInfoAry != null && videoCacheInfoAry is List && videoCacheInfoAry.length >= 3){
        int totalCache = int.parse(videoCacheInfoAry[1]);
        int currCache = int.parse(videoCacheInfoAry[2]);
        if(totalCache == currCache){
          //已经缓存完成
          print("已经缓存完成");
          return true;
        }else if(totalCache > currCache){
          print("未缓存完成：totalCache-${totalCache}, currCache-${currCache}");
          return false;
        }
      }
      return false;
  }

  _initialized(Map<dynamic, dynamic> map) async {
    var videoCacheInfoAry = map['cacheState'];
    int totalCache = 0;
    int currCache = 0;
    if(videoCacheInfoAry != null && videoCacheInfoAry is List && videoCacheInfoAry.length >= 3){
      totalCache = int.parse(videoCacheInfoAry[1]);
      currCache = int.parse(videoCacheInfoAry[2]);
    }
    if(totalCache == 0){
      totalCache = await _getVideoSizeFromNet();
    }
    value = value.copyWith(initialized: true, videoFileSize: totalCache, cacheDiskSize: currCache);
  }

  Future<int> _getVideoSizeFromNet() async {
    HttpClient httpClient;
    int videoFileSize = 0;
    try{
      httpClient = new HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(dataSource));
      HttpClientResponse response = await request.close();
      //输出响应头
      print(response.headers);
      print("消耗流量：${response.headers["content-length"][0]}");
      videoFileSize = int.parse(response.headers["content-length"][0] ?? 0);
      //value = value.copyWith(videoFileSize: int.parse(response.headers["content-length"][0] ?? 0));
    }catch(e){
      print(e);
    }finally{
      if(httpClient != null){
        httpClient.close();
      }
    }
    return Future.value(videoFileSize);
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