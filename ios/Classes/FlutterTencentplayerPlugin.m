#import "FlutterTencentplayerPlugin.h"

#import "FLTVideoPlayer.h"
#import "FLTFrameUpdater.h"
#import "FLTDownLoadManager.h"

@interface FlutterTencentplayerPlugin ()

@property(readonly, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
//@property(readonly, nonatomic) NSMutableDictionary* players;
@property(readonly, nonatomic) NSMutableDictionary* downLoads;
@property(readonly, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;




@end



@implementation FlutterTencentplayerPlugin

NSObject<FlutterPluginRegistrar>* mRegistrar;
//FLTVideoPlayer* player ;
NSMutableDictionary *playerMap;

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
    _messenger = [registrar messenger];
    _registrar = registrar;
   // _players = [NSMutableDictionary dictionaryWithCapacity:1];
    _downLoads = [NSMutableDictionary dictionaryWithCapacity:1];
     NSLog(@"FLTVideo  initWithRegistrar");
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_tencentplayer"
                                     binaryMessenger:[registrar messenger]];
//    FlutterTencentplayerPlugin* instance = [[FlutterTencentplayerPlugin alloc] init];
   FlutterTencentplayerPlugin* instance = [[FlutterTencentplayerPlugin alloc] initWithRegistrar:registrar];
    
    [registrar addMethodCallDelegate:instance channel:channel];

   
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
     //NSLog(@"FLTVideo  call name   %@",call.method);
    if ([@"init" isEqualToString:call.method]) {
        NSLog(@"handleMethodCall_init");
        [self disposeAllPlayers];
        result(nil);
    }else if([@"create" isEqualToString:call.method]){
        NSLog(@"FLTVideo  create");
        //[self disposeAllPlayers];
        FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry:_registry];
//        FLTVideoPlayer*
        FLTVideoPlayer* player= [[FLTVideoPlayer alloc] initWithCall:call frameUpdater:frameUpdater registry:_registry messenger:_messenger];
        if (player) {
            [self onPlayerSetup:player frameUpdater:frameUpdater result:result];
        }
        result(nil);
    }else if([@"download" isEqualToString:call.method]){
        
         NSDictionary* argsMap = call.arguments;
         NSString* urlOrFileId = argsMap[@"urlOrFileId"];
        NSLog(@"下载相关   startdownload  %@", urlOrFileId);
        
        NSString* channelUrl =[NSString stringWithFormat:@"flutter_tencentplayer/downloadEvents%@",urlOrFileId];
        NSLog(@"%@", channelUrl);
        FlutterEventChannel* eventChannel = [FlutterEventChannel
                                             eventChannelWithName:channelUrl
                                             binaryMessenger:_messenger];
       FLTDownLoadManager* downLoadManager = [[FLTDownLoadManager alloc] initWithMethodCall:call result:result];
       [eventChannel setStreamHandler:downLoadManager];
       downLoadManager.eventChannel =eventChannel;
       [downLoadManager downLoad];
       
       _downLoads[urlOrFileId] = downLoadManager;
       NSLog(@"下载相关   start 数组大小  %lu", (unsigned long)_downLoads.count);
        
        
        result(nil);
    }else if([@"stopDownload" isEqualToString:call.method]){
        NSDictionary* argsMap = call.arguments;
        NSString* urlOrFileId = argsMap[@"urlOrFileId"];
        NSLog(@"下载相关    stopDownload  %@", urlOrFileId);
        FLTDownLoadManager* downLoadManager =   _downLoads[urlOrFileId];
        if(downLoadManager!=nil){
           [downLoadManager stopDownLoad];
        }else{
            NSLog(@"下载相关   对象为空  %lu", (unsigned long)_downLoads.count);
        }
        
        
       
        result(nil);
    }else {
        [self onMethodCall:call result:result];
    }
}

-(void) onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    
    NSDictionary* argsMap = call.arguments;
   // int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
    if([NSNull null]==argsMap[@"textureId"]) {
        return;
    }
    int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
//    FLTVideoPlayer* player = _players[@(textureId)];
    FLTVideoPlayer* player = [playerMap objectForKey:@(textureId)];
    //NSLog(@"count:%d",playerMap.count);
    //NSLog(@"object:%@",player);
    if([@"play" isEqualToString:call.method]){
        [player resume:argsMap];
        result(nil);
    }else if([@"pause" isEqualToString:call.method]){
        [player pause];
        result(nil);
    }else if([@"seekTo" isEqualToString:call.method]){
        //NSLog(@"跳转到指定位置----------");
        [player seekTo:[[argsMap objectForKey:@"location"] intValue]];
        result(nil);
    }else if([@"setRate" isEqualToString:call.method]){ //播放速率
        //NSLog(@"修改播放速率----------");
        float rate = [[argsMap objectForKey:@"rate"] floatValue];
        if (rate<0||rate>2) {
            result(nil);
            return;
        }
        [player setRate:rate];
        result(nil);
        
    }else if([@"setBitrateIndex" isEqualToString:call.method]){
        //NSLog(@"修改播放清晰度----------");
        int  index = [[argsMap objectForKey:@"index"] intValue];
        [player setBitrateIndex:index];
        result(nil);
    }else if([@"dispose" isEqualToString:call.method]){
         //NSLog(@"FLTVideo  dispose   ----   ");
        [_registry unregisterTexture:textureId];
       // [_players removeObjectForKey:@(textureId)];
        //_players= nil;
        [self disposePlayer:textureId];
        //[self disposeAllPlayers];
        result(nil);
    }else if([@"mute" isEqualToString:call.method]){
        NSLog(@"FLTVideo mute -- ");
        Boolean isMute = [[argsMap objectForKey:@"isMute"] boolValue];
        [player setMute:isMute];
        result(nil);
    }else if([@"getCacheState" isEqualToString:call.method]){
        dispatch_queue_t queue = dispatch_queue_create("getCacheState", NULL);
        dispatch_async(queue, ^(){
            NSArray *videoCacheInfoAry = [FLTVideoPlayer getVideoCacheInfo:player.configMap];
            dispatch_async(dispatch_get_main_queue(), ^{
                result(videoCacheInfoAry);
            });
        });
    }
    else{
        result(FlutterMethodNotImplemented);
    }
    
}

- (void)onPlayerSetup:(FLTVideoPlayer*)player
         frameUpdater:(FLTFrameUpdater*)frameUpdater
               result:(FlutterResult)result {
//    _players[@(player.textureId)] = player;
    if(!playerMap) playerMap =  [NSMutableDictionary dictionary];
    [playerMap setObject: player forKey:@(player.textureId)];
    result(@{@"textureId" : @(player.textureId)});
    
}

-(void) disposePlayer: (int64_t)textureId{
    //NSLog(@"FLTVideo 销毁单个播放器----------textureId:%lld",textureId);
    if(playerMap){
        FLTVideoPlayer* player = [playerMap objectForKey:@(textureId)];
        if(player){
            [player dispose];
            player = nil;
            [playerMap removeObjectForKey:@(textureId)];
        }
    }
}

-(void) disposeAllPlayers{
    // NSLog(@"FLTVideo 销毁所有播放器----------");
    // Allow audio playback when the Ring/Silent switch is set to silent
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    if(playerMap){
        for(id key in playerMap){
            NSLog(@"key :%@  value :%@", key, [playerMap objectForKey:key]);
            [self disposePlayer:(int64_t)key];
        }
    }
    
    
}
@end
