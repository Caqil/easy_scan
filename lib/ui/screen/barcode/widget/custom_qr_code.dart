import 'dart:ui';
import 'package:easy_localization/easy_localization.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
    super.key,
    required this.data,
    this.title,
    this.primaryColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.size = 250,
    this.logo,
    this.borderRadius,
    this.showShadow = true,
  });

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
            AutoSizeText(
              title!.tr(), // Apply translation if title is a key
              style: GoogleFonts.slabo27px(
                color: primaryColor,
                fontSize: 16.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
          ],
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
              embeddedImage: logo != null ? null : null,
              embeddedImageStyle: logo != null
                  ? QrEmbeddedImageStyle(
                      size: Size(size * 0.15, size * 0.15),
                    )
                  : null,
              errorStateBuilder: (ctx, err) {
                return Center(
                  child: AutoSizeText(
                    'qr_code.error'.tr(), // Use translation key
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                      fontSize: 14.adaptiveSp,
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

class GradientQRCode extends StatelessWidget {
  final String data;
  final String? title;
  final List<Color> gradientColors;
  final double size;
  final Widget? logo;
  final BorderRadius? borderRadius;

  const GradientQRCode({
    super.key,
    required this.data,
    this.title,
    this.gradientColors = const [Colors.blue, Colors.purple],
    this.size = 250,
    this.logo,
    this.borderRadius,
  });

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
            AutoSizeText(
              title!.tr(), // Apply translation if title is a key
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
            SizedBox(height: 16.h),
          ],
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
              embeddedImage: logo != null ? null : null,
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

class TransparentQRCode extends StatelessWidget {
  final String data;
  final String? title;
  final Color accentColor;
  final double size;
  final Widget? logo;

  const TransparentQRCode({
    super.key,
    required this.data,
    this.title,
    this.accentColor = Colors.blue,
    this.size = 250,
    this.logo,
  });

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
                AutoSizeText(
                  title!.tr(), // Apply translation if title is a key
                  style: GoogleFonts.slabo27px(
                    color: Colors.white,
                    fontSize: 16.adaptiveSp,
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

class ThemedQRCode extends StatelessWidget {
  final String data;
  final String contentType;
  final double size;

  const ThemedQRCode({
    super.key,
    required this.data,
    required this.contentType,
    this.size = 250,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                typeSettings.icon,
                color: Colors.white,
                size: 20.adaptiveSp,
              ),
              SizedBox(width: 8.w),
              AutoSizeText(
                typeSettings.title.tr(), // Apply translation to title
                style: GoogleFonts.slabo27px(
                  color: Colors.white,
                  fontSize: 16.adaptiveSp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
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

  _TypeSettings _getTypeSettings(String type) {
    switch (type.toLowerCase()) {
      case 'url':
        return _TypeSettings(
          gradientColors: [Colors.blue, Colors.lightBlueAccent],
          icon: Icons.language,
          title: 'qr_code.website_url', // Use translation key
          logoPath: 'assets/icons/web_logo.png',
        );
      case 'wifi':
        return _TypeSettings(
          gradientColors: [Colors.purple, Colors.purpleAccent],
          icon: Icons.wifi,
          title: 'qr_code.wifi_network', // Use translation key
          logoPath: 'assets/icons/wifi_logo.png',
        );
      case 'email':
        return _TypeSettings(
          gradientColors: [Colors.orange, Colors.amber],
          icon: Icons.email,
          title: 'qr_code.email_address', // Use translation key
          logoPath: 'assets/icons/email_logo.png',
        );
      case 'phone':
        return _TypeSettings(
          gradientColors: [Colors.green, Colors.lightGreen],
          icon: Icons.phone,
          title: 'qr_code.phone_number', // Use translation key
          logoPath: 'assets/icons/phone_logo.png',
        );
      case 'contact':
        return _TypeSettings(
          gradientColors: [Colors.indigo, Colors.indigoAccent],
          icon: Icons.contact_page,
          title: 'qr_code.contact_information', // Use translation key
          logoPath: 'assets/icons/contact_logo.png',
        );
      case 'sms':
        return _TypeSettings(
          gradientColors: [Colors.deepPurple, Colors.purpleAccent],
          icon: Icons.sms,
          title: 'qr_code.sms_message', // Use translation key
          logoPath: 'assets/icons/sms_logo.png',
        );
      case 'location':
        return _TypeSettings(
          gradientColors: [Colors.red, Colors.redAccent],
          icon: Icons.location_on,
          title: 'qr_code.location', // Use translation key
          logoPath: 'assets/icons/location_logo.png',
        );
      default:
        return _TypeSettings(
          gradientColors: [Colors.teal, Colors.tealAccent],
          icon: Icons.qr_code,
          title: 'qr_code.qr_code', // Use translation key
          logoPath: 'assets/icons/qr_logo.png',
        );
    }
  }
}

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
