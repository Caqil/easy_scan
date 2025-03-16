// lib/ui/widget/component/barcode_scan_options_view.dart

import 'package:flutter/material.dart';
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
        size: 60.sp,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Barcode Scanner',
      style: GoogleFonts.notoSerif(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Scan, generate, or view your barcode history',
      textAlign: TextAlign.center,
      style: GoogleFonts.notoSerif(
        fontSize: 14.sp,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onScanPressed,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Scan Barcode'),
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
      label: const Text('Generate Barcode'),
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
      label: const Text('View Scan History'),
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
