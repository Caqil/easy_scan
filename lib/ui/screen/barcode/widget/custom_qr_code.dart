import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomQRCode extends StatelessWidget {
  final String data;
  final String? title;
  final Color primaryColor;
  final Color backgroundColor;
  final double size;
  final Widget? logo;
  final BorderRadius? borderRadius;
  final bool showShadow;

  const CustomQRCode({
    Key? key,
    required this.data,
    this.title,
    this.primaryColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.size = 250,
    this.logo,
    this.borderRadius,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20.r),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                  spreadRadius: 5,
                )
              ]
            : null,
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.notoSerif(
                color: primaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
          ],
          // The actual QR code with custom styling
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: primaryColor.withOpacity(0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              embeddedImage:
                  logo != null ? null : null, // Add custom logo if provided
              embeddedImageStyle: logo != null
                  ? QrEmbeddedImageStyle(
                      size: Size(size * 0.15, size * 0.15),
                    )
                  : null,
              errorStateBuilder: (ctx, err) {
                return Center(
                  child: Text(
                    'Something went wrong!',
                    style: GoogleFonts.notoSerif(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                );
              },
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: primaryColor,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced version with gradient background and custom QR patterns
class GradientQRCode extends StatelessWidget {
  final String data;
  final String? title;
  final List<Color> gradientColors;
  final double size;
  final Widget? logo;
  final BorderRadius? borderRadius;

  const GradientQRCode({
    Key? key,
    required this.data,
    this.title,
    this.gradientColors = const [Colors.blue, Colors.purple],
    this.size = 250,
    this.logo,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
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
            SizedBox(height: 16.h),
          ],
          // QR Code with white background for better scanning
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
              data: data,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              embeddedImage:
                  logo != null ? null : null, // Handle logo embedding
              embeddedImageStyle: logo != null
                  ? QrEmbeddedImageStyle(
                      size: Size(size * 0.2, size * 0.2),
                    )
                  : null,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: gradientColors.last,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: gradientColors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sleek modern transparent QR code
class TransparentQRCode extends StatelessWidget {
  final String data;
  final String? title;
  final Color accentColor;
  final double size;
  final Widget? logo;

  const TransparentQRCode({
    Key? key,
    required this.data,
    this.title,
    this.accentColor = Colors.blue,
    this.size = 250,
    this.logo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: GoogleFonts.notoSerif(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: size,
                  backgroundColor: Colors.white,
                  foregroundColor: accentColor,
                  embeddedImage: logo != null ? null : null,
                  embeddedImageStyle: logo != null
                      ? QrEmbeddedImageStyle(
                          size: Size(size * 0.2, size * 0.2),
                        )
                      : null,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: accentColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Themed QR code based on content type
class ThemedQRCode extends StatelessWidget {
  final String data;
  final String contentType; // 'url', 'wifi', 'email', 'phone', etc.
  final double size;

  const ThemedQRCode({
    Key? key,
    required this.data,
    required this.contentType,
    this.size = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define theme settings based on content type
    final typeSettings = _getTypeSettings(contentType);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: typeSettings.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: typeSettings.gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                typeSettings.icon,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                typeSettings.title,
                style: GoogleFonts.notoSerif(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // QR Code
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
              data: data,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              embeddedImage: AssetImage(typeSettings.logoPath),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size(size * 0.2, size * 0.2),
              ),
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: typeSettings.gradientColors.last,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: typeSettings.gradientColors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper class to define settings for different content types
  _TypeSettings _getTypeSettings(String type) {
    switch (type.toLowerCase()) {
      case 'url':
        return _TypeSettings(
          gradientColors: [Colors.blue, Colors.lightBlueAccent],
          icon: Icons.language,
          title: 'Website URL',
          logoPath: 'assets/icons/web_logo.png',
        );
      case 'wifi':
        return _TypeSettings(
          gradientColors: [Colors.purple, Colors.purpleAccent],
          icon: Icons.wifi,
          title: 'WiFi Network',
          logoPath: 'assets/icons/wifi_logo.png',
        );
      case 'email':
        return _TypeSettings(
          gradientColors: [Colors.orange, Colors.amber],
          icon: Icons.email,
          title: 'Email Address',
          logoPath: 'assets/icons/email_logo.png',
        );
      case 'phone':
        return _TypeSettings(
          gradientColors: [Colors.green, Colors.lightGreen],
          icon: Icons.phone,
          title: 'Phone Number',
          logoPath: 'assets/icons/phone_logo.png',
        );
      case 'contact':
        return _TypeSettings(
          gradientColors: [Colors.indigo, Colors.indigoAccent],
          icon: Icons.contact_page,
          title: 'Contact Information',
          logoPath: 'assets/icons/contact_logo.png',
        );
      case 'sms':
        return _TypeSettings(
          gradientColors: [Colors.deepPurple, Colors.purpleAccent],
          icon: Icons.sms,
          title: 'SMS Message',
          logoPath: 'assets/icons/sms_logo.png',
        );
      case 'location':
        return _TypeSettings(
          gradientColors: [Colors.red, Colors.redAccent],
          icon: Icons.location_on,
          title: 'Location',
          logoPath: 'assets/icons/location_logo.png',
        );
      default:
        return _TypeSettings(
          gradientColors: [Colors.teal, Colors.tealAccent],
          icon: Icons.qr_code,
          title: 'QR Code',
          logoPath: 'assets/icons/qr_logo.png',
        );
    }
  }
}

// Helper class for themed QR codes
class _TypeSettings {
  final List<Color> gradientColors;
  final IconData icon;
  final String title;
  final String logoPath;

  _TypeSettings({
    required this.gradientColors,
    required this.icon,
    required this.title,
    required this.logoPath,
  });
}
