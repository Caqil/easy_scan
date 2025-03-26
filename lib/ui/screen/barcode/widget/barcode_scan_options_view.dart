import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeScanOptionsView extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onGeneratePressed;
  final VoidCallback onHistoryPressed;

  const BarcodeScanOptionsView({
    super.key,
    required this.onScanPressed,
    required this.onGeneratePressed,
    required this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderIcon(context),
                _buildTitle(),
                _buildSubtitle(),
                SizedBox(height: 24.h),
                _buildScanButton(context),
                SizedBox(height: 16.h),
                _buildGenerateButton(context),
                SizedBox(height: 16.h),
                _buildHistoryButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Icon(
        Icons.qr_code_scanner,
        size: 60.adaptiveSp,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTitle() {
    return AutoSizeText(
      'barcode_options.title'.tr(),
      style: GoogleFonts.slabo27px(
        fontSize: 24.adaptiveSp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle() {
    return AutoSizeText(
      'barcode_options.subtitle'.tr(),
      textAlign: TextAlign.center,
      style: GoogleFonts.slabo27px(
        fontWeight: FontWeight.w700,
        fontSize: 14.adaptiveSp,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onScanPressed,
      icon: const Icon(Icons.qr_code_scanner),
      label: AutoSizeText('barcode_options.scan_barcode'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onGeneratePressed,
      icon: const Icon(Icons.qr_code),
      label: AutoSizeText('barcode_options.generate_barcode'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onHistoryPressed,
      icon: const Icon(Icons.history),
      label: AutoSizeText('barcode_options.view_history'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        side: BorderSide(color: Colors.grey.shade400),
        foregroundColor: Colors.grey[700],
      ),
    );
  }
}
