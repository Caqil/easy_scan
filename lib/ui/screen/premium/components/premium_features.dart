import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumFeatures extends StatelessWidget {
  const PremiumFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.lock_open_outlined,
        'title': 'Premium PDF Security',
        'description': 'Password-protect important documents'
      },
      {
        'icon': Icons.text_fields_outlined,
        'title': 'Advanced OCR',
        'description': 'Extract text from images and PDFs'
      },
      {
        'icon': Icons.cloud_upload_outlined,
        'title': 'Cloud Sync',
        'description': 'Backup and access documents anywhere'
      },
      {
        'icon': Icons.compress,
        'title': 'Premium Compression',
        'description': 'Reduce file size without quality loss'
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16.r),
            child: AutoSizeText(
              'Premium Features',
              style: GoogleFonts.slabo27px(
                fontSize: 18.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 12.r),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: Colors.amber,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            feature['title'] as String,
                            style: GoogleFonts.slabo27px(
                              fontSize: 14.adaptiveSp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AutoSizeText(
                            feature['description'] as String,
                            style: GoogleFonts.slabo27px(
                              fontSize: 12.adaptiveSp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
