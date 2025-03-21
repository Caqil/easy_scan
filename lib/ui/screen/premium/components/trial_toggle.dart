import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TrialToggle extends StatelessWidget {
  final bool isTrialEnabled;
  final ValueChanged<bool> onChanged;

  const TrialToggle({
    Key? key,
    required this.isTrialEnabled,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'trial_explanation.start_hint'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                AutoSizeText(
                  'trial_explanation.price_info_1'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isTrialEnabled,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
            activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
