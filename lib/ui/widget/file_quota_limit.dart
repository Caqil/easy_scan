import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/services/file_limit_service.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';

/// A widget to display the user's file quota status
class FileQuotaStatusWidget extends ConsumerWidget {
  final bool showUpgradeButton;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const FileQuotaStatusWidget({
    super.key,
    this.showUpgradeButton = true,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingFilesAsync = ref.watch(remainingFilesProvider);
    final maxFilesAsync = ref.watch(maxAllowedFilesProvider);
    final totalFiles = ref.watch(totalFilesProvider);

    return remainingFilesAsync.when(
      data: (remainingFiles) {
        return maxFilesAsync.when(
          data: (maxFiles) {
            return _buildQuotaWidget(
                context, totalFiles, maxFiles, remainingFiles);
          },
          loading: () => _buildLoadingWidget(),
          error: (_, __) => _buildErrorWidget(context),
        );
      },
      loading: () => _buildLoadingWidget(),
      error: (_, __) => _buildErrorWidget(context),
    );
  }

  Widget _buildQuotaWidget(BuildContext context, int currentFiles, int maxFiles,
      int remainingFiles) {
    final theme = Theme.of(context);
    final isPremium = maxFiles == -1;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Icon and title
              Icon(
                isPremium ? Icons.workspace_premium : Icons.storage_outlined,
                color: isPremium ? Colors.amber : theme.colorScheme.primary,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              AutoSizeText(
                isPremium
                    ? 'limit.unlimited'.tr()
                    : 'limit.file_counter'.tr(
                        namedArgs: {
                          'current': '$currentFiles',
                          'max': '$maxFiles'
                        },
                      ),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              Spacer(),
              if (showUpgradeButton && !isPremium)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: AutoSizeText(
                    'limit.upgrade'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ],
          ),
          if (!isPremium) ...[
            SizedBox(height: 8.h),
            // Progress bar
            LinearProgressIndicator(
              value: maxFiles > 0 ? currentFiles / maxFiles : 0,
              backgroundColor:
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
              color: currentFiles >= maxFiles
                  ? theme.colorScheme.error
                  : (currentFiles > maxFiles * 0.8
                      ? Colors.amber
                      : theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: padding,
      child: Center(
        child: SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: padding,
      child: AutoSizeText(
        'Error loading quota information',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
