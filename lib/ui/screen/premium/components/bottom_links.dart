import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomLinks extends StatelessWidget {
  final bool isPurchasing;
  final VoidCallback onTermsPressed;
  final VoidCallback onRestorePressed;

  const BottomLinks({
    super.key,
    required this.isPurchasing,
    required this.onTermsPressed,
    required this.onRestorePressed,
  });

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
              fontSize: 14.adaptiveSp,
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
              fontSize: 14.adaptiveSp,
            ),
          ),
        ),
      ],
    );
  }
}
