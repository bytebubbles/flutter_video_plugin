class PlayerConfig {
  final bool autoPlay;
  final bool loop;
  final Map<String, String> headers;
  final String cachePath;
  final int progressInterval;
  // 单位:秒
  final int startTime;
  final Map<String, dynamic> auth;
  final bool defaultMute;
  final bool autoLoading;
  //final int maxCacheItems;
  const PlayerConfig(
      {this.autoPlay = true,
        this.loop = false,
        this.headers,
        this.cachePath,
        this.progressInterval = 200,
        this.startTime,
        this.auth,
        this.defaultMute = false,
        this.autoLoading = false,
      });

  PlayerConfig copyWith({
    bool autoPlay,
    bool loop,
    Map<String, String> headers,
    String cachePath,
    int progressInterval,
    int startTime,
    Map<String, dynamic> auth,
    bool defaultMute,
    bool autoLoading,
  }){
    return PlayerConfig(
      autoPlay: autoPlay ?? this.autoPlay,
      loop: loop ?? this.loop,
      headers: headers ?? this.headers,
      cachePath: cachePath ?? this.cachePath,
      progressInterval: progressInterval ?? this.progressInterval,
      startTime: startTime ?? this.startTime,
      auth: auth ?? this.auth,
      defaultMute: defaultMute ?? this.defaultMute,
      autoLoading: autoLoading ?? this.autoLoading
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'autoPlay': this.autoPlay,
    'loop': this.loop,
    'headers': this.headers,
    'cachePath': this.cachePath,
    'progressInterval': this.progressInterval,
    'startTime': this.startTime,
    'auth': this.auth,
    'defaultMute': this.defaultMute,
    'autoLoading': this.autoLoading,
  };
}