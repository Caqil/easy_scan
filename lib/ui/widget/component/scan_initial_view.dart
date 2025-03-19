import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanInitialView extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onImportPressed;

  const ScanInitialView({
    super.key,
    required this.onScanPressed,
    required this.onImportPressed,
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
              spacing: 8.h,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScanIcon(context),
                _buildTitle(),
                _buildSubtitle(),
                _buildScanButton(context),
                _buildImportButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanIcon(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Icon(
        Icons.document_scanner,
        size: 60.sp,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'scan.ready_to_scan'.tr(),
      style: GoogleFonts.slabo27px(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'scan.scan_documents_or_import'.tr(),
      textAlign: TextAlign.center,
      style: GoogleFonts.slabo27px(
        fontWeight: FontWeight.w700,
        fontSize: 14.sp,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onScanPressed,
      icon: const Icon(Icons.camera_alt),
      label: Text('scan.start_scanning'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildImportButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onImportPressed,
      icon: const Icon(Icons.photo_library),
      label: Text('scan.import_from_gallery'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
