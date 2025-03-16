// lib/ui/widget/recent_barcodes.dart

import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_scan_provider.dart';
import 'package:easy_scan/ui/screen/barcode/barcode_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RecentBarcodesWidget extends ConsumerWidget {
  const RecentBarcodesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentBarcodes = ref.watch(recentBarcodesProvider);

    if (recentBarcodes.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if empty
    }

    return Container(
      margin: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Barcodes',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to barcode history screen
                    Navigator.pushNamed(context, '/barcode/history');
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.notoSerif(
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 130.h,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              scrollDirection: Axis.horizontal,
              itemCount: recentBarcodes.length,
              itemBuilder: (context, index) {
                return _buildBarcodeCard(context, recentBarcodes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard(BuildContext context, BarcodeScan scan) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BarcodeResultScreen(
              barcodeValue: scan.barcodeValue,
              barcodeType: scan.barcodeType,
              barcodeFormat: scan.barcodeFormat,
            ),
          ),
        );
      },
      child: Container(
        width: 110.w,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code
            Container(
              width: 70.w,
              height: 70.w,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: QrImageView(
                data: scan.barcodeValue,
                version: QrVersions.auto,
                size: 70.w,
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(height: 8.h),
            // Content type
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getColorForType(scan.barcodeType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _getContentTypeLabel(scan),
                style: GoogleFonts.notoSerif(
                  fontSize: 10.sp,
                  color: _getColorForType(scan.barcodeType),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4.h),
            // Truncated value
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                _truncateText(scan.barcodeValue, 10),
                style: GoogleFonts.notoSerif(
                  fontSize: 10.sp,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'URL':
        return Colors.blue;
      case 'Phone':
        return Colors.green;
      case 'Email':
        return Colors.orange;
      case 'WiFi':
        return Colors.purple;
      case 'Location':
        return Colors.red;
      case 'Contact':
        return Colors.indigo;
      case 'QR Code':
        return Colors.teal;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getContentTypeLabel(BarcodeScan scan) {
    if (scan.barcodeValue.startsWith('http')) {
      return 'URL';
    } else if (scan.barcodeValue.startsWith('WIFI:')) {
      return 'WiFi';
    } else if (scan.barcodeValue.startsWith('BEGIN:VCARD')) {
      return 'Contact';
    } else if (scan.barcodeValue.contains('@')) {
      return 'Email';
    } else {
      return scan.barcodeType;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
