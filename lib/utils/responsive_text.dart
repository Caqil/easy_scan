import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveUtil {
  static double adaptiveSp(num value) {
    final screenWidth = ScreenUtil().screenWidth;
    double scaleFactor = 1.0;

    if (screenWidth > 1200) {
      scaleFactor = 0.65;
    } else if (screenWidth > 900) {
      scaleFactor = 0.75;
    } else if (screenWidth > 600) {
      scaleFactor = 0.85;
    }

    return (value * scaleFactor).sp;
  }

  static double adaptiveW(num value) {
    final screenWidth = ScreenUtil().screenWidth;
    double scaleFactor = 1.0;

    if (screenWidth > 1200) {
      scaleFactor = 0.7;
    } else if (screenWidth > 900) {
      scaleFactor = 0.8;
    } else if (screenWidth > 600) {
      scaleFactor = 0.9;
    }

    return (value * scaleFactor).w;
  }

  static double adaptiveH(num value) {
    final screenHeight = ScreenUtil().screenHeight;
    double scaleFactor = 1.0;

    if (screenHeight > 1200) {
      scaleFactor = 0.7;
    } else if (screenHeight > 900) {
      scaleFactor = 0.8;
    } else if (screenHeight > 600) {
      scaleFactor = 0.9;
    }

    return (value * scaleFactor).h;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isLargeScreen(context)) {
      return EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
    } else {
      return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
    }
  }
}
