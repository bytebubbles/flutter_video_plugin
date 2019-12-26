package com.jinxian.flutter_tencentplayer;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Base64;
import android.util.LongSparseArray;
import android.util.Xml;
import android.view.Surface;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.TextureRegistry;


import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXPlayerAuthBuilder;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.rtmp.downloader.ITXVodDownloadListener;
import com.tencent.rtmp.downloader.TXVodDownloadDataSource;
import com.tencent.rtmp.downloader.TXVodDownloadManager;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;

import org.xmlpull.v1.XmlPullParser;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


/**
 * FlutterTencentplayerPlugin
 */
public class FlutterTencentplayerPlugin implements MethodCallHandler {

    ///////////////////// TencentPlayer 开始////////////////////
    private static class TencentPlayer implements ITXVodPlayListener {
        private TXVodPlayer mVodPlayer;

        TXVodPlayConfig mPlayConfig;
        private Surface surface;
        TXPlayerAuthBuilder authBuilder;

        private final TextureRegistry.SurfaceTextureEntry textureEntry;

        private TencentQueuingEventSink eventSink = new TencentQueuingEventSink();

        private final EventChannel eventChannel;

        private final Registrar mRegistrar;

        private boolean isSetPlaySource;

        TencentPlayer(
                Registrar mRegistrar,
                EventChannel eventChannel,
                TextureRegistry.SurfaceTextureEntry textureEntry,
                MethodCall call,
                Result result) {
            this.eventChannel = eventChannel;
            this.textureEntry = textureEntry;
            this.mRegistrar = mRegistrar;

            mVodPlayer = new TXVodPlayer(mRegistrar.context());

            setPlayConfig(call);

            setTencentPlayer(call);

            setFlutterBridge(eventChannel, textureEntry, result);

            setInitPlayState(call);

            //setPlaySource(call);
        }


        private void setPlayConfig(MethodCall call) {
            mPlayConfig = new TXVodPlayConfig();
            if (call.argument("cachePath") != null) {
                mPlayConfig.setCacheFolderPath(call.argument("cachePath").toString());//        mPlayConfig.setCacheFolderPath(Environment.getExternalStorageDirectory().getPath() + "/nellcache");
                mPlayConfig.setMaxCacheItems(4);
            } else {
                mPlayConfig.setCacheFolderPath(null);
            }
            if (call.argument("headers") != null) {
                mPlayConfig.setHeaders((Map<String, String>) call.argument("headers"));
            }

            mPlayConfig.setProgressInterval(((Number) call.argument("progressInterval")).intValue());
            mVodPlayer.setConfig(this.mPlayConfig);
        }

        private  void setTencentPlayer(MethodCall call) {
            mVodPlayer.setVodListener(this);
//            mVodPlayer.enableHardwareDecode(true);
            mVodPlayer.setLoop((boolean) call.argument("loop"));
            if (call.argument("startTime") != null) {
                mVodPlayer.setStartTime(((Number)call.argument("startTime")).floatValue());
            }
            mVodPlayer.setAutoPlay((boolean) call.argument("autoPlay"));
            mVodPlayer.setMute((boolean) call.argument("defaultMute"));
        }

        private void setFlutterBridge(EventChannel eventChannel, TextureRegistry.SurfaceTextureEntry textureEntry, Result result) {
            // 注册android向flutter发事件
            eventChannel.setStreamHandler(
                    new EventChannel.StreamHandler() {
                        @Override
                        public void onListen(Object o, EventChannel.EventSink sink) {
                            eventSink.setDelegate(sink);
                        }

                        @Override
                        public void onCancel(Object o) {
                            eventSink.setDelegate(null);
                        }
                    }
            );

            surface = new Surface(textureEntry.surfaceTexture());
            mVodPlayer.setSurface(surface);


            Map<String, Object> reply = new HashMap<>();
            reply.put("textureId", textureEntry.id());
            result.success(reply);
        }

        private void setInitPlayState(final MethodCall call){
            boolean autoPlay = (boolean) call.argument("autoPlay");
            boolean autoLoading = (boolean) call.argument("autoLoading");
            if(autoPlay){
                setPlaySource(call);
            }else {
                if(autoLoading){
                    setPlaySource(call);
                }else {
                    isSetPlaySource = false;
                }
            }
            final Map<String, Object> preparedMap = new HashMap<>();
            preparedMap.put("event", "initialized");
            /*Bitmap bitmap = getNetVideoBitmap(call.argument("uri").toString());
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            byte[] byteArray = stream.toByteArray();
            bitmap.recycle();
            preparedMap.put("snapshot", byteArray);*/

            final Handler handler = new Handler(){
                @Override
                public void handleMessage(Message msg) {
                    final Map<String, Object> preparedMap;

                    switch (msg.what){
                        case 0:
                            preparedMap  = new HashMap<>();
                            preparedMap.put("event", "initialized");
                            ArrayList<String> videoCacheInfoAry = msg.getData().getStringArrayList("videoCacheInfoAry");
                            preparedMap.put("cacheState", videoCacheInfoAry);
                            eventSink.success(preparedMap);
                            break;
                        case 1:
                            preparedMap  = new HashMap<>();
                            preparedMap.put("event", "firstFrame");
                            preparedMap.put("snapshot", msg.getData().getByteArray("byteArray"));
                            eventSink.success(preparedMap);
                            break;
                    }
                    //final Map<String, Object> preparedMap = new HashMap<>();
                }
            };

            new Thread(){
                @Override
                public void run() {

                    Message msg = new Message();
                    Bundle bundle = new Bundle();
                    ArrayList<String> videoCacheInfoAry = getVideoCacheInfo(call);
                    bundle.putStringArrayList("videoCacheInfoAry",videoCacheInfoAry);
                    msg.what = 0;
                    handler.sendMessage(msg);

                    Message msg2 = new Message();
                    Bundle bundle2 = new Bundle();
                    Bitmap bitmap = getNetVideoBitmap(call.argument("uri").toString(),videoCacheInfoAry);
                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    if(bitmap == null){
                        bundle2.putByteArray("byteArray",null);
                        msg2.setData(bundle2);
                        msg2.what = 1;
                        handler.sendMessage(msg2);
                        try {
                            stream.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                        return ;
                    }
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                    byte[] byteArray = stream.toByteArray();
                    bitmap.recycle();

                    bundle2.putByteArray("byteArray",byteArray);
                    msg2.setData(bundle2);
                    msg2.what = 1;
                    handler.sendMessage(msg2);
                    try {
                        stream.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }.start();
            /*ArrayList<String> videoCacheInfoAry = getVideoCacheInfo(call);
            preparedMap.put("cacheState", videoCacheInfoAry);
            eventSink.success(preparedMap);*/
        }

        private void setPlaySource(MethodCall call) {
            // network FileId播放
            if (call.argument("auth") != null) {
                authBuilder = new TXPlayerAuthBuilder();
                Map authMap = (Map<String, Object>)call.argument("auth");
                authBuilder.setAppId(((Number)authMap.get("appId")).intValue());
                authBuilder.setFileId(authMap.get("fileId").toString());
                mVodPlayer.startPlay(authBuilder);
            } else {
                // asset播放
                if (call.argument("asset") != null) {
                    String assetLookupKey = mRegistrar.lookupKeyForAsset(call.argument("asset").toString());
                    AssetManager assetManager = mRegistrar.context().getAssets();
                    try {
                        InputStream inputStream = assetManager.open(assetLookupKey);
                        String cacheDir = mRegistrar.context().getCacheDir().getAbsoluteFile().getPath();
                        String fileName = Base64.encodeToString(assetLookupKey.getBytes(), Base64.DEFAULT);
                        File file = new File(cacheDir, fileName + ".mp4");
                        FileOutputStream fileOutputStream = new FileOutputStream(file);
                        if(!file.exists()){
                            file.createNewFile();
                        }
                        int ch = 0;
                        while((ch=inputStream.read()) != -1) {
                            fileOutputStream.write(ch);
                        }
                        inputStream.close();
                        fileOutputStream.close();

                        mVodPlayer.startPlay(file.getPath());
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                } else {
                    // file、 network播放
                    mVodPlayer.startPlay(call.argument("uri").toString());
                }
            }
            isSetPlaySource = true;
        }

        // 播放器监听1
        @Override
        public void onPlayEvent(TXVodPlayer player, int event, Bundle param) {
            switch (event) {
                //准备阶段
                case TXLiveConstants.PLAY_EVT_VOD_PLAY_PREPARED:
                    Map<String, Object> preparedMap = new HashMap<>();
                    preparedMap.put("event", "prepared");
                    preparedMap.put("duration", (int) player.getDuration());
                    preparedMap.put("width", player.getWidth());
                    preparedMap.put("height", player.getHeight());
                    eventSink.success(preparedMap);
                    break;
                case TXLiveConstants.PLAY_EVT_PLAY_PROGRESS:
                    Map<String, Object> progressMap = new HashMap<>();
                    progressMap.put("event", "progress");
                    progressMap.put("progress", param.getInt(TXLiveConstants.EVT_PLAY_PROGRESS_MS));
                    progressMap.put("duration", param.getInt(TXLiveConstants.EVT_PLAY_DURATION_MS));
                    progressMap.put("playable", param.getInt(TXLiveConstants.EVT_PLAYABLE_DURATION_MS));
                    eventSink.success(progressMap);
                    break;
                case TXLiveConstants.PLAY_EVT_PLAY_LOADING:
                    Map<String, Object> loadingMap = new HashMap<>();
                    loadingMap.put("event", "loading");
                    eventSink.success(loadingMap);
                    break;
                case TXLiveConstants.PLAY_EVT_VOD_LOADING_END:
                    Map<String, Object> loadingendMap = new HashMap<>();
                    loadingendMap.put("event", "loadingend");
                    eventSink.success(loadingendMap);
                    break;
                case TXLiveConstants.PLAY_EVT_PLAY_END:
                    Map<String, Object> playendMap = new HashMap<>();
                    playendMap.put("event", "playend");
                    eventSink.success(playendMap);
                    break;
                case TXLiveConstants.PLAY_ERR_NET_DISCONNECT:
                    Map<String, Object> disconnectMap = new HashMap<>();
                    disconnectMap.put("event", "disconnect");
                    if (mVodPlayer != null) {
                        mVodPlayer.setVodListener(null);
                        mVodPlayer.stopPlay(true);
                    }
                    eventSink.success(disconnectMap);
                    break;
                case TXLiveConstants.PLAY_WARNING_RECONNECT:
                    Map<String, Object> reconnectMap = new HashMap<>();
                    reconnectMap.put("event", "reconnect");
                    eventSink.success(reconnectMap);
                    break;
                 case TXLiveConstants.PLAY_EVT_PLAY_BEGIN:
                    Map<String, Object> playBeginMap = new HashMap<>();
                     playBeginMap.put("event", "playBegin");
                    eventSink.success(playBeginMap);
                    break;

            }
            if (event < 0) {
                Map<String, Object> errorMap = new HashMap<>();
                errorMap.put("event", "error");
                errorMap.put("errorInfo", param.getString(TXLiveConstants.EVT_DESCRIPTION));
                errorMap.put("errorCode", event);
                eventSink.success(errorMap);
            }
        }

        // 播放器监听2
        @Override
        public void onNetStatus(TXVodPlayer txVodPlayer, Bundle param) {
            Map<String, Object> netStatusMap = new HashMap<>();
            netStatusMap.put("event", "netStatus");
            netStatusMap.put("netSpeed", param.getInt(TXLiveConstants.NET_STATUS_NET_SPEED));
            netStatusMap.put("cacheSize", param.getInt(TXLiveConstants.NET_STATUS_V_SUM_CACHE_SIZE));
            eventSink.success(netStatusMap);
        }

        void play(MethodCall call) {
            if (isSetPlaySource){
                if (!mVodPlayer.isPlaying()) {
                    mVodPlayer.resume();
                }
                return ;
            }
            mVodPlayer.setAutoPlay(true);
            setPlaySource(call);

        }

        void pause() {
            mVodPlayer.pause();
        }

        void seekTo(int location) {
            mVodPlayer.seek(location);
        }

        void setRate(float rate) {
            mVodPlayer.setRate(rate);
        }

        void setBitrateIndex(int index) {
            mVodPlayer.setBitrateIndex(index);
        }

        void setMute(boolean isMute){
            mVodPlayer.setMute(isMute);
        }

        void dispose() {
            if (mVodPlayer != null) {
                mVodPlayer.setVodListener(null);
                mVodPlayer.stopPlay(true);
            }
            textureEntry.release();
            eventChannel.setStreamHandler(null);
            if (surface != null) {
                surface.release();
            }
        }
    }
    ///////////////////// TencentPlayer 结束////////////////////

    ////////////////////  TencentDownload 开始/////////////////
    class TencentDownload implements ITXVodDownloadListener {
        private TencentQueuingEventSink eventSink = new TencentQueuingEventSink();

        private final EventChannel eventChannel;

        private final Registrar mRegistrar;

        private String fileId;

        private TXVodDownloadManager downloader;

        private TXVodDownloadMediaInfo txVodDownloadMediaInfo;


        void stopDownload() {
            if (downloader != null && txVodDownloadMediaInfo != null) {
                downloader.stopDownload(txVodDownloadMediaInfo);
            }
        }


        TencentDownload(
                Registrar mRegistrar,
                EventChannel eventChannel,
                MethodCall call,
                Result result) {
            this.eventChannel = eventChannel;
            this.mRegistrar = mRegistrar;


            downloader = TXVodDownloadManager.getInstance();
            downloader.setListener(this);
            downloader.setDownloadPath(call.argument("savePath").toString());
            String urlOrFileId = call.argument("urlOrFileId").toString();

            if (urlOrFileId.startsWith("http")) {
                txVodDownloadMediaInfo = downloader.startDownloadUrl(urlOrFileId);
            } else {
                TXPlayerAuthBuilder auth = new TXPlayerAuthBuilder();
                auth.setAppId(((Number)call.argument("appId")).intValue());
                auth.setFileId(urlOrFileId);
                int quanlity = ((Number)call.argument("quanlity")).intValue();
                String templateName = "HLS-标清-SD";
                if (quanlity == 2) {
                    templateName = "HLS-标清-SD";
                } else if (quanlity == 3) {
                    templateName = "HLS-高清-HD";
                } else if (quanlity == 4) {
                    templateName = "HLS-全高清-FHD";
                }
                TXVodDownloadDataSource source = new TXVodDownloadDataSource(auth, templateName);
                txVodDownloadMediaInfo = downloader.startDownload(source);
            }

            eventChannel.setStreamHandler(
                    new EventChannel.StreamHandler() {
                        @Override
                        public void onListen(Object o, EventChannel.EventSink sink) {
                            eventSink.setDelegate(sink);
                        }

                        @Override
                        public void onCancel(Object o) {
                            eventSink.setDelegate(null);
                        }
                    }
            );
            result.success(null);
        }

        @Override
        public void onDownloadStart(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("start", txVodDownloadMediaInfo);

        }

        @Override
        public void onDownloadProgress(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("progress", txVodDownloadMediaInfo);

        }

        @Override
        public void onDownloadStop(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("stop", txVodDownloadMediaInfo);
        }

        @Override
        public void onDownloadFinish(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            dealCallToFlutterData("complete", txVodDownloadMediaInfo);
        }

        @Override
        public void onDownloadError(TXVodDownloadMediaInfo txVodDownloadMediaInfo, int i, String s) {
            HashMap<String, Object> targetMap = Util.convertToMap(txVodDownloadMediaInfo);
            targetMap.put("downloadStatus", "error");
            targetMap.put("error", "code:" + i + "  msg:" +  s);
            if (txVodDownloadMediaInfo.getDataSource() != null) {
                targetMap.put("quanlity", txVodDownloadMediaInfo.getDataSource().getQuality());
                targetMap.putAll(Util.convertToMap(txVodDownloadMediaInfo.getDataSource().getAuthBuilder()));
            }
            eventSink.success(targetMap);
        }

        @Override
        public int hlsKeyVerify(TXVodDownloadMediaInfo txVodDownloadMediaInfo, String s, byte[] bytes) {
            return 0;
        }

        private void dealCallToFlutterData(String type, TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
            HashMap<String, Object> targetMap = Util.convertToMap(txVodDownloadMediaInfo);
            targetMap.put("downloadStatus", type);
            if (txVodDownloadMediaInfo.getDataSource() != null) {
                targetMap.put("quanlity", txVodDownloadMediaInfo.getDataSource().getQuality());
                targetMap.putAll(Util.convertToMap(txVodDownloadMediaInfo.getDataSource().getAuthBuilder()));
            }
            eventSink.success(targetMap);
        }


    }
    ////////////////////  TencentDownload 结束/////////////////


    private final Registrar registrar;
    private final LongSparseArray<TencentPlayer> videoPlayers;
    private final LongSparseArray<MethodCall> methodCalls;
    private final HashMap<String, TencentDownload> downloadManagerMap;

    private FlutterTencentplayerPlugin(Registrar registrar) {
        this.registrar = registrar;
        this.videoPlayers = new LongSparseArray<>();
        this.methodCalls = new LongSparseArray<>();
        this.downloadManagerMap = new HashMap<>();
    }


    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_tencentplayer");
        final FlutterTencentplayerPlugin plugin = new FlutterTencentplayerPlugin(registrar);

        channel.setMethodCallHandler(plugin);

        registrar.addViewDestroyListener(
                new PluginRegistry.ViewDestroyListener() {
                    @Override
                    public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
                        plugin.onDestroy();
                        return false;
                    }
                }
        );
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        TextureRegistry textures = registrar.textures();
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        }

        switch (call.method) {
            case "init":
                disposeAllPlayers();
                break;
            case "create":
                TextureRegistry.SurfaceTextureEntry handle = textures.createSurfaceTexture();

                EventChannel eventChannel = new EventChannel(registrar.messenger(), "flutter_tencentplayer/videoEvents" + handle.id());

                TencentPlayer player = new TencentPlayer(registrar, eventChannel, handle, call, result);
                videoPlayers.put(handle.id(), player);
                methodCalls.put(handle.id(), call);
                break;
            case "download":
                String urlOrFileId = call.argument("urlOrFileId").toString();
                EventChannel downloadEventChannel = new EventChannel(registrar.messenger(), "flutter_tencentplayer/downloadEvents" + urlOrFileId);
                TencentDownload tencentDownload = new TencentDownload(registrar, downloadEventChannel, call, result);

                downloadManagerMap.put(urlOrFileId, tencentDownload);
                break;
            case "stopDownload":
                downloadManagerMap.get(call.argument("urlOrFileId").toString()).stopDownload();
                result.success(null);
                break;
            default:
                long textureId = ((Number) call.argument("textureId")).longValue();
                TencentPlayer tencentPlayer = videoPlayers.get(textureId);
                if (tencentPlayer == null) {
                    result.error(
                            "Unknown textureId",
                            "No video player associated with texture id " + textureId,
                            null);
                    return;
                }
                onMethodCall(call, result, textureId, tencentPlayer);
                break;

        }
    }

    // flutter 发往android的命令
    private void onMethodCall(MethodCall call, Result result, long textureId, TencentPlayer player) {
        switch (call.method) {
            case "play":
                player.play(call);
                result.success(null);
                break;
            case "pause":
                player.pause();
                result.success(null);
                break;
            case "seekTo":
                int location = ((Number) call.argument("location")).intValue();
                player.seekTo(location);
                result.success(null);
                break;
            case "setRate":
                float rate = ((Number) call.argument("rate")).floatValue();
                player.setRate(rate);
                result.success(null);
                break;
            case "setBitrateIndex":
                int bitrateIndex = ((Number) call.argument("index")).intValue();
                player.setBitrateIndex(bitrateIndex);
                result.success(null);
                break;
            case "dispose":
                disposePlayer(result,player,textureId);
                break;
            case "mute":
                boolean isMute = ((Boolean) call.argument("isMute")).booleanValue();
                player.setMute(isMute);
                result.success(null);
                break;
            case "getCacheState":
                getCacheState(result,textureId);
                break;
            default:
                result.notImplemented();
                break;
        }

    }

    private void getCacheState(final Result result, long textureId){

        final MethodCall call = methodCalls.get(textureId);
        if(call.argument("cachePath") == null) {
            result.success(null);
            return ;
        }

        final Handler handler = new Handler(){
            @Override
            public void handleMessage(Message msg) {
                ArrayList<String> videoCacheInfoAry = msg.getData().getStringArrayList("videoCacheInfoAry");
                result.success(videoCacheInfoAry);
            }
        };
        new Thread(){
            @Override
            public void run() {
                ArrayList<String> videoCacheInfoAry = getVideoCacheInfo(call);
                Bundle bundle = new Bundle();
                bundle.putStringArrayList("videoCacheInfoAry",videoCacheInfoAry);
                Message message = new Message();
                message.setData(bundle);
                handler.sendMessage(message);
            }
        }.start();

    }

    private void disposePlayer(Result result,TencentPlayer player, long textureId){
        player.dispose();
        videoPlayers.remove(textureId);
        methodCalls.remove(textureId);
        result.success(null);
    }

    private void disposeAllPlayers() {
        for (int i = 0; i < videoPlayers.size(); i++) {
            videoPlayers.valueAt(i).dispose();
        }
        videoPlayers.clear();
        methodCalls.clear();
    }

    private void onDestroy() {
        disposeAllPlayers();
    }

    public static Bitmap getNetVideoBitmap(String videoUrl,ArrayList<String> videoCacheInfoAry) {
        Bitmap bitmap = null;
        String url = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            if(videoCacheInfoAry != null && videoCacheInfoAry.size() >= 6){
                if(Integer.parseInt(videoCacheInfoAry.get(4)) == 1){
                    url = videoCacheInfoAry.get(5);
                    //Log.d("哇啦",videoUrl);

                }
            }
            if(url == null){
                //根据本地缓存获取缩略图
                retriever.setDataSource(videoUrl, new HashMap());
            }else {
                //根据url获取缩略图
                retriever.setDataSource(url);
            }

            //获得第一帧图片
            bitmap = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC);
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
        } finally {
            retriever.release();
        }
        return bitmap;
    }

    private static ArrayList<String> getVideoCacheInfo( MethodCall call){

        ArrayList<String> videoCacheInfoAry = new ArrayList<>();
        List<TXCacheXMLItemBean> videoCacheItems = null;
        TXCacheXMLItemBean item = null;
        FileInputStream txCacheFileInStream = null;
        BufferedReader reader = null;
        try{
            String txCachePath = call.argument("cachePath").toString()+"/txvodcache/tx_cache.xml";
            Log.d("TXVideoPlayer",txCachePath);
            File txCacheFile = new File(txCachePath);
            if(txCacheFile.exists()){
                txCacheFileInStream = new FileInputStream(txCacheFile);
                XmlPullParser xmlPullParser = Xml.newPullParser();
                xmlPullParser.setInput(txCacheFileInStream,"utf-8");
                int type = xmlPullParser.getEventType();

                while(type != XmlPullParser.END_DOCUMENT){
                    switch (type){
                        case XmlPullParser.START_TAG:
                            if("caches".equals(xmlPullParser.getName())){
                                videoCacheItems = new ArrayList<>();
                            }else if("cache".equals(xmlPullParser.getName())){
                                item = new TXCacheXMLItemBean();
                            }else if("path".equals(xmlPullParser.getName())){
                                item.setPath(xmlPullParser.nextText());
                            }else if("time".equals(xmlPullParser.getName())){
                                item.setTime(xmlPullParser.nextText());
                            }else if("url".equals(xmlPullParser.getName())){
                                item.setUrl(xmlPullParser.nextText());
                            }else if("fileType".equals(xmlPullParser.getName())){
                                item.setFileType(xmlPullParser.nextText());
                            }
                            break;
                        case XmlPullParser.END_TAG:
                            if("cache".equals(xmlPullParser.getName())){
                                if(videoCacheItems != null && item != null) videoCacheItems.add(item);
                            }
                            break;
                    }
                    type = xmlPullParser.next();
                }
                Log.d("TXVideoPlayer",videoCacheItems.toString());
                if(videoCacheItems != null && videoCacheItems.size() > 0){
                    for(TXCacheXMLItemBean itemBean : videoCacheItems){
                        if(itemBean.getUrl().equals(call.argument("uri"))){
                            String videoPath = call.argument("cachePath").toString() + "/txvodcache/"+itemBean.getPath();
                            String videoInfoPath = videoPath+".info";
                            File videoInfoFile = new File(videoInfoPath);
                            reader = new BufferedReader(new FileReader(videoInfoFile));
                            String tempStr = null;
                            while ((tempStr = reader.readLine()) != null){
                                videoCacheInfoAry.add(tempStr);
                            }
                            int identity = -1;
                            if(videoCacheInfoAry.size() >= 3){
                                double total = videoCacheInfoAry.indexOf(1);
                                double curr = videoCacheInfoAry.indexOf(2);

                                if(total > curr){
                                    identity = 0;
                                }else {
                                    identity = 1;
                                }
                            }
                            videoCacheInfoAry.add(identity+"");
                            videoCacheInfoAry.add(videoPath);
                            break;
                        }
                    }
                }
            }else {
                Log.e("TXVideoPlayer",txCachePath+"is not exists");
            }

        }catch (Exception e){
            Log.e("TXVideoPlayer",e.getMessage());
        }finally {
            if(txCacheFileInStream != null){
                try {
                    txCacheFileInStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if(reader != null){
                try {
                    reader.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

        }

        return videoCacheInfoAry;
    }
}


class TXCacheXMLItemBean {
    private String path;
    private String time;
    private String url;
    private String fileType;

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getTime() {
        return time;
    }

    public void setTime(String time) {
        this.time = time;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getFileType() {
        return fileType;
    }

    public void setFileType(String fileType) {
        this.fileType = fileType;
    }
}