import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

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
              fontSize: 16.sp,
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
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  FileUtils.getCompressionLevelDescription(compressionLevel)!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AutoSizeText(
            'simple_view.expected_results'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CompressionStatsCard(
            originalSize: originalSize,
            estimatedSize: estimatedSize,
          ),
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
    bool isAlwaysAvailable,
    WidgetRef ref,
    SubscriptionStatus subscriptionStatus,
  ) {
    final bool isEnabled = isAlwaysAvailable;
    final bool isSelected = compressionLevel == level;

    return InkWell(
      onTap: () {
        if (isEnabled) {
          onLevelChanged(level);
        } else {
          _showPremiumDialog(context);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
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
                      fontSize: 14.sp,
                    ),
                  ),
                  if (!isAlwaysAvailable) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ],
              ),
            ],
          ),
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

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('premium_required.title'.tr()),
        content: Text(
          'subscription.subtitle'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          OutlinedButton(
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
