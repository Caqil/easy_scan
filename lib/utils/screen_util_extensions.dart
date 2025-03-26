import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension ResponsiveExtensions on num {
  double get adaptiveSp {
    final screenWidth = ScreenUtil().screenWidth;
    double scaleFactor = 1.0;
    if (screenWidth > 1200) {
      scaleFactor = 0.65;
    } else if (screenWidth > 900) {
      scaleFactor = 0.75;
    } else if (screenWidth > 600) {
      scaleFactor = 0.85;
    }

    return (this * scaleFactor).sp;
  }

  double get adaptiveH {
    final screenHeight = ScreenUtil().screenHeight;
    double scaleFactor = 1.0;
    if (screenHeight > 1200) {
      scaleFactor = 0.7;
    } else if (screenHeight > 900) {
      scaleFactor = 0.8;
    } else if (screenHeight > 600) {
      scaleFactor = 0.9;
    }

    return (this * scaleFactor).h;
  }

  double get adaptiveW {
    final screenWidth = ScreenUtil().screenWidth;
    double scaleFactor = 1.0;

    // Apply scaling factor based on screen width
    if (screenWidth > 1200) {
      scaleFactor = 0.7;
    } else if (screenWidth > 900) {
      scaleFactor = 0.8;
    } else if (screenWidth > 600) {
      scaleFactor = 0.9;
    }

    // Important: Use the original .w method, not adaptiveW to avoid recursion
    return (this * scaleFactor).w;
  }
}

/// Extension for BuildContext to provide screen size information
extension ContextExtensions on BuildContext {
  /// Check if current screen is tablet or larger
  bool get isTablet => MediaQuery.of(this).size.width >= 600;

  /// Check if current screen is large tablet/desktop
  bool get isLargeScreen => MediaQuery.of(this).size.width >= 900;

  /// Get text scale factor based on screen size
  double get textScaleFactor {
    final width = MediaQuery.of(this).size.width;
    if (width >= 900) {
      return 0.75;
    } else if (width >= 600) {
      return 0.85;
    }
    return 1.0;
  }

  /// Get appropriate horizontal padding for current device
  EdgeInsets get adaptivePadding {
    if (isLargeScreen) {
      return EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h);
    } else if (isTablet) {
      return EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
    } else {
      return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
    }
  }
}
