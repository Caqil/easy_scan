import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeaderWidget extends StatelessWidget {
  final String appName;
  final String version;
  final IconData icon;
  final Color? backgroundColor;

  const AppHeaderWidget({
    Key? key,
    required this.appName,
    required this.version,
    required this.icon,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 36.r,
            ),
          ),
          SizedBox(height: 16.h),
          AutoSizeText(
            appName,
            style: GoogleFonts.slabo27px(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          AutoSizeText(
            version,
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
