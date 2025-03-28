import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/services/file_limit_service.dart';

class PremiumUpgradeUtils {
  static const _animationDuration = Duration(milliseconds: 300);
  static const _buttonBounceDuration = Duration(milliseconds: 150);

  /// Displays a premium upgrade dialog with smooth animations
  static Future<void> showFileLimitReachedDialog(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: _animationDuration,
      pageBuilder: (context, animation, secondaryAnimation) => ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Semantics(
            label: 'File limit reached title',
            child: Text(
              'limit.file_limit_reached.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          content: _buildDialogContent(context),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: _buildDialogActions(context),
        ),
      ),
    ).then((_) => null); // Explicitly discard the return value
  }

  static Widget _buildDialogContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Locked feature icon',
            child: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.error,
              size: 60,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'limit.file_limit_reached.message'.tr(namedArgs: {'limit': '5'}),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: 12),
          Text(
            'limit.file_limit_reached.upgrade_prompt'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildDialogActions(BuildContext context) {
    return [
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        child: Semantics(
          label: 'Upgrade to premium button',
          child: Text(
            'limit.file_limit_reached.upgrade'.tr(),
            style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.bold, fontSize: 14.adaptiveSp),
          ),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Semantics(
          label: 'Cancel button',
          child: Text(
            'common.cancel'.tr(),
            style: GoogleFonts.slabo27px(
                color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ),
    ];
  }

  /// Shows a refined snackbar with remaining files info
  static void showRemainingFilesMessage(
      BuildContext context, int remainingFiles) {
    if (!context.mounted) return;
    AppDialogs.showSnackBar(
      context,
      message: 'limit.remaining_files'.tr(
        namedArgs: {
          'count': remainingFiles.toString(),
          'plural': remainingFiles == 1 ? '' : 's'
        },
      ),
      type: SnackBarType.warning,
      duration: Duration(seconds: 4),
      action: SnackBarAction(
        label: 'limit.upgrade'.tr(),
        textColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
          }
        },
      ),
    );
  }

  /// Validates file action with robust error handling
  static Future<bool> canPerformFileAction(
    BuildContext context,
    WidgetRef ref, {
    bool showDialog = true,
  }) async {
    try {
      final hasReachedLimitAsync = ref.read(hasReachedFileLimitProvider);
      final hasReachedLimit = hasReachedLimitAsync.value ?? false;

      if (hasReachedLimit) {
        if (showDialog && context.mounted) {
          await showFileLimitReachedDialog(context);
        }
        return false;
      }

      final remainingFilesAsync = ref.read(remainingFilesProvider);
      final remainingFiles = remainingFilesAsync.value ?? 0;

      if (remainingFiles <= 2 && remainingFiles > 0 && context.mounted) {
        showRemainingFilesMessage(context, remainingFiles);
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'An error occurred while checking file limits',
          type: SnackBarType.error,
        );
      }
      return false;
    }
  }
}
