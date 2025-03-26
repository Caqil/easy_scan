import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'compression_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper function to check premium outside of widgets
Future<bool> checkPremiumAccess(WidgetRef ref) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.hasActiveSubscription();
}

// Helper class for premium-related actions
class PremiumFeatureHandler {
  static Future<bool> canUseFeature(
    BuildContext context,
    WidgetRef ref, {
    bool showDialog = true,
  }) async {
    final subscriptionStatus = ref.read(subscriptionStatusProvider);

    // Quick check using status provider first (no API call)
    if (subscriptionStatus.hasFullAccess) {
      return true;
    }

    // Double-check with the service if the state might be outdated
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final hasAccess = await subscriptionService.hasActiveTrialOrSubscription();

    if (!hasAccess && showDialog) {
      _showPremiumDialog(context);
    }

    return hasAccess;
  }

  static void _showPremiumDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('ocr.premium_required.title'.tr()),
        content: Text(
          'subscription.subtitle'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            child: Text('Upgrade'.tr()),
          ),
        ],
      ),
    );
  }
}

class CompressionSimpleView extends ConsumerWidget {
  final Document document;
  final int originalSize;
  final int estimatedSize;
  final CompressionLevel compressionLevel;
  final Function(CompressionLevel) onLevelChanged;

  const CompressionSimpleView({
    super.key,
    required this.document,
    required this.originalSize,
    required this.estimatedSize,
    required this.compressionLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using subscriptionStatus from provider to avoid API calls on each build
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final premiumStatus = ref.watch(isPremiumProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentInfoCard(document: document, fileSize: originalSize),
          const SizedBox(height: 24),
          AutoSizeText(
            'simple_view.compression_level'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCompressionLevelSelector(context, ref, subscriptionStatus),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryContainer,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  FileUtils.getCompressionLevelTitle(compressionLevel)!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.adaptiveSp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  FileUtils.getCompressionLevelDescription(compressionLevel)!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AutoSizeText(
            'simple_view.expected_results'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CompressionStatsCard(
            originalSize: originalSize,
            estimatedSize: estimatedSize,
          ),
          premiumStatus.when(
            data: (isPremium) {
              if (!isPremium) {
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildPremiumBanner(context),
                  ],
                );
              } else {
                return const SizedBox.shrink(); // Nothing if premium
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Text('Error checking subscription: $error'),
          )
        ],
      ),
    );
  }

  Widget _buildCompressionLevelSelector(
    BuildContext context,
    WidgetRef ref,
    SubscriptionStatus subscriptionStatus,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompressionOption(
                context,
                CompressionLevel.low,
                true, // Always unlocked
                ref,
                subscriptionStatus,
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                context,
                CompressionLevel.medium,
                subscriptionStatus.hasFullAccess, // Unlocked only for premium
                ref,
                subscriptionStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompressionOption(
                context,
                CompressionLevel.high,
                subscriptionStatus.hasFullAccess, // Unlocked only for premium
                ref,
                subscriptionStatus,
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                context,
                CompressionLevel.maximum,
                subscriptionStatus.hasFullAccess, // Unlocked only for premium
                ref,
                subscriptionStatus,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompressionOption(
    BuildContext context,
    CompressionLevel level,
    bool isAvailable,
    WidgetRef ref,
    SubscriptionStatus subscriptionStatus,
  ) {
    final bool isSelected = compressionLevel == level;

    return InkWell(
      onTap: () async {
        // Always check subscription status directly for latest status
        final subscriptionService = ref.read(subscriptionServiceProvider);
        final hasAccess = await subscriptionService.hasActiveSubscription();

        if (level == CompressionLevel.low || hasAccess) {
          // Low level is always available, others require premium access
          onLevelChanged(level);
        } else {
          // Show premium dialog if no access
          await PremiumFeatureHandler.canUseFeature(context, ref);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Opacity(
            opacity: isAvailable ? 1.0 : 0.7,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.compress,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutoSizeText(
                        _getLevelName(level),
                        style: GoogleFonts.slabo27px(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w700,
                          fontSize: 14.adaptiveSp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Premium lock indicator
          if (!isAvailable)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    'limit.file_limit_reached.upgrade'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.adaptiveSp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AutoSizeText(
                    'limit.file_limit_reached.upgrade_prompt'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 12.adaptiveSp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Upgrade'.tr(),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelName(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 'compression_levels.low'.tr();
      case CompressionLevel.medium:
        return 'compression_levels.medium'.tr();
      case CompressionLevel.high:
        return 'compression_levels.high'.tr();
      case CompressionLevel.maximum:
        return 'compression_levels.maximum'.tr();
    }
  }
}
