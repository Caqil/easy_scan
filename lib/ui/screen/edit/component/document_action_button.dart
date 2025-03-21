import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget that displays a row of document action buttons
class DocumentActionButtons extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isPasswordProtected;
  final Function() onPasswordTap;
  final Function() onSignatureTap;
  final Function() onWatermarkTap;
  final Function() onExtractTextTap;
  final Function() onFindTextTap;
  final Function() onShareTap;

  const DocumentActionButtons({
    super.key,
    required this.colorScheme,
    this.isPasswordProtected = false,
    required this.onPasswordTap,
    required this.onSignatureTap,
    required this.onWatermarkTap,
    required this.onExtractTextTap,
    required this.onFindTextTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80.h,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: isPasswordProtected ? Icons.lock : Icons.lock_outline,
              label: isPasswordProtected
                  ? 'document.password_protected'.tr()
                  : 'pdf.password'.tr(),
              isActive: isPasswordProtected,
              onTap: onPasswordTap,
            ),
            _buildActionButton(
              icon: Icons.draw_outlined,
              label: 'document_actions.signature'.tr(),
              onTap: onSignatureTap,
            ),
            _buildActionButton(
              icon: Icons.water,
              label: 'document_actions.watermark'.tr(),
              onTap: onWatermarkTap,
            ),
            _buildActionButton(
              icon: Icons.text_snippet_outlined,
              label: 'document_actions.extract_text'.tr(),
              onTap: onExtractTextTap,
            ),
            _buildActionButton(
              icon: Icons.search_outlined,
              label: 'document_actions.find_text'.tr(),
              onTap: onFindTextTap,
            ),
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'common.share'.tr(),
              onTap: onShareTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Function() onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withOpacity(0.2)
                      : colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 1.h),
              AutoSizeText(
                label,
                style: GoogleFonts.slabo27px(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 8.sp,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
