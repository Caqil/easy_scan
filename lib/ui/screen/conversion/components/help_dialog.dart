import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("help_dialog.title".tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _helpItem(
            "help_dialog.ocr_title".tr(),
            "help_dialog.ocr_description".tr(),
          ),
          SizedBox(height: 8.h),
          _helpItem(
            "help_dialog.image_quality_title".tr(),
            "help_dialog.image_quality_description".tr(),
          ),
          SizedBox(height: 8.h),
          _helpItem(
            "help_dialog.pdf_password_title".tr(),
            "help_dialog.pdf_password_description".tr(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("help_dialog.close_button".tr()),
        ),
      ],
    );
  }

  Widget _helpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(description),
      ],
    );
  }
}
