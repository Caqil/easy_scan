// lib/ui/screen/barcode/barcode_generator_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
        title: Text(
          'Generate Barcode',
          style: GoogleFonts.notoSerif(
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
                    label: Text(
                        _isGenerating ? 'Generating...' : 'Generate Barcode'),
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
        Text(
          'Barcode Type',
          style: GoogleFonts.notoSerif(
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
                _buildImprovedTypeOption(
                    BarcodeType.qrCode, 'QR Code', Icons.qr_code_2),
                _buildImprovedTypeOption(
                    BarcodeType.url, 'URL', Icons.language),
                _buildImprovedTypeOption(
                    BarcodeType.email, 'Email', Icons.email),
                _buildImprovedTypeOption(
                    BarcodeType.phone, 'Phone', Icons.phone),
                _buildImprovedTypeOption(BarcodeType.sms, 'SMS', Icons.sms),
                _buildImprovedTypeOption(BarcodeType.wifi, 'WiFi', Icons.wifi),
                _buildImprovedTypeOption(
                    BarcodeType.location, 'Location', Icons.location_on),
                _buildImprovedTypeOption(
                    BarcodeType.contact, 'Contact', Icons.contact_page),
                _buildImprovedTypeOption(
                    BarcodeType.plainText, 'Text', Icons.text_fields),
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
            Text(
              label,
              style: GoogleFonts.notoSerif(
                color: isSelected ? accentColor : Colors.grey.shade700,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      default:
        return Colors.grey;
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
          Text(
            'Enter Details',
            style: GoogleFonts.notoSerif(
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
          label: 'Content',
          hintText: 'Enter any text for your QR code',
          icon: Icons.text_fields,
          maxLines: 3,
        );

      case BarcodeType.url:
        return _buildImprovedTextField(
          controller: _contentController,
          label: 'Website URL',
          hintText: 'https://example.com',
          icon: Icons.link,
          keyboardType: TextInputType.url,
        );

      case BarcodeType.email:
        return Column(
          children: [
            _buildImprovedTextField(
              controller: _contentController,
              label: 'Email Address',
              hintText: 'email@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _emailSubjectController,
              label: 'Subject (Optional)',
              hintText: 'Enter email subject',
              icon: Icons.subject,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _emailBodyController,
              label: 'Body (Optional)',
              hintText: 'Enter email body',
              icon: Icons.message,
              maxLines: 3,
            ),
          ],
        );

      case BarcodeType.phone:
        return _buildImprovedTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hintText: '+1 234 567 8900',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        );

      case BarcodeType.sms:
        return Column(
          children: [
            _buildImprovedTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: '+1 234 567 8900',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _smsBodyController,
              label: 'Message (Optional)',
              hintText: 'Enter message',
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
              label: 'WiFi Network Name (SSID)',
              hintText: 'Enter WiFi name',
              icon: Icons.wifi,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _wifiPasswordController,
              label: 'Password',
              hintText: 'Enter WiFi password',
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
                title: Text(
                  'Security',
                  style: GoogleFonts.notoSerif(
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Text(
                  _wifiEncryption ? 'WPA/WPA2' : 'None (Open Network)',
                  style: GoogleFonts.notoSerif(
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
                    label: 'Latitude',
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
                    label: 'Longitude',
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
              label: 'Location Name (Optional)',
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
              label: 'Full Name',
              hintText: 'John Doe',
              icon: Icons.person,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: '+1 234 567 8900',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),
            _buildImprovedTextField(
              controller: _emailSubjectController,
              label: 'Email (Optional)',
              hintText: 'email@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        );

      case BarcodeType.plainText:
        return _buildImprovedTextField(
          controller: _contentController,
          label: 'Text',
          hintText: 'Enter any text',
          icon: Icons.text_fields,
          maxLines: 5,
        );

      default:
        return _buildImprovedTextField(
          controller: _contentController,
          label: 'Content',
          hintText: 'Enter content',
          icon: Icons.text_fields,
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
            Text(
              label,
              style: GoogleFonts.notoSerif(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
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
          style: GoogleFonts.notoSerif(
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  // New method for improved barcode display
  Widget _buildImprovedBarcodeDisplay() {
    final Color accentColor = _getColorForType(_selectedType);

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
        children: [
          // Barcode header
          Row(
            children: [
              Icon(
                Icons.qr_code,
                color: accentColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Generated Barcode',
                style: GoogleFonts.notoSerif(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Barcode container
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: RepaintBoundary(
              key: _qrKey,
              child: QrImageView(
                data: _generatedData,
                version: QrVersions.auto,
                size: 200.w,
                backgroundColor: Colors.white,
                errorStateBuilder: (ctx, err) {
                  return Center(
                    child: Text(
                      'Error generating QR code',
                      style: GoogleFonts.notoSerif(
                        color: Colors.red,
                      ),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                embeddedImage: _getLogoForType(),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(40.w, 40.w),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Data display
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encoded Data:',
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _generatedData,
                  style: GoogleFonts.notoSerif(
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
                label: 'Save',
                color: accentColor,
                onTap: _saveQrCode,
              ),
              _buildActionButton(
                icon: Icons.copy,
                label: 'Copy',
                color: Colors.grey.shade700,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _generatedData));
                  AppDialogs.showSnackBar(
                    context,
                    message: 'Data copied to clipboard',
                    type: SnackBarType.success,
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                color: Colors.blue,
                onTap: () {
                  // Implement share functionality
                  _shareQrCode();
                },
              ),
            ],
          ),
        ],
      ),
    );
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
            Text(
              label,
              style: GoogleFonts.notoSerif(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get embedded logo for QR code
  AssetImage? _getLogoForType() {
    // In a real implementation, you'd return different logos based on type
    // For example, for WiFi you might use a wifi icon, for email an envelope, etc.
    // Since assets depend on your project structure, returning null for now
    return null;
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
          errorMessage = 'Please enter some content';
        }
        break;

      case BarcodeType.url:
        data = _contentController.text.trim();
        if (data.isEmpty) {
          isValid = false;
          errorMessage = 'Please enter a URL';
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
          errorMessage = 'Please enter an email address';
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
          errorMessage = 'Please enter a phone number';
        } else {
          data = 'tel:$phone';
        }
        break;

      case BarcodeType.sms:
        final phone = _phoneController.text.trim();
        final message = _smsBodyController.text.trim();

        if (phone.isEmpty) {
          isValid = false;
          errorMessage = 'Please enter a phone number';
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
          errorMessage = 'Please enter a WiFi network name';
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
          errorMessage = 'Please enter latitude and longitude';
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
            errorMessage = 'Invalid latitude or longitude format';
          }
        }
        break;

      case BarcodeType.contact:
        final name = _contentController.text.trim();
        final phone = _phoneController.text.trim();
        final email = _emailSubjectController.text.trim();

        if (name.isEmpty) {
          isValid = false;
          errorMessage = 'Please enter a name';
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
    if (mounted) {
      AppDialogs.showSnackBar(
        context,
        message: 'Barcode saved to history',
        type: SnackBarType.success,
      );
    }
  }

  String _getBarcodeFormat() {
    // Return an appropriate format based on barcode type
    switch (_selectedType) {
      case BarcodeType.qrCode:
        return 'QR_CODE';
      case BarcodeType.url:
        return 'QR_CODE';
      case BarcodeType.email:
        return 'QR_CODE';
      case BarcodeType.phone:
        return 'QR_CODE';
      case BarcodeType.sms:
        return 'QR_CODE';
      case BarcodeType.wifi:
        return 'QR_CODE';
      case BarcodeType.location:
        return 'QR_CODE';
      case BarcodeType.contact:
        return 'QR_CODE';
      case BarcodeType.plainText:
        return 'QR_CODE';
      default:
        return 'QR_CODE';
    }
  }

  Future<void> _saveQrCode() async {
    try {
      // Capture the QR code as an image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to capture QR code');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final typeName = _selectedType.toString().split('.').last;
      final filePath = '${directory.path}/qrcodes/${typeName}_$timestamp.png';

      // Create directory if it doesn't exist
      final dir = Directory('${directory.path}/qrcodes');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Show success message
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'QR code saved successfully',
          type: SnackBarType.success,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Show the image in a dialog or navigate to a viewer
              _showSavedQrCode(file);
            },
          ),
        );
      }
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Failed to save QR code: $e',
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
              child: Text(
                'Saved QR Code',
                style: GoogleFonts.notoSerif(
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
                    child: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
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
      // First capture QR code as image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to capture QR code');
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
        text: 'Generated QR Code: $_generatedData',
        subject: 'QR Code - ${_selectedType.toString().split('.').last}',
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Failed to share QR code: $e',
        type: SnackBarType.error,
      );
    }
  }
}
