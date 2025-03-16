import 'dart:io';

import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
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
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (unchanged)
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
            // QR Code or Customized Image
            Container(
              width: 70.w,
              height: 70.w,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: scan.isCustomized && scan.customImagePath != null
                  ? _buildCustomizedQRThumbnail(scan.customImagePath!)
                  : QrImageView(
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
                color: getColorForType(scan.barcodeType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                scan.isCustomized ? 'Custom' : _getContentTypeLabel(scan),
                style: GoogleFonts.notoSerif(
                  fontSize: 10.sp,
                  color: getColorForType(scan.barcodeType),
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

  Color getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'url':
      case 'url/website':
        return Colors.blue;
      case 'phone':
      case 'phone number':
        return Colors.green;
      case 'email':
      case 'email address':
      case 'email message':
        return Colors.orange;
      case 'wifi':
      case 'wifi network':
        return Colors.purple;
      case 'location':
        return Colors.red;
      case 'contact':
      case 'contact information':
        return Colors.indigo;
      case 'event':
      case 'calendar event':
        return Colors.teal;
      case 'product':
      case 'product code':
        return Colors.brown;
      case 'custom':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  // New method to display customized QR image thumbnail
  Widget _buildCustomizedQRThumbnail(String imagePath) {
    final file = File(imagePath);

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image can't be loaded
        return Icon(
          Icons.qr_code,
          size: 40.sp,
          color: Colors.grey,
        );
      },
    );
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

/// A widget to display customized QR codes
class CustomizedQRCodesWidget extends ConsumerWidget {
  const CustomizedQRCodesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customizedCodes = ref.watch(customizedQrCodesProvider);

    if (customizedCodes.isEmpty) {
      return const SizedBox.shrink();
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
                  'My Designed QR Codes',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to customized QR codes screen
                    // You could implement a dedicated screen for these
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
            height: 140.h, // Slightly taller for customized codes
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              scrollDirection: Axis.horizontal,
              itemCount: customizedCodes.length,
              itemBuilder: (context, index) {
                return _buildCustomizedQrCard(context, customizedCodes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizedQrCard(BuildContext context, BarcodeScan scan) {
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
        width: 120.w,
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
          border: Border.all(
            color: Colors.blue.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Customized badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.brush,
                    size: 12.sp,
                    color: Colors.blue.shade800,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Custom Design',
                    style: GoogleFonts.notoSerif(
                      fontSize: 10.sp,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // QR Code
            Container(
              width: 80.w,
              height: 80.w,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: QrImageView(
                data: scan.barcodeValue,
                version: QrVersions.auto,
                size: 80.w,
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
                foregroundColor: scan.typeColor,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: scan.typeColor,
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Content type
            Text(
              scan.barcodeType,
              style: GoogleFonts.notoSerif(
                fontSize: 10.sp,
                color: scan.typeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
