import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/models/content_type.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:easy_scan/ui/screen/barcode/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/models/barcode_scan.dart';
import 'barcode_result_screen.dart';

class BarcodeHistoryScreen extends ConsumerStatefulWidget {
  const BarcodeHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BarcodeHistoryScreen> createState() =>
      _BarcodeHistoryScreenState();
}

class _BarcodeHistoryScreenState extends ConsumerState<BarcodeHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // Get scan history from provider
    final scanHistory = ref.watch(barcodeScanHistoryProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'Scan History',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (scanHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearHistoryDialog(context),
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: scanHistory.isEmpty
          ? _buildEmptyState()
          : _buildHistoryList(scanHistory),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 72.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Scan History',
            style: GoogleFonts.notoSerif(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your scanned barcodes will appear here',
            style: GoogleFonts.notoSerif(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label:  Text('scan.start_scanning'.tr()),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<BarcodeScan> history) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final scan = history[index];
        return _buildHistoryItem(scan);
      },
    );
  }

  Widget _buildHistoryItem(BarcodeScan scan) {
    final contentType = getContentTypeIcon(scan.barcodeValue);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 1,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Left icon or custom QR thumbnail
              scan.isCustomized && scan.customImagePath != null
                  ? _buildCustomizedThumbnail(scan.customImagePath!)
                  : Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: contentType.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        contentType.icon,
                        color: contentType.color,
                        size: 24.sp,
                      ),
                    ),
              SizedBox(width: 16.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _truncateText(scan.barcodeValue, 40),
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      scan.isCustomized
                          ? 'Customized • ${_formatDate(scan.timestamp)}'
                          : '${contentType.label} • ${_formatDate(scan.timestamp)}',
                      style: GoogleFonts.notoSerif(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Action
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizedThumbnail(String imagePath) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.r),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.purple.withOpacity(0.1),
              child: Icon(
                Icons.qr_code,
                color: Colors.purple,
                size: 24.sp,
              ),
            );
          },
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  ContentTypeInfo getContentTypeIcon(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ContentTypeInfo(Icons.language, Colors.blue, 'URL');
    } else if (value.startsWith('tel:') ||
        RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value)) {
      return ContentTypeInfo(Icons.phone, Colors.green, 'Phone');
    } else if (value.contains('@') && value.contains('.')) {
      return ContentTypeInfo(Icons.email, Colors.orange, 'Email');
    } else if (value.startsWith('WIFI:')) {
      return ContentTypeInfo(Icons.wifi, Colors.purple, 'WiFi');
    } else if (value.startsWith('MATMSG:') || value.startsWith('mailto:')) {
      return ContentTypeInfo(Icons.email, Colors.orange, 'Email');
    } else if (value.startsWith('geo:') ||
        RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
            .hasMatch(value)) {
      return ContentTypeInfo(Icons.location_on, Colors.red, 'Location');
    } else if (value.startsWith('BEGIN:VCARD')) {
      return ContentTypeInfo(Icons.contact_page, Colors.indigo, 'Contact');
    } else if (value.startsWith('BEGIN:VEVENT')) {
      return ContentTypeInfo(Icons.event, Colors.teal, 'Event');
    } else if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      return ContentTypeInfo(Icons.qr_code, Colors.black, 'Product');
    } else {
      return ContentTypeInfo(Icons.text_fields, Colors.grey, 'Text');
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              ref.read(barcodeScanHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
