import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;
  final double? height;
  final Color? color;

  const SettingsDivider({
    super.key,
    this.indent,
    this.endIndent,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? 1,
      indent: indent ?? 72.r,
      endIndent: endIndent ?? 16.r,
      color: color,
    );
  }
}
