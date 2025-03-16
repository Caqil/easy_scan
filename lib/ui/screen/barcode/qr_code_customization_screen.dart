import 'dart:io';
import 'package:easy_scan/ui/screen/barcode/widget/customizable_qrcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class QRCodeCustomizationScreen extends ConsumerStatefulWidget {
  final String data;
  final String contentType;

  const QRCodeCustomizationScreen({
    Key? key,
    required this.data,
    required this.contentType,
  }) : super(key: key);

  @override
  ConsumerState<QRCodeCustomizationScreen> createState() =>
      _QRCodeCustomizationScreenState();
}

class _QRCodeCustomizationScreenState
    extends ConsumerState<QRCodeCustomizationScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'Customize QR Code',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info text
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Customize your QR code before saving or sharing. Add a logo, change colors, and more!',
                        style: GoogleFonts.notoSerif(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Customizable QR Code
              CustomizableQRCode(
                data: widget.data,
                initialTitle: _getTitle(),
                onSaveQR: _handleSaveQR,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.contentType.toLowerCase()) {
      case 'url/website':
        return 'Website URL';
      case 'phone number':
        return 'Phone Number';
      case 'email address':
      case 'email message':
        return 'Email Address';
      case 'wifi network':
        return 'WiFi Network';
      case 'location':
        return 'Location';
      case 'contact':
        return 'Contact Information';
      case 'calendar event':
        return 'Calendar Event';
      case 'product code':
        return 'Product Code';
      default:
        return 'QR Code';
    }
  }

  Future<void> _handleSaveQR(File qrFile) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Show saving options dialog
      _showSavingOptionsDialog(qrFile);
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Error saving QR code: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSavingOptionsDialog(File qrFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save QR Code'),
        content: Text('Choose how you want to save your QR code'),
        actions: [
          
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareQRCode(qrFile);
            },
            child: Text('Share'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(qrFile);
            },
            child: Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }


  Future<void> _shareQRCode(File qrFile) async {
    try {
      // Share the file and barcode data
      await Share.shareXFiles(
        [XFile(qrFile.path)],
        text: widget.data,
        subject: 'QR Code: ${_getTitle()}',
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Error sharing QR code: $e',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _copyToClipboard(File qrFile) async {
    try {
      // Copy the data to clipboard
      await Clipboard.setData(ClipboardData(text: widget.data));

      AppDialogs.showSnackBar(
        context,
        message: 'Data copied to clipboard',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Error copying data: $e',
        type: SnackBarType.error,
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Customization Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Colors',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'Select different colors for your QR code or use a gradient background.'),
              SizedBox(height: 12),
              Text(
                'Add Logo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'Add a custom logo image to the center of your QR code. Be careful not to make it too large or the code might not scan properly.'),
              SizedBox(height: 12),
              Text(
                'Change Shapes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'Customize the eye and data module shapes for a unique look.'),
              SizedBox(height: 12),
              Text(
                'Saving and Sharing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'You can save to gallery, share with others, or copy the data to clipboard.'),
              SizedBox(height: 12),
              Text(
                'Scanning',
                style: TextStyle(
                    fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
              ),
              Text(
                  'Note: Very heavily customized QR codes may be difficult to scan with some devices. If you have trouble scanning, try using fewer customizations.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
