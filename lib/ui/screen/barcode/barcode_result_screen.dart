import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class BarcodeResultScreen extends ConsumerWidget {
  final String barcodeValue;
  final String barcodeType;
  final String barcodeFormat;

  const BarcodeResultScreen({
    Key? key,
    required this.barcodeValue,
    required this.barcodeType,
    required this.barcodeFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionButtons = _getActionButtons(context);
    final contentType = _determineContentType();

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
                    // Content Type
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
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

                    SizedBox(height: 16.h),

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

  List<Widget> _getActionButtons(BuildContext context) {
    final List<Widget> buttons = [];
    final contentType = _determineContentType();

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
        onPressed: () {
          // Share the barcode value
        },
        icon: const Icon(Icons.share),
        label: const Text('Share'),
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
}
