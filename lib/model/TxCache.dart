import 'dart:convert' show json;

class TxCache {

  String fileType;
  String path;
  String time;
  String url;

  TxCache.fromParams({this.fileType, this.path, this.time, this.url});

  factory TxCache(jsonStr) => jsonStr == null ? null : jsonStr is String ? new TxCache.fromJson(json.decode(jsonStr)) : new TxCache.fromJson(jsonStr);

  TxCache.fromJson(jsonRes) {
    fileType = jsonRes['fileType'];
    path = jsonRes['path'];
    time = jsonRes['time'];
    url = jsonRes['url'];
  }

  @override
  String toString() {
    return '{"fileType": ${fileType != null?'${json.encode(fileType)}':'null'},"path": ${path != null?'${json.encode(path)}':'null'},"time": ${time != null?'${json.encode(time)}':'null'},"url": ${url != null?'${json.encode(url)}':'null'}}';
  }
}

