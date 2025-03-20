import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:lottie/lottie.dart';

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
  bool _trialStarted = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Check if trial is already active
    _checkTrialStatus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkTrialStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final hasTrial = await subscriptionService.hasActiveTrialOrSubscription();

      setState(() {
        _trialStarted = hasTrial;
        _isLoading = false;
      });

      // If trial is already active, we can move to the next step
      if (_trialStarted) {
        widget.onSubscriptionHandled();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  Future<void> _startFreeTrial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.startTrial();

      setState(() {
        _trialStarted = true;
        _isLoading = false;
      });

      widget.onSubscriptionHandled();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.subscription_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
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

            // Start trial button or success message
            if (_trialStarted)
              _buildTrialStartedCard(colorScheme)
            else
              _buildTrialButton(colorScheme),

            SizedBox(height: 12.h),

            // Skip button
            if (!_trialStarted && !_isLoading)
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
    return ElevatedButton(
      onPressed: _isLoading ? null : _startFreeTrial,
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
                Icon(Icons.star_border_outlined, size: 20.r),
                SizedBox(width: 8.w),
                Text(
                  'onboarding.start_free_trial'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTrialStartedCard(ColorScheme colorScheme) {
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
            'onboarding.trial_started'.tr(),
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
}
