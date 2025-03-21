import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/models/document.dart';
import 'compression_widgets.dart';

class CompressionAdvancedView extends StatelessWidget {
  final Document document;
  final int originalSize;
  final int estimatedSize;
  final double qualityValue;
  final double imageQualityValue;
  final Function(double) onQualityChanged;
  final Function(double) onImageQualityChanged;

  const CompressionAdvancedView({
    super.key,
    required this.document,
    required this.originalSize,
    required this.estimatedSize,
    required this.qualityValue,
    required this.imageQualityValue,
    required this.onQualityChanged,
    required this.onImageQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentInfoCard(document: document, fileSize: originalSize),
          const SizedBox(height: 24),
          Text(
            'advanced_view.advanced_settings'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SliderWithLabel(
            label: 'compression.overall_quality'.tr(),
            value: qualityValue,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: onQualityChanged,
          ),
          const SizedBox(height: 16),
          SliderWithLabel(
            label: 'compression.image_quality'.tr(),
            value: imageQualityValue,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: onImageQualityChanged,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'advanced_view.warning'.tr(),
                    style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'simple_view.expected_results'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CompressionStatsCard(
            originalSize: originalSize,
            estimatedSize: estimatedSize,
          ),
        ],
      ),
    );
  }
}
