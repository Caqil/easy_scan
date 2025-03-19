import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SettingsSectionHeader({
    Key? key,
    required this.title,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.only(left: 24.r, right: 24.r, top: 8.r, bottom: 4.r),
      child: Text(
        title,
        style: GoogleFonts.slabo27px(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
