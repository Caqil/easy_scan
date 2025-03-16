import 'dart:io';
import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:easy_scan/ui/screen/barcode/qr_code_customization_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class BarcodeResultScreen extends ConsumerWidget {
  final String barcodeValue;
  final String barcodeType;
  final String barcodeFormat;

  // GlobalKey for capturing the QR code for sharing
  final GlobalKey _qrKey = GlobalKey();

  BarcodeResultScreen({
    Key? key,
    required this.barcodeValue,
    required this.barcodeType,
    required this.barcodeFormat,
  }) : super(key: key);
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
          Text(
            'Customized QR Code',
            style: GoogleFonts.notoSerif(
              color: Colors.white,
              fontSize: 16.sp,
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
        title: Text(
          'Scan Result',
          style: GoogleFonts.notoSerif(
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
                          child: Text(
                            contentType,
                            style: GoogleFonts.notoSerif(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
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
                          child: Text(
                            isQrCode ? 'QR Code' : 'Barcode',
                            style: GoogleFonts.notoSerif(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
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
                    Text(
                      'Content:',
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      barcodeValue,
                      style: GoogleFonts.notoSerif(
                        fontSize: 16.sp,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Technical Info
                    ExpansionTile(
                      title: Text(
                        'Technical Details',
                        style: GoogleFonts.notoSerif(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      collapsedIconColor: Colors.grey,
                      iconColor: Theme.of(context).primaryColor,
                      children: [
                        ListTile(
                          title: Text(
                            'Barcode Format',
                            style: GoogleFonts.notoSerif(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          subtitle: Text(
                            barcodeFormat,
                            style: GoogleFonts.notoSerif(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            'Barcode Type',
                            style: GoogleFonts.notoSerif(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          subtitle: Text(
                            barcodeType,
                            style: GoogleFonts.notoSerif(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
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
      return 'URL/Website';
    } else if (barcodeValue.startsWith('tel:') ||
        RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(barcodeValue)) {
      return 'Phone Number';
    } else if (barcodeValue.contains('@') && barcodeValue.contains('.')) {
      return 'Email Address';
    } else if (barcodeValue.startsWith('WIFI:')) {
      return 'WiFi Network';
    } else if (barcodeValue.startsWith('MATMSG:') ||
        barcodeValue.startsWith('mailto:')) {
      return 'Email Message';
    } else if (barcodeValue.startsWith('geo:') ||
        RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
            .hasMatch(barcodeValue)) {
      return 'Location';
    } else if (barcodeValue.startsWith('BEGIN:VCARD')) {
      return 'Contact';
    } else if (barcodeValue.startsWith('BEGIN:VEVENT')) {
      return 'Calendar Event';
    } else if (RegExp(r'^[0-9]+$').hasMatch(barcodeValue)) {
      return 'Product Code';
    } else {
      return 'Text';
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
            message: 'Copied to clipboard',
            type: SnackBarType.success,
          );
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copy to Clipboard'),
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
        ElevatedButton.icon(
          onPressed: () => _navigateToCustomizationScreen(context, ref),
          icon: const Icon(Icons.edit),
          label: const Text('Customize QR Code'),
          style: ElevatedButton.styleFrom(
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
      case 'URL/Website':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _launchUrl(barcodeValue, context),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
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
          ElevatedButton.icon(
            onPressed: () => _launchUrl('tel:$phoneNumber', context),
            icon: const Icon(Icons.phone),
            label: const Text('Call Number'),
            style: ElevatedButton.styleFrom(
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
            label: const Text('Send Message'),
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
          ElevatedButton.icon(
            onPressed: () => _launchUrl('mailto:$email', context),
            icon: const Icon(Icons.email),
            label: const Text('Send Email'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
        break;

      case 'WiFi Network':
        // Parse WIFI:T:WPA;S:MyNetwork;P:password;;
        final ssid = RegExp(r'S:(.*?)(;|$)').firstMatch(barcodeValue)?.group(1);
        final password =
            RegExp(r'P:(.*?)(;|$)').firstMatch(barcodeValue)?.group(1);

        if (ssid != null) {
          buttons.add(
            ElevatedButton.icon(
              onPressed: () {
                AppDialogs.showSnackBar(
                  context,
                  message: 'WiFi details copied to clipboard',
                  type: SnackBarType.success,
                );
              },
              icon: const Icon(Icons.wifi),
              label: const Text('Connect to Network'),
              style: ElevatedButton.styleFrom(
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
                    message: 'WiFi password copied to clipboard',
                    type: SnackBarType.success,
                  );
                },
                icon: const Icon(Icons.password),
                label: const Text('Copy Password'),
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

      case 'Location':
        String mapUrl;
        if (barcodeValue.startsWith('geo:')) {
          // Parse geo:37.786971,-122.399677
          mapUrl = 'https://maps.google.com/?q=' + barcodeValue.substring(4);
        } else {
          // Assume it's already lat,long
          mapUrl = 'https://maps.google.com/?q=' + barcodeValue;
        }

        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _launchUrl(mapUrl, context),
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
            style: ElevatedButton.styleFrom(
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
        label: const Text('Share QR Code'),
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
            message: 'Could not launch $url',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error launching URL: $e',
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
          message: 'QR code not ready for sharing',
          type: SnackBarType.error,
        );
        return;
      }

      // Show a loading indicator
      AppDialogs.showSnackBar(
        context,
        message: 'Preparing QR code for sharing...',
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
        throw Exception('Failed to capture QR code image');
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
      final String shareText = '$contentTypeStr QR Code\n$barcodeValue';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'QR Code: $contentTypeStr',
      );
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error sharing QR code: $e',
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
    Key? key,
    required this.barcodeValue,
    required this.barcodeType,
    required this.qrKey,
  }) : super(key: key);

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
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  barcodeType,
                  style: GoogleFonts.notoSerif(
                    color: Colors.white,
                    fontSize: 16.sp,
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
