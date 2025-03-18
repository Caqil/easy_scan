import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/barcode/barcode_result_screen.dart';
import 'package:easy_scan/ui/screen/barcode/qr_code_customization_screen.dart';
import 'package:easy_scan/ui/screen/barcode/widget/barcode_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class RecentBarcodesWidget extends ConsumerWidget {
  final bool showAllOption;
  final int maxItems;
  final String title;
  final Function()? onViewAllPressed;

  const RecentBarcodesWidget({
    super.key,
    this.showAllOption = true,
    this.maxItems = 5,
    this.title = 'recent_barcodes.default_title',
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentBarcodes = ref.watch(recentBarcodesProvider);

    if (recentBarcodes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit number of items shown
    final displayedBarcodes = recentBarcodes.take(maxItems).toList();

    return Container(
      margin: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.tr(),
                style: GoogleFonts.notoSerif(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showAllOption)
                TextButton(
                  onPressed: onViewAllPressed ??
                      () {
                        Navigator.pushNamed(context, '/barcode/history');
                      },
                  child: Text(
                    'recent_barcodes.view_all'.tr(),
                    style: GoogleFonts.notoSerif(
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),

          // Grid Layout for Barcodes - 2 columns
          GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: displayedBarcodes.length,
            itemBuilder: (context, index) {
              return _buildBarcodeCard(context, displayedBarcodes[index], ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard(
      BuildContext context, BarcodeScan scan, WidgetRef ref) {
    // Get content type for proper coloring and icons
    final contentType = _getContentTypeInfo(scan.barcodeValue);

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
      onLongPress: () {
        _showOptionsBottomSheet(context, scan, ref);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: scan.isCustomized
                ? Colors.purple.withOpacity(0.3)
                : Colors.transparent,
            width: scan.isCustomized ? 1.5 : 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Image with gradient background
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            scan.isCustomized && scan.customImagePath != null
                                ? [
                                    Colors.purple.withOpacity(0.05),
                                    Colors.deepPurple.withOpacity(0.1)
                                  ]
                                : [
                                    contentType.color.withOpacity(0.05),
                                    contentType.color.withOpacity(0.1)
                                  ],
                      ),
                    ),
                  ),

                  // QR Code
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: scan.isCustomized && scan.customImagePath != null
                        ? _buildCustomizedQRThumbnail(scan.customImagePath!)
                        : QrImageView(
                            data: scan.barcodeValue,
                            version: QrVersions.auto,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.all(8.w),
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: contentType.color,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: contentType.color,
                            ),
                          ),
                  ),

                  // Custom badge if customized
                  if (scan.isCustomized)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.brush,
                              size: 12.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'recent_barcodes.custom'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // More options button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _showOptionsBottomSheet(context, scan, ref),
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(12.r)),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12.r)),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade800,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content info
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type label with icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: contentType.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              contentType.icon,
                              size: 10.sp,
                              color: contentType.color,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              contentType.label,
                              style: GoogleFonts.notoSerif(
                                fontSize: 8.sp,
                                color: contentType.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // QR Code content preview
                  Text(
                    _truncateText(scan.barcodeValue, 25),
                    style: GoogleFonts.notoSerif(
                      fontSize: 10.sp,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build customized QR image thumbnail
  Widget _buildCustomizedQRThumbnail(String imagePath) {
    final file = File(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if image can't be loaded
          return Container(
            color: Colors.white,
            child: Icon(
              Icons.qr_code,
              size: 60.sp,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // Show iOS-style options bottom sheet when tapping More or long pressing
  void _showOptionsBottomSheet(
      BuildContext context, BarcodeScan scan, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeActionSheet(
        scan: scan,
        onView: () {
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
        onCustomize: () {
          final contentType = _getContentTypeInfo(scan.barcodeValue);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRCodeCustomizationScreen(
                data: scan.barcodeValue,
                contentType: contentType.label,
                barcodeFormat: scan.barcodeFormat,
              ),
            ),
          );
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: scan.barcodeValue));
          AppDialogs.showSnackBar(
            context,
            message: 'recent_barcodes.content_copied'.tr(),
            type: SnackBarType.success,
          );
        },
        onShare: () => _shareQrCode(context, scan),
        onDelete: () => _confirmDelete(context, scan, ref),
      ),
    );
  }

  // Helper function to share QR code
  Future<void> _shareQrCode(BuildContext context, BarcodeScan scan) async {
    try {
      // Show loading indicator
      AppDialogs.showSnackBar(
        context,
        message: 'recent_barcodes.preparing_share'.tr(),
      );

      String? imagePath;

      // Use the custom image if available
      if (scan.isCustomized && scan.customImagePath != null) {
        imagePath = scan.customImagePath;
      } else {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        imagePath = '${tempDir.path}/qr_share_$timestamp.png';

        // Note: This is a placeholder - in a real app, you would
        // capture the rendered QR code and save it to this path
      }

      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'recent_barcodes.qr_code_text'
              .tr(namedArgs: {'value': scan.barcodeValue}),
          subject: 'recent_barcodes.shared_qr_subject'.tr(),
        );
      } else {
        // Fallback to sharing just the text value
        await Share.share(
          scan.barcodeValue,
          subject: 'recent_barcodes.qr_content_subject'.tr(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'recent_barcodes.share_error'
              .tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }

  // Helper function to confirm deletion
  void _confirmDelete(BuildContext context, BarcodeScan scan, WidgetRef ref) {
    AppDialogs.showConfirmDialog(
      context,
      title: 'recent_barcodes.delete_qr_title'.tr(),
      message: 'recent_barcodes.delete_confirm'.tr(),
      confirmText: 'recent_barcodes.delete'.tr(),
      cancelText: 'recent_barcodes.cancel'.tr(),
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed) {
        // Delete from provider
        ref.read(barcodeScanHistoryProvider.notifier).removeScan(scan.id);

        // Show confirmation
        AppDialogs.showSnackBar(
          context,
          message: 'recent_barcodes.qr_deleted'.tr(),
          type: SnackBarType.success,
        );
      }
    });
  }

  // Helper function to get content type info
  _ContentTypeInfo _getContentTypeInfo(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _ContentTypeInfo(
          Icons.language, Colors.blue, 'recent_barcodes.url'.tr());
    } else if (value.startsWith('tel:') ||
        RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value)) {
      return _ContentTypeInfo(
          Icons.phone, Colors.green, 'recent_barcodes.phone'.tr());
    } else if (value.contains('@') && value.contains('.')) {
      return _ContentTypeInfo(
          Icons.email, Colors.orange, 'recent_barcodes.email'.tr());
    } else if (value.startsWith('WIFI:')) {
      return _ContentTypeInfo(
          Icons.wifi, Colors.purple, 'recent_barcodes.wifi'.tr());
    } else if (value.startsWith('MATMSG:') || value.startsWith('mailto:')) {
      return _ContentTypeInfo(
          Icons.email, Colors.orange, 'recent_barcodes.email'.tr());
    } else if (value.startsWith('geo:') ||
        RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
            .hasMatch(value)) {
      return _ContentTypeInfo(
          Icons.location_on, Colors.red, 'recent_barcodes.location'.tr());
    } else if (value.startsWith('BEGIN:VCARD')) {
      return _ContentTypeInfo(
          Icons.contact_page, Colors.indigo, 'recent_barcodes.contact'.tr());
    } else if (value.startsWith('BEGIN:VEVENT')) {
      return _ContentTypeInfo(
          Icons.event, Colors.teal, 'recent_barcodes.event'.tr());
    } else if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      return _ContentTypeInfo(
          Icons.qr_code, Colors.black, 'recent_barcodes.product'.tr());
    } else {
      return _ContentTypeInfo(
          Icons.text_fields, Colors.grey, 'recent_barcodes.text'.tr());
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class _ContentTypeInfo {
  final IconData icon;
  final Color color;
  final String label;

  _ContentTypeInfo(this.icon, this.color, this.label);
}
