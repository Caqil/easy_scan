import 'dart:io';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/share_limit_service.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class DocumentShareService {
  final ShareLimitService _shareLimitService = ShareLimitService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  /// Share a document with error handling and premium limit check
  Future<void> shareDocument(
    BuildContext context,
    WidgetRef ref,
    Document document, {
    String? subject,
  }) async {
    try {
      // Check if user has premium subscription
      final hasSubscription =
          await _subscriptionService.hasActiveTrialOrSubscription();

      // Check share limit for free users
      final hasReachedLimit = await _shareLimitService.hasReachedShareLimit();

      if (!hasSubscription && hasReachedLimit) {
        // Show premium upgrade dialog
        _showUpgradeToPremiumDialog(context);
        return;
      }

      // Proceed with sharing
      final File file = File(document.pdfPath);
      if (await file.exists()) {
        // Increment share count for free users
        if (!hasSubscription) {
          await _shareLimitService.incrementShareCount();

          // Get remaining shares
          final remainingShares = await _shareLimitService.getRemainingShares();

          // Show remaining shares toast if close to limit
          if (remainingShares <= 2 && remainingShares > 0) {
            _showRemainingSharesMessage(context, remainingShares);
          }
        }

        // Share the file
        await Share.shareXFiles(
          [XFile(document.pdfPath)],
          subject: subject ?? document.name,
        );
      } else {
        throw Exception('share.file_not_found'.tr());
      }
    } catch (e) {
      logger.error('Error sharing document: $e');
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'share.error'.tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Share multiple files
  Future<void> shareMultipleDocuments(
    BuildContext context,
    WidgetRef ref,
    List<Document> documents, {
    String? subject,
  }) async {
    try {
      // Check if user has premium subscription
      final hasSubscription =
          await _subscriptionService.hasActiveTrialOrSubscription();

      // Check share limit for free users
      final hasReachedLimit = await _shareLimitService.hasReachedShareLimit();

      if (!hasSubscription && hasReachedLimit) {
        // Show premium upgrade dialog
        _showUpgradeToPremiumDialog(context);
        return;
      }

      // Proceed with sharing
      final List<XFile> files = [];

      for (var document in documents) {
        final File file = File(document.pdfPath);
        if (await file.exists()) {
          files.add(XFile(document.pdfPath));
        }
      }

      if (files.isNotEmpty) {
        // Increment share count for free users
        if (!hasSubscription) {
          await _shareLimitService.incrementShareCount();

          // Get remaining shares
          final remainingShares = await _shareLimitService.getRemainingShares();

          // Show remaining shares toast if close to limit
          if (remainingShares <= 2 && remainingShares > 0) {
            _showRemainingSharesMessage(context, remainingShares);
          }
        }

        // Share the files
        await Share.shareXFiles(
          files,
          subject: subject ?? 'shared_documents'.tr(),
        );
      } else {
        throw Exception('share.no_valid_files'.tr());
      }
    } catch (e) {
      logger.error('Error sharing multiple documents: $e');
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'share.error'.tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Show dialog to upgrade to premium when share limit is reached
  void _showUpgradeToPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('share.limit_reached.title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.amber,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'share.limit_reached.message'.tr(
                namedArgs: {'limit': '5'},
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'share.limit_reached.upgrade_prompt'.tr(),
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
            child: Text('share.limit_reached.upgrade'.tr()),
          ),
        ],
      ),
    );
  }

  /// Show message about remaining shares
  void _showRemainingSharesMessage(BuildContext context, int remainingShares) {
    AppDialogs.showSnackBar(
      context,
      message: 'share.remaining'.tr(
        namedArgs: {
          'count': remainingShares.toString(),
          'plural': remainingShares == 1 ? '' : 's'
        },
      ),
      type: SnackBarType.warning,
      duration: Duration(seconds: 4),
      action: SnackBarAction(
        label: 'share.upgrade'.tr(),
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
}

/// Provider for document share service
final documentShareServiceProvider = Provider<DocumentShareService>((ref) {
  return DocumentShareService();
});
