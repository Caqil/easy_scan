import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/conversion_state.dart';
import '../../../../providers/conversion_provider.dart';
import '../../../../ui/common/dialogs.dart';

class ConversionButton extends StatelessWidget {
  final ConversionState state;
  final WidgetRef ref;

  const ConversionButton({
    super.key,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = state.selectedFile != null &&
        state.inputFormat != null &&
        state.outputFormat != null &&
        !state.isConverting;

    return SizedBox(
      height: 56.h,
      child: ElevatedButton(
        onPressed: isEnabled ? () => _startConversion(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child:
            state.isConverting ? _buildLoadingIndicator() : _buildButtonLabel(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12.w),
            Text("conversion_button.converting".tr()), // Localized string
          ],
        ),
        SizedBox(height: 6.h),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white30,
        ),
      ],
    );
  }

  Widget _buildButtonLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(state.inputFormat?.icon ?? Icons.file_present, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          "conversion_button.convert".tr(), // Localized string
          style: GoogleFonts.notoSerif(fontSize: 16.sp),
        ),
        SizedBox(width: 8.w),
        Icon(state.outputFormat?.icon ?? Icons.file_present, size: 20.sp),
      ],
    );
  }

  void _startConversion(BuildContext context) {
    ref.read(conversionStateProvider.notifier).convertFile(
      onSuccess: () {
        AppDialogs.showSnackBar(
          context,
          message: "conversion_button.success_message".tr(), // Localized string
          type: SnackBarType.success,
        );
      },
      onFailure: (error) {
        AppDialogs.showSnackBar(
          context,
          message: "conversion_button.failure_message"
              .tr(args: [error]), // Localized string with argument
          type: SnackBarType.error,
        );
      },
    );
  }
}
