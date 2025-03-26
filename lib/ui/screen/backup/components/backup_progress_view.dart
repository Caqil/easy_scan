import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BackupProgressView extends StatelessWidget {
  final double progress;
  final String message;
  final bool isBackup;

  const BackupProgressView({
    super.key,
    required this.progress,
    required this.message,
    required this.isBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          Container(
            width: 150.w,
            height: 150.w,
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
                  // Circular progress indicator
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  // Percentage text
                  AutoSizeText(
                    '${(progress * 100).round()}%',
                    style: GoogleFonts.slabo27px(
                      fontSize: 24.adaptiveSp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Operation title
          AutoSizeText(
            isBackup
                ? 'backup.creating_backup_title'.tr()
                : 'backup.restoring_title'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 20.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Current operation message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBackup ? Icons.backup : Icons.restore,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20.adaptiveSp,
                ),
                const SizedBox(width: 8),
                AutoSizeText(
                  message,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.adaptiveSp,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Additional information
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                AutoSizeText(
                  isBackup
                      ? 'backup.progress.backup_info'.tr()
                      : 'backup.progress.restore_info'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isBackup) ...[
                  const SizedBox(height: 8),
                  AutoSizeText(
                    'backup.progress.restart_note'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.adaptiveSp,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
