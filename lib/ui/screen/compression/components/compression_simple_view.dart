import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'compression_widgets.dart';

class CompressionSimpleView extends StatelessWidget {
  final Document document;
  final int originalSize;
  final int estimatedSize;
  final CompressionLevel compressionLevel;
  final Function(CompressionLevel) onLevelChanged;

  const CompressionSimpleView({
    super.key,
    required this.document,
    required this.originalSize,
    required this.estimatedSize,
    required this.compressionLevel,
    required this.onLevelChanged,
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
          AutoSizeText(
            'simple_view.compression_level'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CompressionLevelSelector(
            selectedLevel: compressionLevel,
            onLevelChanged: onLevelChanged,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryContainer,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  FileUtils.getCompressionLevelTitle()!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  FileUtils.getCompressionLevelDescription()!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AutoSizeText(
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
