import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:lottie/lottie.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scanpro/utils/purchase_utils.dart';

class SubscriptionStep extends ConsumerStatefulWidget {
  final VoidCallback onSubscriptionHandled;

  const SubscriptionStep({
    Key? key,
    required this.onSubscriptionHandled,
  }) : super(key: key);

  @override
  ConsumerState<SubscriptionStep> createState() => _SubscriptionStepState();
}

class _SubscriptionStepState extends ConsumerState<SubscriptionStep>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasSubscription = false;
  bool _showPackages = false;
  Map<String, List<Package>> _subscriptionOptions = {
    'monthly': [],
    'yearly': [],
  };
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Check current subscription status
    _checkSubscriptionStatus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);

      // Check if user already has an active subscription
      final hasActiveSubscription =
          await subscriptionService.hasActiveTrialOrSubscription();

      // Load subscription options in background
      _loadSubscriptionOptions();

      setState(() {
        _hasSubscription = hasActiveSubscription;
        _isLoading = false;
      });

      // If subscription is already active, we can move to the next step
      if (hasActiveSubscription) {
        widget.onSubscriptionHandled();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = PurchaseUtils.handlePurchaseError(e)!;
      });

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.subscription_check_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _loadSubscriptionOptions() async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final options = await subscriptionService.getSubscriptionOptions();
      if (mounted) {
        setState(() {
          _subscriptionOptions = options;
          if (options['yearly']!.isEmpty) {
            print('No yearly plans available');
          }
        });
      }
    } catch (e) {
      print('Error loading subscription options: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load plans';
        });
      }
    }
  }

  Future<void> _startFreeTrial() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.startTrial();

      if (mounted) {
        setState(() {
          _hasSubscription = true;
          _isLoading = false;
        });

        // Move to next step
        widget.onSubscriptionHandled();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;

          // Handle known RevenueCat error types
          if (e is PurchasesError) {
            if (e.code == PurchasesErrorCode.purchaseCancelledError) {
              _errorMessage = 'onboarding.subscription_cancelled'.tr();
            } else {
              _errorMessage = PurchaseUtils.handlePurchaseError(e)!;
            }
          } else {
            _errorMessage = PurchaseUtils.handlePurchaseError(e)!;
          }
        });

        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.subscription_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restored = await subscriptionService.restorePurchases();

      if (mounted) {
        setState(() {
          _hasSubscription = restored;
          _isLoading = false;
        });

        if (restored) {
          AppDialogs.showSnackBar(
            context,
            message: 'onboarding.subscription_restored'.tr(),
            type: SnackBarType.success,
          );

          // Wait a moment before proceeding
          await Future.delayed(const Duration(seconds: 1));
          widget.onSubscriptionHandled();
        } else {
          AppDialogs.showSnackBar(
            context,
            message: 'onboarding.no_subscription_found'.tr(),
            type: SnackBarType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.restore_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = ''; // Reset error message
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.purchasePackage(package);

      if (mounted) {
        setState(() {
          _hasSubscription = true;
          _isLoading = false;
        });

        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.subscription_successful'.tr(),
          type: SnackBarType.success,
        );

        widget.onSubscriptionHandled();
      }
    } catch (e) {
      if (mounted) {
        // Custom error handling with specific cases
        String? customErrorMessage = PurchaseUtils.handlePurchaseError(e);

        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = customErrorMessage!;
        });

        // Only show snackbar for non-cancellation errors
        if (!customErrorMessage!.contains('cancelled')) {
          AppDialogs.showSnackBar(
            context,
            message: customErrorMessage,
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  void _togglePackages() {
    setState(() {
      _showPackages = !_showPackages;
    });
  }

  void _skipSubscription() {
    // Just move to the next step without starting a trial
    widget.onSubscriptionHandled();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'onboarding.subscription_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'onboarding.subscription_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),

            // Animation or illustration
            Center(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                )),
                child: Container(
                  height: 160.h,
                  child: Lottie.asset(
                    'assets/animations/subscription.json',
                    fit: BoxFit.contain,
                    // Fallback if the animation is not available
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.star,
                      size: 100.r,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Premium features card
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'onboarding.premium_features'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildFeaturesList(colorScheme),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Trial information
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'onboarding.trial_info'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontSize: 13.sp,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Show subscription packages if requested
            if (_showPackages) _buildSubscriptionPackages(colorScheme),

            // if (_hasError) _buildErrorMessage(colorScheme),

            // Start trial button or success message
            if (_hasSubscription)
              _buildSubscriptionActiveCard(colorScheme)
            else
              _buildTrialButton(colorScheme),

            SizedBox(height: 16.h),

            // Restore purchases option
            if (!_hasSubscription && !_isLoading)
              Center(
                child: TextButton(
                  onPressed: _restorePurchases,
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  ),
                  child: Text(
                    'onboarding.restore_purchases'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            // Skip button
            if (!_hasSubscription && !_isLoading)
              Center(
                child: TextButton(
                  onPressed: _skipSubscription,
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  ),
                  child: Text(
                    'onboarding.maybe_later'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(ColorScheme colorScheme) {
    final features = [
      {
        'icon': Icons.text_format,
        'title': 'onboarding.ocr_feature'.tr(),
        'description': 'onboarding.ocr_feature_desc'.tr(),
      },
      {
        'icon': Icons.lock_outline,
        'title': 'onboarding.security_feature'.tr(),
        'description': 'onboarding.security_feature_desc'.tr(),
      },
      {
        'icon': Icons.cloud_upload_outlined,
        'title': 'onboarding.cloud_feature'.tr(),
        'description': 'onboarding.cloud_feature_desc'.tr(),
      },
      {
        'icon': Icons.file_copy_outlined,
        'title': 'onboarding.unlimited_feature'.tr(),
        'description': 'onboarding.unlimited_feature_desc'.tr(),
      },
    ];

    return Column(
      children: features
          .map((feature) => _buildFeatureItem(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
                colorScheme: colorScheme,
              ))
          .toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 18.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.slabo27px(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.sp,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialButton(ColorScheme colorScheme) {
    return Column(
      children: [
        // Call to action button
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () => _showPackages ? _togglePackages() : _startFreeTrial(),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 2,
            shadowColor: colorScheme.primary.withOpacity(0.4),
            minimumSize: Size(double.infinity, 54.h),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _showPackages
                            ? Icons.close
                            : Icons.star_border_outlined,
                        size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      _showPackages
                          ? 'onboarding.hide_options'.tr()
                          : 'onboarding.start_free_trial'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),

        if (!_showPackages) SizedBox(height: 12.h),

        // See plans button
        if (!_showPackages)
          TextButton(
            onPressed: _togglePackages,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            ),
            child: Text(
              'onboarding.see_subscription_plans'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubscriptionActiveCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24.r,
          ),
          SizedBox(width: 12.w),
          Text(
            'onboarding.subscription_active'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPackages(ColorScheme colorScheme) {
    // Show loading indicator while fetching packages
    if (_subscriptionOptions['monthly']!.isEmpty &&
        _subscriptionOptions['yearly']!.isEmpty) {
      return Container(
        margin: EdgeInsets.only(bottom: 24.h),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              SizedBox(height: 16.h),
              Text(
                'onboarding.loading_options'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 14.sp,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build subscription options cards
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'onboarding.subscription_plans'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: 16.h),

          // Monthly plans
          if (_subscriptionOptions['monthly']!.isNotEmpty) ...[
            Text(
              'onboarding.monthly_plans'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            ..._subscriptionOptions['monthly']!
                .map((package) => _buildPackageCard(package, colorScheme)),
            SizedBox(height: 16.h),
          ],

          // Yearly plans
          if (_subscriptionOptions['yearly']!.isNotEmpty) ...[
            Text(
              'onboarding.yearly_plans'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            ..._subscriptionOptions['yearly']!
                .map((package) => _buildPackageCard(package, colorScheme)),
            SizedBox(height: 16.h),
          ],

          // Other plans
          if (_subscriptionOptions['other']!.isNotEmpty) ...[
            Text(
              'onboarding.other_plans'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            ..._subscriptionOptions['other']!
                .map((package) => _buildPackageCard(package, colorScheme)),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package, ColorScheme colorScheme) {
    final hasFreeTrial = package.storeProduct.introductoryPrice != null;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => _purchasePackage(package),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFreeTrial ? Icons.star : Icons.auto_awesome,
                  color: colorScheme.primary,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.storeProduct.title
                          .replaceAll('(ScanPro)', '')
                          .trim(),
                      style: GoogleFonts.slabo27px(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasFreeTrial)
                      Text(
                        'onboarding.free_trial_available'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontSize: 12.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${package.storeProduct.price} ${package.storeProduct.currencyCode}',
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (hasFreeTrial)
                    Text(
                      '7-day free trial',
                      style: GoogleFonts.slabo27px(
                        fontSize: 12.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
