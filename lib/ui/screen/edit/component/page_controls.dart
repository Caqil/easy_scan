import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

/// Controls for document pages including counter and delete button
class PageControls extends StatelessWidget {
  final int currentPageIndex;
  final int pageCount;
  final Function(int) onDeletePage;

  const PageControls({
    super.key,
    required this.currentPageIndex,
    required this.pageCount,
    required this.onDeletePage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDeleteButton(),
          _buildPageCounter(),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () => onDeletePage(currentPageIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            AutoSizeText(
              'common.delete'.tr(),
              style: GoogleFonts.slabo27px(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10.adaptiveSp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.copy,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          AutoSizeText(
            '${currentPageIndex + 1} / $pageCount',
            style: GoogleFonts.slabo27px(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
