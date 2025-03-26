import 'dart:io';
import 'package:scanpro/models/barcode_scan.dart';
import 'package:scanpro/providers/barcode_provider.dart';
import 'package:scanpro/ui/screen/barcode/qr_code_customization_screen.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_localization/easy_localization.dart';

class BarcodeResultScreen extends ConsumerWidget {
  final String barcodeValue;
  final String barcodeType;
  final String barcodeFormat;

  // GlobalKey for capturing the QR code for sharing
  final GlobalKey _qrKey = GlobalKey();

  BarcodeResultScreen({
    super.key,
    required this.barcodeValue,
    required this.barcodeType,
    required this.barcodeFormat,
  });

  BarcodeScan? _findCustomizedScan(WidgetRef ref) {
    final barcodeHistory = ref.watch(barcodeScanHistoryProvider);

    // Find the most recent customized version matching this barcode value
    for (final scan in barcodeHistory) {
      if (scan.barcodeValue == barcodeValue &&
          scan.isCustomized == true &&
          scan.customImagePath != null) {
        return scan;
      }
    }

    return null;
  }

  Widget _buildCustomizedQRDisplay(String imagePath) {
    final file = File(imagePath);

    return RepaintBoundary(
      key: _qrKey, // Keep the key for sharing functionality
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            'barcode_result.customized_qr'.tr(),
            style: GoogleFonts.slabo27px(
              color: Colors.white,
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Image.file(
            file,
            width: 250.w,
            height: 250.w,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if the image can't be loaded
              return BarcodeResultQRCode(
                barcodeValue: barcodeValue,
                barcodeType: _determineContentType().toLowerCase(),
                qrKey: _qrKey,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionButtons = _getActionButtons(context, ref);
    final contentType = _determineContentType();
    final isQrCode = _isQrCodeFormat();
    final customizedScan = _findCustomizedScan(ref);
    return Scaffold(
      appBar: CustomAppBar(
        title: AutoSizeText(
          'barcode_result.scan_result'.tr(),
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content Type with format indicator
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: AutoSizeText(
                            contentType,
                            style: GoogleFonts.slabo27px(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.adaptiveSp,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isQrCode
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isQrCode
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: AutoSizeText(
                            isQrCode
                                ? 'barcode_result.qr_code'.tr()
                                : 'barcode_result.barcode'.tr(),
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 10.adaptiveSp,
                              color: isQrCode ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    Center(
                      child: customizedScan != null &&
                              customizedScan.customImagePath != null
                          ? _buildCustomizedQRDisplay(
                              customizedScan.customImagePath!)
                          : BarcodeResultQRCode(
                              barcodeValue: barcodeValue,
                              barcodeType: contentType.toLowerCase(),
                              qrKey: _qrKey,
                            ),
                    ),
                    SizedBox(height: 24.h),

                    // Barcode Value
                    AutoSizeText(
                      'barcode_result.content'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.adaptiveSp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    AutoSizeText(
                      barcodeValue,
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.adaptiveSp,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Technical Info
                    ExpansionTile(
                      title: AutoSizeText(
                        'barcode_result.technical_details'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.adaptiveSp,
                        ),
                      ),
                      collapsedIconColor: Colors.grey,
                      iconColor: Theme.of(context).primaryColor,
                      children: [
                        ListTile(
                          title: AutoSizeText(
                            'barcode_result.barcode_format'.tr(),
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.adaptiveSp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          subtitle: AutoSizeText(
                            barcodeFormat,
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.adaptiveSp,
                            ),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: AutoSizeText(
                            'barcode_result.barcode_type'.tr(),
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.adaptiveSp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          subtitle: AutoSizeText(
                            barcodeType,
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.adaptiveSp,
                            ),
                          ),
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: actionButtons,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to check if this is a QR code (vs linear barcode)
  bool _isQrCodeFormat() {
    final qrFormats = ['QR_CODE', 'AZTEC', 'DATA_MATRIX'];
    return qrFormats.contains(barcodeFormat) || barcodeFormat.contains('QR');
  }

  String _determineContentType() {
    if (barcodeValue.startsWith('http://') ||
        barcodeValue.startsWith('https://')) {
      return 'barcode_result.url_website'.tr();
    } else if (barcodeValue.startsWith('tel:') ||
        RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(barcodeValue)) {
      return 'barcode_result.phone_number'.tr();
    } else if (barcodeValue.contains('@') && barcodeValue.contains('.')) {
      return 'barcode_result.email_address'.tr();
    } else if (barcodeValue.startsWith('WIFI:')) {
      return 'barcode_result.wifi_network'.tr();
    } else if (barcodeValue.startsWith('MATMSG:') ||
        barcodeValue.startsWith('mailto:')) {
      return 'barcode_result.email_message'.tr();
    } else if (barcodeValue.startsWith('geo:') ||
        RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
            .hasMatch(barcodeValue)) {
      return 'barcode_result.location'.tr();
    } else if (barcodeValue.startsWith('BEGIN:VCARD')) {
      return 'barcode_result.contact'.tr();
    } else if (barcodeValue.startsWith('BEGIN:VEVENT')) {
      return 'barcode_result.calendar_event'.tr();
    } else if (RegExp(r'^[0-9]+$').hasMatch(barcodeValue)) {
      return 'barcode_result.product_code'.tr();
    } else {
      return 'barcode_result.text'.tr();
    }
  }

  List<Widget> _getActionButtons(BuildContext context, WidgetRef ref) {
    final List<Widget> buttons = [];
    final contentType = _determineContentType();
    final isQrCode = _isQrCodeFormat();

    // Copy button is always available
    buttons.add(
      OutlinedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: barcodeValue));
          AppDialogs.showSnackBar(
            context,
            message: 'barcode_result.copied_to_clipboard'.tr(),
            type: SnackBarType.success,
          );
        },
        icon: const Icon(Icons.copy),
        label: AutoSizeText('barcode_result.copy_to_clipboard'.tr()),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );

    buttons.add(SizedBox(height: 12.h));

    // Add QR Code Customization button if this is a QR code
    if (isQrCode) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _navigateToCustomizationScreen(context, ref),
          icon: const Icon(Icons.edit),
          label: AutoSizeText('barcode_result.customize_qr_code'.tr()),
          style: OutlinedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      );

      buttons.add(SizedBox(height: 12.h));
    }

    // Add content-specific buttons
    switch (contentType) {
      case 'Url Website':
        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _launchUrl(barcodeValue, context),
            icon: const Icon(Icons.open_in_browser),
            label: AutoSizeText('barcode_result.open_in_browser'.tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
        break;

      case 'Phone Number':
        final phoneNumber = barcodeValue.startsWith('tel:')
            ? barcodeValue.substring(4)
            : barcodeValue;

        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _launchUrl('tel:$phoneNumber', context),
            icon: const Icon(Icons.phone),
            label: AutoSizeText('barcode_result.call_number'.tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );

        buttons.add(SizedBox(height: 12.h));

        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _launchUrl('sms:$phoneNumber', context),
            icon: const Icon(Icons.message),
            label: AutoSizeText('barcode_result.send_message'.tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
        break;

      case 'Email Address':
        final email = barcodeValue.startsWith('mailto:')
            ? barcodeValue.substring(7)
            : barcodeValue;

        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _launchUrl('mailto:$email', context),
            icon: const Icon(Icons.email),
            label: AutoSizeText('barcode_result.send_email'.tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
        break;

      case 'Wifi Network':
        // Parse WIFI:T:WPA;S:MyNetwork;P:password;;
        final ssid = RegExp(r'S:(.*?)(;|$)').firstMatch(barcodeValue)?.group(1);
        final password =
            RegExp(r'P:(.*?)(;|$)').firstMatch(barcodeValue)?.group(1);

        if (ssid != null) {
          buttons.add(
            OutlinedButton.icon(
              onPressed: () {
                AppDialogs.showSnackBar(
                  context,
                  message: 'barcode_result.wifi_details_copied'.tr(),
                  type: SnackBarType.success,
                );
              },
              icon: const Icon(Icons.wifi),
              label: AutoSizeText('barcode_result.connect_to_network'.tr()),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          );

          if (password != null) {
            buttons.add(SizedBox(height: 12.h));

            buttons.add(
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  AppDialogs.showSnackBar(
                    context,
                    message: 'barcode_result.wifi_password_copied'.tr(),
                    type: SnackBarType.success,
                  );
                },
                icon: const Icon(Icons.password),
                label: AutoSizeText('barcode_result.copy_password'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            );
          }
        }
        break;

      case 'location':
        String mapUrl;
        if (barcodeValue.startsWith('geo:')) {
          // Parse geo:37.786971,-122.399677
          mapUrl = 'https://maps.google.com/?q=${barcodeValue.substring(4)}';
        } else {
          // Assume it's already lat,long
          mapUrl = 'https://maps.google.com/?q=$barcodeValue';
        }

        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _launchUrl(mapUrl, context),
            icon: const Icon(Icons.map),
            label: AutoSizeText('barcode_result.open_in_maps'.tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
        break;

      default:
        // For other types, we just have the copy button already added
        break;
    }

    // Add Share button as the last option
    buttons.add(SizedBox(height: 12.h));
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => _shareResult(context),
        icon: const Icon(Icons.share),
        label: AutoSizeText('barcode_result.share_qr_code'.tr()),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );

    return buttons;
  }

  void _navigateToCustomizationScreen(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeCustomizationScreen(
          data: barcodeValue,
          contentType: _determineContentType(),
        ),
      ),
    ).then((customImagePath) {
      // Only update if we got a result back (the custom image path)
      if (customImagePath != null && customImagePath is String) {
        // Create a new scan to update the history with the customized QR code
        final updatedScan = BarcodeScan(
          barcodeValue: barcodeValue,
          barcodeType: _determineContentType(),
          barcodeFormat: barcodeFormat,
          timestamp: DateTime.now(),
          isCustomized: true,
          customImagePath: customImagePath, // Save the image path
        );

        // Add to provider to update recent scans
        ref.read(barcodeScanHistoryProvider.notifier).addScan(updatedScan);
      }
    });
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          AppDialogs.showSnackBar(
            context,
            message:
                'barcode_result.could_not_launch'.tr(namedArgs: {'url': url}),
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'barcode_result.error_launching_url'
              .tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }

  // Share the QR code image and barcode data
  void _shareResult(BuildContext context) async {
    try {
      // Check if the QR code is rendered
      if (_qrKey.currentContext == null) {
        AppDialogs.showSnackBar(
          context,
          message: 'barcode_result.qr_not_ready'.tr(),
          type: SnackBarType.error,
        );
        return;
      }

      // Show a loading indicator
      AppDialogs.showSnackBar(
        context,
        message: 'barcode_result.preparing_qr'.tr(),
        type: SnackBarType.normal,
      );

      // 1. Capture the QR code as an image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image =
          await boundary.toImage(pixelRatio: 3.0); // Higher quality
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('barcode_result.capture_failed'.tr());
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = '${tempDir.path}/qrcode_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // 3. Share the file and the barcode data
      final String contentTypeStr = _determineContentType();
      final String shareText = 'barcode_result.share_text'
          .tr(namedArgs: {'type': contentTypeStr, 'value': barcodeValue});

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject:
            'barcode_result.qr_subject'.tr(namedArgs: {'type': contentTypeStr}),
      );
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'barcode_result.share_error'
              .tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }
}

// QR Code Widget
class BarcodeResultQRCode extends StatelessWidget {
  final String barcodeValue;
  final String barcodeType;
  final GlobalKey qrKey;

  const BarcodeResultQRCode({
    super.key,
    required this.barcodeValue,
    required this.barcodeType,
    required this.qrKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: qrKey,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getColorsForType(barcodeType),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _getColorsForType(barcodeType)[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Code header with icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForType(barcodeType),
                  color: Colors.white,
                  size: 20.adaptiveSp,
                ),
                SizedBox(width: 8.w),
                AutoSizeText(
                  barcodeType,
                  style: GoogleFonts.slabo27px(
                    color: Colors.white,
                    fontSize: 16.adaptiveSp,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      )
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // QR Code with white background
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: QrImageView(
                data: barcodeValue,
                version: QrVersions.auto,
                size: 200.w,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: _getColorsForType(barcodeType)[1],
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: _getColorsForType(barcodeType)[0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to determine colors based on barcode type
  List<Color> _getColorsForType(String type) {
    switch (type.toLowerCase()) {
      case 'url/website':
        return [Colors.blue.shade600, Colors.blue.shade900];
      case 'phone number':
        return [Colors.green.shade600, Colors.green.shade900];
      case 'email address':
      case 'email message':
        return [Colors.orange, Colors.deepOrange];
      case 'wifi network':
        return [Colors.purple, Colors.deepPurple];
      case 'location':
        return [Colors.red.shade600, Colors.red.shade900];
      case 'contact':
        return [Colors.indigo, Colors.blueAccent];
      case 'calendar event':
        return [Colors.teal, Colors.tealAccent];
      case 'product code':
        return [Colors.brown, Colors.brown.shade700];
      default:
        return [Colors.blueGrey, Colors.blueGrey.shade800];
    }
  }

  // Helper method to get the appropriate icon
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'url/website':
        return Icons.language;
      case 'phone number':
        return Icons.phone;
      case 'email address':
      case 'email message':
        return Icons.email;
      case 'wifi network':
        return Icons.wifi;
      case 'location':
        return Icons.location_on;
      case 'contact':
        return Icons.contact_page;
      case 'calendar event':
        return Icons.event;
      case 'product code':
        return Icons.qr_code_scanner;
      default:
        return Icons.qr_code;
    }
  }
}
