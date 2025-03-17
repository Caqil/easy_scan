import 'dart:io';
import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/barcode/barcode_result_screen.dart';
import 'package:easy_scan/ui/screen/barcode/qr_code_customization_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeActionSheet extends ConsumerWidget {
  final BarcodeScan scan;
  final VoidCallback? onView;
  final VoidCallback? onCustomize;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const BarcodeActionSheet({
    super.key,
    required this.scan,
    this.onView,
    this.onCustomize,
    this.onCopy,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentType = _getContentTypeInfo(scan.barcodeValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with QR info and close button
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR thumbnail
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: contentType.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: scan.isCustomized && scan.customImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(scan.customImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.qr_code,
                              color: contentType.color,
                              size: 24,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            contentType.icon,
                            size: 24,
                            color: contentType.color,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Code info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contentType.label,
                        style: GoogleFonts.notoSerif(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _truncateText(scan.barcodeValue, 40),
                        style: GoogleFonts.notoSerif(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionItem(
                      context: context,
                      icon: Icons.visibility,
                      label: 'View',
                      onTap: () {
                        Navigator.pop(context);
                        if (onView != null) {
                          onView!();
                        } else {
                          _viewDetails(context);
                        }
                      },
                    ),
                    _buildActionItem(
                      context: context,
                      icon: Icons.brush,
                      label: 'Customize',
                      onTap: () {
                        Navigator.pop(context);
                        if (onCustomize != null) {
                          onCustomize!();
                        } else {
                          _customizeQrCode(context, contentType.label);
                        }
                      },
                    ),
                    _buildActionItem(
                      context: context,
                      icon: Icons.copy,
                      label: 'Copy',
                      onTap: () {
                        Navigator.pop(context);
                        if (onCopy != null) {
                          onCopy!();
                        } else {
                          _copyToClipboard(context);
                        }
                      },
                    ),
                    _buildActionItem(
                      context: context,
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: () {
                        Navigator.pop(context);
                        if (onDelete != null) {
                          onDelete!();
                        } else {
                          _confirmDelete(context, ref);
                        }
                      },
                    ),
                  ],
                ),
              )),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // Helper method to build action items in the first row
  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.notoSerif(
                fontSize: 10.sp,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  // View barcode details
  void _viewDetails(BuildContext context) {
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
  }

  // Navigate to customize QR code screen
  void _customizeQrCode(BuildContext context, String contentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeCustomizationScreen(
          data: scan.barcodeValue,
          contentType: contentType,
          barcodeFormat: scan.barcodeFormat,
        ),
      ),
    );
  }

  // Copy barcode content to clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: scan.barcodeValue));
    AppDialogs.showSnackBar(
      context,
      message: 'Content copied to clipboard',
      type: SnackBarType.success,
    );
  }

  // Confirm delete action
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    AppDialogs.showConfirmDialog(
      context,
      title: 'Delete QR Code',
      message:
          'Are you sure you want to delete this QR code from your history?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed) {
        // Delete from provider
        ref.read(barcodeScanHistoryProvider.notifier).removeScan(scan.id);

        // Show confirmation
        AppDialogs.showSnackBar(
          context,
          message: 'QR code deleted from history',
          type: SnackBarType.success,
        );
      }
    });
  }

  // Helper to truncate text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Helper to get content type info
  _ContentTypeInfo _getContentTypeInfo(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _ContentTypeInfo(Icons.language, Colors.blue, 'URL');
    } else if (value.startsWith('tel:') ||
        RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value)) {
      return _ContentTypeInfo(Icons.phone, Colors.green, 'Phone');
    } else if (value.contains('@') && value.contains('.')) {
      return _ContentTypeInfo(Icons.email, Colors.orange, 'Email');
    } else if (value.startsWith('WIFI:')) {
      return _ContentTypeInfo(Icons.wifi, Colors.purple, 'WiFi');
    } else if (value.startsWith('MATMSG:') || value.startsWith('mailto:')) {
      return _ContentTypeInfo(Icons.email, Colors.orange, 'Email');
    } else if (value.startsWith('geo:') ||
        RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
            .hasMatch(value)) {
      return _ContentTypeInfo(Icons.location_on, Colors.red, 'Location');
    } else if (value.startsWith('BEGIN:VCARD')) {
      return _ContentTypeInfo(Icons.contact_page, Colors.indigo, 'Contact');
    } else if (value.startsWith('BEGIN:VEVENT')) {
      return _ContentTypeInfo(Icons.event, Colors.teal, 'Event');
    } else if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      return _ContentTypeInfo(Icons.qr_code, Colors.black, 'Product');
    } else {
      return _ContentTypeInfo(Icons.text_fields, Colors.grey, 'Text');
    }
  }
}

class _ContentTypeInfo {
  final IconData icon;
  final Color color;
  final String label;

  _ContentTypeInfo(this.icon, this.color, this.label);
}
