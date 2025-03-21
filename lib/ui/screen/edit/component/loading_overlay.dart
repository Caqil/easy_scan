import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay that displays during processing operations
class LoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final ColorScheme colorScheme;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            AutoSizeText(
              'processing'.tr(),
              style: GoogleFonts.slabo27px(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
