import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A card showing a scanned document page
class DocumentCard extends StatelessWidget {
  final File page;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const DocumentCard({
    super.key,
    required this.page,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPageImage(),
                _buildGradientOverlay(),
                _buildPageNumberIndicator(),
                _buildDeleteButton(context),
                _buildEditIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageImage() {
    return Hero(
      tag: 'scan_page_$index',
      child: Image.file(
        page,
        fit: BoxFit.cover,
        cacheHeight: 500,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.4),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumberIndicator() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AutoSizeText(
          '${index + 1}',
          style: GoogleFonts.slabo27px(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.mediumImpact();
              onRemove();
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditIndicator() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionIndicator(Icons.touch_app, 'tap_to_edit'.tr()),
            _buildActionIndicator(Icons.drag_indicator, 'drag'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIndicator(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 14,
        ),
        const SizedBox(width: 4),
        AutoSizeText(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
