import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/file_limit_service.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';

// Create a simplified provider that just returns if the user has premium
final hasPremiumProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.hasActiveSubscription();
});

// Create a provider for trial status
final hasTrialProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final hasSubscription = await subscriptionService.hasActiveSubscription();
  final hasTrialOrSubscription =
      await subscriptionService.hasActiveTrialOrSubscription();

  // If they have trial OR subscription but don't have a paid subscription, they must be on trial
  return hasTrialOrSubscription && !hasSubscription;
});

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
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    // Force subscription refresh if needed
    ref.watch(hasPremiumProvider);

    return remainingFilesAsync.when(
      data: (remainingFiles) {
        return maxFilesAsync.when(
          data: (maxFiles) {
            return _buildQuotaWidget(
              context,
              ref,
              totalFiles,
              maxFiles,
              remainingFiles,
              subscriptionStatus,
            );
          },
          loading: () => _buildLoadingWidget(),
          error: (error, stack) {
            logger.error('Error loading max files: $error\n$stack');
            return _buildErrorWidget(context);
          },
        );
      },
      loading: () => _buildLoadingWidget(),
      error: (error, stack) {
        logger.error('Error loading remaining files: $error\n$stack');
        return _buildErrorWidget(context);
      },
    );
  }

  Widget _buildQuotaWidget(
    BuildContext context,
    WidgetRef ref,
    int currentFiles,
    int maxFiles,
    int remainingFiles,
    SubscriptionStatus subscriptionStatus,
  ) {
    final theme = Theme.of(context);
    final isPremium = maxFiles == -1 || subscriptionStatus.isActive;
    final isTrialActive = subscriptionStatus.isTrialActive;
    final expirationDate = subscriptionStatus.expirationDate;

    logger.info(
        'user premium: $isPremium, trial: $isTrialActive, expiration: $expirationDate');

    return GestureDetector(
      onTap: showUpgradeButton && !isPremium
          ? () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PremiumScreen()))
          : null,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isPremium
                ? Colors.amber.withOpacity(0.5)
                : (isTrialActive
                    ? Colors.green.withOpacity(0.5)
                    : theme.dividerColor.withOpacity(0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Icon
                Icon(
                  isPremium
                      ? Icons.workspace_premium
                      : (isTrialActive
                          ? Icons.free_cancellation
                          : Icons.storage_outlined),
                  color: isPremium
                      ? Colors.amber
                      : (isTrialActive
                          ? Colors.green
                          : theme.colorScheme.primary),
                  size: 24.r,
                ),
                SizedBox(width: 12.w),

                // Status Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        _getStatusText(isPremium, isTrialActive),
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.adaptiveSp,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      if (expirationDate != null &&
                          (isTrialActive || isPremium))
                        AutoSizeText(
                          _getExpirationText(expirationDate),
                          style: GoogleFonts.slabo27px(
                            fontSize: 12.adaptiveSp,
                            color: isTrialActive &&
                                    expirationDate
                                            .difference(DateTime.now())
                                            .inDays <
                                        2
                                ? theme.colorScheme.error
                                : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Upgrade Button or Premium Badge
                if (isPremium)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: Colors.amber, size: 16.r),
                        SizedBox(width: 4.w),
                        AutoSizeText(
                          'Premium',
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.adaptiveSp,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (showUpgradeButton)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: AutoSizeText(
                      isTrialActive
                          ? 'subscription.extend'.tr()
                          : 'limit.upgrade'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.adaptiveSp,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),

            // Progress Bar for Non-Premium Users
            if (!isPremium) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
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
                  ),
                  SizedBox(width: 8.w),
                  AutoSizeText(
                    '$currentFiles / $maxFiles',
                    style: GoogleFonts.slabo27px(
                      fontSize: 12.adaptiveSp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // Remaining Files Warning
            if (!isPremium && remainingFiles <= 2) ...[
              SizedBox(height: 8.h),
              AutoSizeText(
                'limit.file_counter'.tr(
                  namedArgs: {
                    'current': currentFiles.toString(),
                    'max': maxFiles.toString()
                  },
                ),
                style: GoogleFonts.slabo27px(
                  fontSize: 12.adaptiveSp,
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(bool isPremium, bool isTrialActive) {
    if (isPremium) return 'limit.unlimited'.tr();
    if (isTrialActive) return 'onboarding.free_trial'.tr();
    return 'onboarding.start_free_trial'.tr();
  }

  String _getExpirationText(DateTime expirationDate) {
    final daysRemaining = expirationDate.difference(DateTime.now()).inDays;
    if (daysRemaining < 0) return 'subscription.expired'.tr();
    if (daysRemaining == 0) return 'subscription.expires_today'.tr();
    if (daysRemaining == 1) return 'subscription.expires_tomorrow'.tr();
    return 'subscription.expires_in'
        .tr(namedArgs: {'days': daysRemaining.toString()});
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
        style:
            GoogleFonts.slabo27px(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
