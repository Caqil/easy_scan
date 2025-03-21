import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/barcode_scan.dart';
import 'package:scanpro/providers/barcode_provider.dart';
import 'package:scanpro/ui/screen/barcode/qr_code_customization_screen.dart';
import 'package:scanpro/ui/screen/barcode/widget/custom_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum BarcodeType {
  qrCode,
  url,
  email,
  phone,
  sms,
  wifi,
  location,
  contact,
  plainText,
}

class BarcodeGeneratorScreen extends ConsumerStatefulWidget {
  const BarcodeGeneratorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BarcodeGeneratorScreen> createState() =>
      _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState
    extends ConsumerState<BarcodeGeneratorScreen> {
  BarcodeType _selectedType = BarcodeType.qrCode;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _wifiNameController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailBodyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsBodyController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();

  String _generatedData = '';
  bool _wifiEncryption = true;
  bool _isGenerating = false;

  final GlobalKey _qrKey = GlobalKey();

  @override
  void dispose() {
    _contentController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    _phoneController.dispose();
    _smsBodyController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AutoSizeText(
          'barcode_generator.title'.tr(),
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector carousel
                _buildImprovedTypeSelector(),

                SizedBox(height: 24.h),

                // Input form with enhanced design
                _buildImprovedInputForm(),

                SizedBox(height: 24.h),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _validateAndGenerate,
                    icon: const Icon(Icons.qr_code),
                    label: AutoSizeText(_isGenerating
                        ? 'barcode_generator.generating'.tr()
                        : 'barcode_generator.generate_barcode'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // QR Code Display with enhanced design
                if (_generatedData.isNotEmpty) _buildImprovedBarcodeDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method for improved type selector
  Widget _buildImprovedTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          'barcode_generator.barcode_type'.tr(),
          style: GoogleFonts.slabo27px(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 100.h,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 8.w),
                _buildImprovedTypeOption(BarcodeType.qrCode,
                    'barcode_generator.qr_code'.tr(), Icons.qr_code_2),
                _buildImprovedTypeOption(BarcodeType.url,
                    'barcode_generator.url'.tr(), Icons.language),
                _buildImprovedTypeOption(BarcodeType.email,
                    'barcode_generator.email'.tr(), Icons.email),
                _buildImprovedTypeOption(BarcodeType.phone,
                    'barcode_generator.phone'.tr(), Icons.phone),
                _buildImprovedTypeOption(
                    BarcodeType.sms, 'barcode_generator.sms'.tr(), Icons.sms),
                _buildImprovedTypeOption(BarcodeType.wifi,
                    'barcode_generator.wifi'.tr(), Icons.wifi),
                _buildImprovedTypeOption(BarcodeType.location,
                    'barcode_generator.location'.tr(), Icons.location_on),
                _buildImprovedTypeOption(BarcodeType.contact,
                    'barcode_generator.contact'.tr(), Icons.contact_page),
                _buildImprovedTypeOption(BarcodeType.plainText,
                    'barcode_generator.text'.tr(), Icons.text_fields),
                SizedBox(width: 8.w),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // New method for improved type options
  Widget _buildImprovedTypeOption(
      BarcodeType type, String label, IconData icon) {
    final bool isSelected = _selectedType == type;
    final Color accentColor = _getColorForType(type);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _generatedData = '';
        });
      },
      child: Container(
        width: 80.w,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.2)
                    : accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? accentColor : Colors.grey.shade500,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 8.h),
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                color: isSelected ? accentColor : Colors.grey.shade700,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get color based on barcode type
  Color _getColorForType(BarcodeType type) {
    switch (type) {
      case BarcodeType.qrCode:
        return Colors.teal;
      case BarcodeType.url:
        return Colors.blue;
      case BarcodeType.email:
        return Colors.orange;
      case BarcodeType.phone:
        return Colors.green;
      case BarcodeType.sms:
        return Colors.deepPurple;
      case BarcodeType.wifi:
        return Colors.purple;
      case BarcodeType.location:
        return Colors.red;
      case BarcodeType.contact:
        return Colors.indigo;
      case BarcodeType.plainText:
        return Colors.blueGrey;
    }
  }

  // New method for improved input form
  Widget _buildImprovedInputForm() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'barcode_generator.enter_details'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: _getColorForType(_selectedType),
            ),
          ),
          SizedBox(height: 16.h),
          _buildTypeSpecificForm(),
        ],
      ),
    );
  }

  // This method determines which form to show based on selected type
  Widget _buildTypeSpecificForm() {
    switch (_selectedType) {
      case BarcodeType.qrCode:
        return _buildImprovedTextField(
          controller: _contentController,
          label: 'barcode_generator.content'.tr(),
          hintText: 'barcode_generator.enter_content'.tr(),
          icon: Icons.text_fields,
          maxLines: 3,
        );

      case BarcodeType.url:
        return _buildImprovedTextField(
          controller: _contentController,
          label: 'barcode_generator.website_url'.tr(),
          hintText: 'https://example.com',
          icon: Icons.link,
          keyboardType: TextInputType.url,
        );

      case BarcodeType.email:
        return Column(
          children: [
            _buildImprovedTextField(
              controller: _contentController,
              label: 'barcode_generator.email_address'.tr(),
              hintText: 'email@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _emailSubjectController,
              label: 'barcode_generator.subject_optional'.tr(),
              hintText: 'barcode_generator.enter_subject'.tr(),
              icon: Icons.subject,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _emailBodyController,
              label: 'barcode_generator.body_optional'.tr(),
              hintText: 'barcode_generator.enter_body'.tr(),
              icon: Icons.message,
              maxLines: 3,
            ),
          ],
        );

      case BarcodeType.phone:
        return _buildImprovedTextField(
          controller: _phoneController,
          label: 'barcode_generator.phone_number'.tr(),
          hintText: '+1 234 567 8900',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        );

      case BarcodeType.sms:
        return Column(
          children: [
            _buildImprovedTextField(
              controller: _phoneController,
              label: 'barcode_generator.phone_number'.tr(),
              hintText: '+1 234 567 8900',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _smsBodyController,
              label: 'barcode_generator.message_optional'.tr(),
              hintText: 'barcode_generator.enter_message'.tr(),
              icon: Icons.message,
              maxLines: 3,
            ),
          ],
        );

      case BarcodeType.wifi:
        return Column(
          children: [
            _buildImprovedTextField(
              controller: _wifiNameController,
              label: 'barcode_generator.wifi_ssid'.tr(),
              hintText: 'barcode_generator.enter_wifi_name'.tr(),
              icon: Icons.wifi,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _wifiPasswordController,
              label: 'pdf.password'.tr(),
              hintText: 'barcode_generator.enter_wifi_password'.tr(),
              icon: Icons.lock,
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: AutoSizeText(
                  'barcode_generator.security'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: AutoSizeText(
                  _wifiEncryption
                      ? 'barcode_generator.wpa_wpa2'.tr()
                      : 'barcode_generator.none_open'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                value: _wifiEncryption,
                onChanged: (value) {
                  setState(() {
                    _wifiEncryption = value;
                  });
                },
                secondary: Icon(
                  _wifiEncryption ? Icons.lock_outline : Icons.lock_open,
                  color: _wifiEncryption ? Colors.green : Colors.red,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                dense: true,
              ),
            ),
          ],
        );

      case BarcodeType.location:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildImprovedTextField(
                    controller: _latitudeController,
                    label: 'barcode_generator.latitude'.tr(),
                    hintText: '37.7749',
                    icon: Icons.north,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildImprovedTextField(
                    controller: _longitudeController,
                    label: 'barcode_generator.longitude'.tr(),
                    hintText: '-122.4194',
                    icon: Icons.east,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _locationNameController,
              label: 'barcode_generator.location_name_optional'.tr(),
              hintText: 'San Francisco',
              icon: Icons.place,
            ),
          ],
        );

      case BarcodeType.contact:
        return Column(
          children: [
            _buildImprovedTextField(
              controller: _contentController,
              label: 'barcode_generator.full_name'.tr(),
              hintText: 'John Doe',
              icon: Icons.person,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _phoneController,
              label: 'barcode_generator.phone_number'.tr(),
              hintText: '+1 234 567 8900',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _emailSubjectController,
              label: 'barcode_generator.email_optional'.tr(),
              hintText: 'email@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        );

      case BarcodeType.plainText:
        return _buildImprovedTextField(
          controller: _contentController,
          label: 'barcode_generator.text'.tr(),
          hintText: 'barcode_generator.enter_any_text'.tr(),
          icon: Icons.text_fields,
          maxLines: 5,
        );
    }
  }

  // New method for improved text fields
  Widget _buildImprovedTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    final Color accentColor = _getColorForType(_selectedType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: accentColor,
            ),
            SizedBox(width: 8.w),
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: accentColor,
                width: 1.5,
              ),
            ),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovedBarcodeDisplay() {
    if (_generatedData.isEmpty) return SizedBox.shrink();

    // Create a repaint boundary to capture the QR code for saving/sharing
    return RepaintBoundary(
      key: _qrKey,
      child: Column(
        children: [
          // Determine which QR code to show based on content type
          _buildTypeSpecificQRCode(),

          SizedBox(height: 16.h),

          // Data display below the QR code
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'barcode_generator.encoded_data'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4.h),
                AutoSizeText(
                  _generatedData,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.save_alt,
                label: 'common.save'.tr(),
                color: _getColorForType(_selectedType),
                onTap: _saveQrCode,
              ),
              _buildActionButton(
                icon: Icons.copy,
                label: 'barcode_generator.copy'.tr(),
                color: Colors.grey.shade700,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _generatedData));
                  AppDialogs.showSnackBar(
                    context,
                    message: 'barcode_generator.data_copied'.tr(),
                    type: SnackBarType.success,
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.share,
                label: 'common.share'.tr(),
                color: Colors.blue,
                onTap: _shareQrCode,
              ),
              _buildActionButton(
                icon: Icons.edit,
                label: 'barcode_generator.customize'.tr(),
                color: Colors.purple,
                onTap: () => _navigateToCustomization(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigate to customization screen
  void _navigateToCustomization() {
    if (_generatedData.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeCustomizationScreen(
          data: _generatedData,
          contentType: _selectedType.toString().split('.').last,
        ),
      ),
    );
  }

  // Helper method to determine which QR code style to use based on selected type
  Widget _buildTypeSpecificQRCode() {
    final Color accentColor = _getColorForType(_selectedType);

    // Choose different QR code styles based on content type
    switch (_selectedType) {
      case BarcodeType.wifi:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.wifi_connection'.tr(),
          gradientColors: [Colors.purple, Colors.deepPurple],
          size: 230.w,
        );

      case BarcodeType.url:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.website_url_title'.tr(),
          gradientColors: [Colors.blue.shade600, Colors.blue.shade900],
          size: 230.w,
        );

      case BarcodeType.email:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.email_link'.tr(),
          gradientColors: [Colors.orange, Colors.deepOrange],
          size: 230.w,
        );

      case BarcodeType.phone:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.phone_number_title'.tr(),
          gradientColors: [Colors.green.shade600, Colors.green.shade900],
          size: 230.w,
        );

      case BarcodeType.sms:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.sms_message'.tr(),
          gradientColors: [Colors.deepPurple, Colors.purple],
          size: 230.w,
        );

      case BarcodeType.location:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.location_title'.tr(),
          gradientColors: [Colors.red.shade600, Colors.red.shade900],
          size: 230.w,
        );

      case BarcodeType.contact:
        return GradientQRCode(
          data: _generatedData,
          title: 'barcode_generator.contact_info'.tr(),
          gradientColors: [Colors.indigo, Colors.blueAccent],
          size: 230.w,
        );

      case BarcodeType.qrCode:
      case BarcodeType.plainText:
        return CustomQRCode(
          data: _generatedData,
          title: _selectedType == BarcodeType.qrCode
              ? 'barcode_generator.qr_code_title'.tr()
              : 'barcode_generator.text_content'.tr(),
          primaryColor: accentColor,
          backgroundColor: Colors.white,
          size: 230.w,
          showShadow: true,
        );
    }
  }

  // Helper method for action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(height: 4.h),
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndGenerate() {
    // Reset any previous result
    String data = '';
    bool isValid = true;
    String errorMessage = '';

    setState(() {
      _isGenerating = true;
    });

    switch (_selectedType) {
      case BarcodeType.qrCode:
      case BarcodeType.plainText:
        data = _contentController.text.trim();
        if (data.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_content_error'.tr();
        }
        break;

      case BarcodeType.url:
        data = _contentController.text.trim();
        if (data.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_url_error'.tr();
        } else if (!data.startsWith('http://') &&
            !data.startsWith('https://')) {
          data = 'https://$data';
        }
        break;

      case BarcodeType.email:
        final email = _contentController.text.trim();
        final subject = _emailSubjectController.text.trim();
        final body = _emailBodyController.text.trim();

        if (email.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_email_error'.tr();
        } else {
          // Generate mailto format
          data = 'mailto:$email';
          if (subject.isNotEmpty || body.isNotEmpty) {
            data += '?';
            if (subject.isNotEmpty) {
              data += 'subject=${Uri.encodeComponent(subject)}';
            }
            if (body.isNotEmpty) {
              data += subject.isNotEmpty ? '&' : '';
              data += 'body=${Uri.encodeComponent(body)}';
            }
          }
        }
        break;

      case BarcodeType.phone:
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_phone_error'.tr();
        } else {
          data = 'tel:$phone';
        }
        break;

      case BarcodeType.sms:
        final phone = _phoneController.text.trim();
        final message = _smsBodyController.text.trim();

        if (phone.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_phone_error'.tr();
        } else {
          data = 'smsto:$phone';
          if (message.isNotEmpty) {
            data += ':$message';
          }
        }
        break;

      case BarcodeType.wifi:
        final ssid = _wifiNameController.text.trim();
        final password = _wifiPasswordController.text.trim();

        if (ssid.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_wifi_name_error'.tr();
        } else {
          // Generate WiFi QR format
          final String security = _wifiEncryption ? 'WPA' : 'nopass';
          data = 'WIFI:S:$ssid;T:$security;';
          if (_wifiEncryption && password.isNotEmpty) {
            data += 'P:$password;';
          }
          data += ';';
        }
        break;

      case BarcodeType.location:
        final lat = _latitudeController.text.trim();
        final lng = _longitudeController.text.trim();
        final name = _locationNameController.text.trim();

        if (lat.isEmpty || lng.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_lat_long_error'.tr();
        } else {
          try {
            double.parse(lat);
            double.parse(lng);
            data = 'geo:$lat,$lng';
            if (name.isNotEmpty) {
              data += '?q=$lat,$lng(${Uri.encodeComponent(name)})';
            }
          } catch (e) {
            isValid = false;
            errorMessage = 'barcode_generator.invalid_lat_long_error'.tr();
          }
        }
        break;

      case BarcodeType.contact:
        final name = _contentController.text.trim();
        final phone = _phoneController.text.trim();
        final email = _emailSubjectController.text.trim();

        if (name.isEmpty) {
          isValid = false;
          errorMessage = 'barcode_generator.enter_name_error'.tr();
        } else {
          // Generate vCard format
          data = 'BEGIN:VCARD\nVERSION:3.0\n';
          data += 'N:$name\n';
          data += 'FN:$name\n';

          if (phone.isNotEmpty) {
            data += 'TEL:$phone\n';
          }

          if (email.isNotEmpty) {
            data += 'EMAIL:$email\n';
          }

          data += 'END:VCARD';
        }
        break;
    }

    // Handle validation result
    if (!isValid) {
      setState(() {
        _isGenerating = false;
      });

      AppDialogs.showSnackBar(
        context,
        message: errorMessage,
        type: SnackBarType.error,
      );
      return;
    }

    // Set the generated data if valid
    setState(() {
      _generatedData = data;
      _isGenerating = false;

      // Save to barcode scan history
      _saveToHistory();
    });
  }

  void _saveToHistory() {
    // Create a BarcodeScan object to save to history
    final scan = BarcodeScan(
      barcodeValue: _generatedData,
      barcodeType: _selectedType.toString().split('.').last,
      barcodeFormat: _getBarcodeFormat(),
      timestamp: DateTime.now(),
    );

    // Add to provider
    ref.read(barcodeScanHistoryProvider.notifier).addScan(scan);

    // Show confirmation
    AppDialogs.showSnackBar(
      context,
      message: 'barcode_generator.saved_to_history'.tr(),
      type: SnackBarType.success,
    );
  }

  String _getBarcodeFormat() {
    // Return an appropriate format based on barcode type
    switch (_selectedType) {
      case BarcodeType.qrCode:
      case BarcodeType.url:
      case BarcodeType.email:
      case BarcodeType.phone:
      case BarcodeType.sms:
      case BarcodeType.wifi:
      case BarcodeType.location:
      case BarcodeType.contact:
      case BarcodeType.plainText:
        return 'QR_CODE';
    }
  }

  Future<void> _saveQrCode() async {
    try {
      // Using a GlobalKey for RepaintBoundary makes it easy to capture
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('barcode_generator.capture_failed'.tr());
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final typeName = _selectedType.toString().split('.').last;
      final folderPath = '${directory.path}/qrcodes';
      final filePath = '$folderPath/${typeName}_$timestamp.png';

      // Create directory if it doesn't exist
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Show success message
      AppDialogs.showSnackBar(
        context,
        message: 'barcode_generator.qr_code_saved'.tr(),
        type: SnackBarType.success,
        action: SnackBarAction(
          label: 'barcode_generator.view'.tr(),
          onPressed: () {
            _showSavedQrCode(file);
          },
          textColor: Colors.white,
        ),
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'barcode_generator.save_failed'
            .tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
    }
  }

  void _showSavedQrCode(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: AutoSizeText(
                'barcode_generator.saved_qr_code'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Image.file(
              file,
              width: 250.w,
              height: 250.w,
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AutoSizeText('barcode_generator.close'.tr()),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: AutoSizeText('common.share'.tr()),
                    onPressed: () {
                      Navigator.pop(context);
                      Share.shareXFiles([XFile(file.path)]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQrCode() async {
    try {
      // Capture QR code as image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('barcode_generator.capture_failed'.tr());
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp file for sharing
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final typeName = _selectedType.toString().split('.').last;
      final filePath = '${directory.path}/${typeName}_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'barcode_generator.generated_qr_code'.tr(),
        subject: 'barcode_generator.qr_code_subject'
            .tr(namedArgs: {'type': _selectedType.toString().split('.').last}),
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'barcode_generator.share_failed'
            .tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
    }
  }
}
