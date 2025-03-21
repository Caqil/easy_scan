import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const PremiumBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3), // Blue
              Color(0xFF673AB7), // Purple
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    'subscription.monthly_desc'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AutoSizeText(
                    'onboarding.start_free_trial'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Icon
            Container(
              width: 60.w,
              height: 60.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: Center(
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 36.r,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
