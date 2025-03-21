import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/services/file_limit_service.dart';

class PremiumUpgradeUtils {
  /// Show dialog to upgrade to premium when file limit is reached
  static Future<void> showFileLimitReachedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('limit.file_limit_reached.title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'limit.file_limit_reached.message'.tr(
                namedArgs: {'limit': '5'},
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'limit.file_limit_reached.upgrade_prompt'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('limit.file_limit_reached.upgrade'.tr()),
          ),
        ],
      ),
    );
  }

  /// Show message about remaining files
  static void showRemainingFilesMessage(
    BuildContext context,
    int remainingFiles,
  ) {
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
        onPressed: () {
          // Navigate to premium screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PremiumScreen(),
            ),
          );
        },
      ),
    );
  }

  /// Check if action is allowed based on file limit, and show appropriate dialogs
  static Future<bool> canPerformFileAction(BuildContext context, WidgetRef ref,
      {bool showDialog = true}) async {
    // Check if user has reached limit using the providers
    final hasReachedLimitAsync = ref.read(hasReachedFileLimitProvider);

    // Use the future to get the result
    final hasReachedLimit = await hasReachedLimitAsync.value;

    if (hasReachedLimit ?? false) {
      if (showDialog && context.mounted) {
        await showFileLimitReachedDialog(context);
      }
      return false;
    }

    // Get remaining files if close to limit
    final remainingFilesAsync = ref.read(remainingFilesProvider);
    final remainingFiles = await remainingFilesAsync.value;

    if ((remainingFiles ?? 0) <= 2 &&
        (remainingFiles ?? 0) > 0 &&
        context.mounted) {
      showRemainingFilesMessage(context, remainingFiles ?? 0);
    }

    return true;
  }
}
