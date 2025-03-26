import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/providers/settings_provider.dart';
import 'package:scanpro/ui/common/dialogs.dart';

void showQualitySelector(
    BuildContext context, WidgetRef ref, int currentQuality) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => QualitySelectorSheet(
      initialQuality: currentQuality,
      ref: ref,
    ),
  );
}

class QualitySelectorSheet extends StatefulWidget {
  final int initialQuality;
  final WidgetRef ref;

  const QualitySelectorSheet({
    super.key,
    required this.initialQuality,
    required this.ref,
  });

  @override
  _QualitySelectorSheetState createState() => _QualitySelectorSheetState();
}

class _QualitySelectorSheetState extends State<QualitySelectorSheet> {
  late int _selectedQuality;

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.initialQuality;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            "settings.pdf_quality".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 20.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            "settings.pdf_quality_desc".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.adaptiveSp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AutoSizeText(
                "Lower Quality",
                style: GoogleFonts.slabo27px(
                  fontSize: 12.adaptiveSp,
                  color: Colors.grey.shade600,
                ),
              ),
              AutoSizeText(
                "Higher Quality",
                style: GoogleFonts.slabo27px(
                  fontSize: 12.adaptiveSp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Slider(
            value: _selectedQuality.toDouble(),
            min: 30,
            max: 100,
            divisions: 7,
            label: "$_selectedQuality%",
            onChanged: (value) {
              setState(() {
                _selectedQuality = value.round();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                "$_selectedQuality%",
                style: GoogleFonts.slabo27px(
                  fontSize: 24.adaptiveSp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.r),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: AutoSizeText("common.cancel".tr()),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.ref
                        .read(settingsProvider.notifier)
                        .setDefaultPdfQuality(_selectedQuality);
                    Navigator.pop(context);

                    AppDialogs.showSnackBar(
                      context,
                      message: "settings.quality_saved".tr(),
                      type: SnackBarType.success,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.r),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: AutoSizeText("common.save".tr()),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
