import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomLinks extends StatelessWidget {
  final bool isPurchasing;
  final VoidCallback onTermsPressed;
  final VoidCallback onRestorePressed;

  const BottomLinks({
    Key? key,
    required this.isPurchasing,
    required this.onTermsPressed,
    required this.onRestorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: isPurchasing ? null : onTermsPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: AutoSizeText(
            'subscription.terms'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.sp,
            ),
          ),
        ),
        AutoSizeText(
          '•',
          style: GoogleFonts.slabo27px(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: isPurchasing ? null : onRestorePressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: AutoSizeText(
            'subscription.restore_purchases'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
