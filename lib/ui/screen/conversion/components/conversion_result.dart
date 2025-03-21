import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import '../../../../models/conversion_state.dart';
import '../../../../providers/conversion_provider.dart';
import '../../../../ui/common/dialogs.dart';

class ConversionResultSection extends StatelessWidget {
  final ConversionState state;
  final WidgetRef ref;

  const ConversionResultSection({
    super.key,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (state.error != null) {
      return _buildErrorSection();
    } else if (state.convertedFilePath != null) {
      return _buildSuccessSection(context);
    }

    // This should not happen, but just in case
    return const SizedBox.shrink();
  }

  Widget _buildErrorSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade700, size: 20.sp),
              SizedBox(width: 8.w),
              AutoSizeText(
                "conversion_result.error.title".tr(), // Localized string
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            state.error!,
            style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700, color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green.shade700, size: 20.sp),
              SizedBox(width: 8.w),
              AutoSizeText(
                "conversion_result.success.title".tr(), // Localized string
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            "conversion_result.success.file_saved".tr(
                namedArgs: {'saved': path.basename(state.convertedFilePath!)}),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => OpenFile.open(state.convertedFilePath!),
                  icon: const Icon(Icons.file_open),
                  label: AutoSizeText("conversion_result.success.open"
                      .tr()), // Localized string
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Share functionality
                    AppDialogs.showSnackBar(
                      context,
                      message: "conversion_result.success.share_message"
                          .tr(), // Localized string
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: AutoSizeText("conversion_result.success.share"
                      .tr()), // Localized string
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (state.convertedFilePath != null &&
                    state.outputFormat != null) {
                  ref
                      .read(conversionStateProvider.notifier)
                      .saveConvertedFileAsDocument(
                        state.convertedFilePath!,
                        state.outputFormat!,
                        ref,
                      );

                  // Show success message
                  AppDialogs.showSnackBar(
                    context,
                    type: SnackBarType.success,
                    message: "conversion_result.success.save_success_message"
                        .tr(), // Localized string
                  );
                }
              },
              icon: const Icon(Icons.save_alt),
              label: AutoSizeText("conversion_result.success.save_to_library"
                  .tr()), // Localized string
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
