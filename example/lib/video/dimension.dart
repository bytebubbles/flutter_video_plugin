

import 'package:flutter_screenutil/flutter_screenutil.dart';

double setWidth(int value){
  return ScreenUtil.getInstance().setWidth(value);
}
double setHeight(int value){
  return ScreenUtil.getInstance().setHeight(value);
}

double setSp(int value) {
  return ScreenUtil.getInstance().setSp(value);
}
double setFullWidth(int value){
  double _screenWidth = ScreenUtil.screenWidthDp;
  double scalWidth = _screenWidth / ScreenUtil.getInstance().height;
  return value * scalWidth;
}
double setFullSp(int value){
  double _screenWidth = ScreenUtil.screenWidthDp;
  double scalWidth = _screenWidth / ScreenUtil.getInstance().height;
  double n = value * scalWidth;
  if(!ScreenUtil.instance.allowFontScaling){
    return n;
  }else {
    return n / ScreenUtil.textScaleFactory;
  }

}