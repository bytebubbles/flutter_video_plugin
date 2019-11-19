class PlayerConfig {
  final bool autoPlay;
  final bool loop;
  final Map<String, String> headers;
  final String cachePath;
  final int progressInterval;
  // 单位:秒
  final int startTime;
  final Map<String, dynamic> auth;
  final bool switchCache;
  final String coverImgUrl;
  final bool defaultMute;

  const PlayerConfig(
      {this.autoPlay = true,
        this.loop = false,
        this.headers,
        this.cachePath,
        //this.cachePath = "/var/mobile/Containers/Data/Application/1A610B42-5E2A-4371-A2EE-3FF79B2525ED/Library/Caches",
        //this.cachePath = "/var/mobile/Containers/Data/Application/5B994A15-98F7-4318-8379-31C7CBA78BFA/Documents",
        this.progressInterval = 200,
        this.startTime,
        this.auth,
        this.switchCache = false,
        this.coverImgUrl,
        this.defaultMute = false,
      });

  PlayerConfig copyWith({
    bool autoPlay,
    bool loop,
    Map<String, String> headers,
    String cachePath,
    int progressInterval,
    int startTime,
    Map<String, dynamic> auth,
    bool switchCache,
    String coverImgUrl,
    bool defaultMute
  }){
    return PlayerConfig(
      autoPlay: autoPlay ?? this.autoPlay,
      loop: loop ?? this.loop,
      headers: headers ?? this.headers,
      cachePath: cachePath ?? this.cachePath,
      progressInterval: progressInterval ?? this.progressInterval,
      startTime: startTime ?? this.startTime,
      auth: auth ?? this.auth,
      switchCache: switchCache ?? this.switchCache,
      coverImgUrl: coverImgUrl ?? this.coverImgUrl,
      defaultMute: defaultMute ?? this.defaultMute
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
    'switchCache': this.switchCache,
    'defaultMute': this.defaultMute,

  };
}