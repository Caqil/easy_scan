import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/barcode_scan.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/barcode_provider.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/ui/screen/barcode/widget/customizable_qrcode.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class QRCodeCustomizationScreen extends ConsumerStatefulWidget {
  final String data;
  final String contentType;
  final String? barcodeFormat;
  final bool saveToLibrary;

  const QRCodeCustomizationScreen({
    Key? key,
    required this.data,
    required this.contentType,
    this.barcodeFormat,
    this.saveToLibrary = true,
  }) : super(key: key);

  @override
  ConsumerState<QRCodeCustomizationScreen> createState() =>
      _QRCodeCustomizationScreenState();
}

class _QRCodeCustomizationScreenState
    extends ConsumerState<QRCodeCustomizationScreen> {
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Custom ${_getTitle()}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

              // Custom name input field
              if (widget.saveToLibrary) ...[
                Text(
                  'QR Code Name',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    hintText: 'Enter a name for your QR code',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                SizedBox(height: 24.h),
              ],

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
      // Show a processing dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Processing'),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Saving QR code...'),
              ],
            ),
          ),
        );
      }

      // Save to library if enabled
      if (widget.saveToLibrary) {
        await _saveToLibrary(qrFile);
      }

      // Close the processing dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show saving options dialog
      if (context.mounted) {
        _showSavingOptionsDialog(qrFile);
      }
    } catch (e) {
      // Close the processing dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error saving QR code: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveToLibrary(File qrFile) async {
    try {
      // 1. Get a permanent file path in the app's documents directory
      final String documentName = _nameController.text.trim();
      final String qrImagePath = await FileUtils.getUniqueFilePath(
        documentName: documentName,
        extension: 'png',
        inTempDirectory: false,
      );

      // Copy the QR image to the permanent location
      final File permanentFile = await qrFile.copy(qrImagePath);

      // 2. Add to barcode history
      final BarcodeScan customizedScan = BarcodeScan(
        barcodeValue: widget.data,
        barcodeType: widget.contentType,
        barcodeFormat: widget.barcodeFormat ?? 'QR_CODE',
        timestamp: DateTime.now(),
        isCustomized: true,
        customImagePath: permanentFile.path,
      );

      ref.read(barcodeScanHistoryProvider.notifier).addScan(customizedScan);

      // 3. Create a document entry if appropriate
      // For QR codes, we can save them as documents too for better management
      final imageService = ImageService();
      final File thumbnailFile = await imageService.createThumbnail(
        permanentFile,
        size: AppConstants.thumbnailSize,
      );

      Document(
        name: documentName,
        pdfPath: permanentFile.path, // Using image path since it's not a PDF
        pagesPaths: [permanentFile.path],
        pageCount: 1,
        thumbnailPath: thumbnailFile.path,
        tags: [
          'qr_code',
          widget.contentType.toLowerCase().replaceAll(' ', '_')
        ],
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      ref.read(barcodeScanHistoryProvider.notifier).addScan(customizedScan);
    } catch (e) {
      throw Exception('Failed to save to library: $e');
    }
  }

  void _showSavingOptionsDialog(File qrFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do next?'),
            if (widget.saveToLibrary) ...[
              SizedBox(height: 8),
              Text(
                'Your QR code has been saved to your library',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return true to indicate success
            },
            child: Text('common.done'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareQRCode(qrFile);
            },
            child: Text('common.share'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(qrFile);
            },
            child: Text('Copy Content'),
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
                  'Your customized QR code will be saved to your library automatically. You can also share it or copy the content.'),
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
