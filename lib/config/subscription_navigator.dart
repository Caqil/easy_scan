import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:scanpro/ui/screen/premium/trial_explanation_sheet.dart';

class SubscriptionNavigator {
  /// Navigate to the premium screen
  static Future<void> openPremiumScreen(BuildContext context) async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PremiumScreen(),
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      logger.error('Error opening premium screen: $e');
    }
  }

  /// Show the trial explanation sheet
  static Future<void> showTrialExplanation(BuildContext context,
      {VoidCallback? onComplete}) async {
    try {
      await TrialExplanationSheet.show(context, onComplete: onComplete);
    } catch (e) {
      logger.error('Error showing trial explanation: $e');
    }
  }

  /// Show a subscription required dialog
  static Future<bool> showSubscriptionRequiredDialog(
    BuildContext context, {
    String title = 'Premium Feature',
    String message = 'This feature requires a premium subscription to use.',
    String actionText = 'Upgrade',
    String cancelText = 'Maybe Later',
  }) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(actionText),
            ),
          ],
        ),
      );

      if (result == true) {
        await openPremiumScreen(context);
        return true;
      }

      return false;
    } catch (e) {
      logger.error('Error showing subscription required dialog: $e');
      return false;
    }
  }

  /// Check if a feature is available and show upgrade UI if needed
  static Future<bool> checkFeatureAccess(
    BuildContext context,
    WidgetRef ref, {
    required String featureKey,
    String title = 'Premium Feature',
    String message = 'This feature requires a premium subscription to use.',
  }) async {
    // Check if user has access (could be premium or trial)
    final subscriptionStatus = ref.read(subscriptionStatusProvider);

    // If user has full access, return true
    if (subscriptionStatus.hasFullAccess) {
      return true;
    }

    // Otherwise, show the subscription required dialog
    final shouldUpgrade = await showSubscriptionRequiredDialog(
      context,
      title: title,
      message: message,
    );

    // If the user chose to upgrade and now has access, return true
    if (shouldUpgrade) {
      // Refresh the status
      final updatedStatus = ref.read(subscriptionStatusProvider);
      return updatedStatus.hasFullAccess;
    }

    return false;
  }
}
