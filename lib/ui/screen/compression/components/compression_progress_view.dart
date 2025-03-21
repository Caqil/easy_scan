import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CompressionProgressView extends StatelessWidget {
  final double progress;
  final String statusMessage;

  const CompressionProgressView({
    super.key,
    required this.progress,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 8,
                  ),
                  AutoSizeText(
                    '${(progress * 100).round()}%',
                    style: GoogleFonts.slabo27px(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AutoSizeText(
            'compressing_view.compressing_pdf'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'compressing_view.using_cloud_api'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compress,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                AutoSizeText(
                  statusMessage,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
