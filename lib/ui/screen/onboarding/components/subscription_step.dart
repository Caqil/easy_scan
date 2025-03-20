import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';

class SubscriptionStep extends ConsumerStatefulWidget {
  final VoidCallback onSubscriptionHandled;

  const SubscriptionStep({
    Key? key,
    required this.onSubscriptionHandled,
  }) : super(key: key);

  @override
  ConsumerState<SubscriptionStep> createState() => _SubscriptionStepState();
}

class _SubscriptionStepState extends ConsumerState<SubscriptionStep> {
  bool _isLoading = false;
  bool _trialStarted = false;

  @override
  void initState() {
    super.initState();
    // Check if trial is already active
    _checkTrialStatus();
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            Text(
              'onboarding.subscription_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'onboarding.subscription_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),

            // Animation or illustration
            Container(
              height: 180.h,
              width: double.infinity,
              child: Lottie.asset(
                'assets/animations/subscription.json',
                fit: BoxFit.contain,
                // Fallback if the animation is not available
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.star,
                  size: 100.r,
                  color: Colors.amber,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Premium features list
            _buildFeaturesList(),

            SizedBox(height: 30.h),

            // Trial information
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'onboarding.trial_info'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Start trial button
            if (_trialStarted)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24.r,
                    ),
                    SizedBox(width: 8.w),
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
              )
            else
              ElevatedButton(
                onPressed: _isLoading ? null : _startFreeTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  minimumSize: Size(double.infinity, 50.h),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        'onboarding.start_free_trial'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

            SizedBox(height: 12.h),

            // Skip button
            if (!_trialStarted && !_isLoading)
              TextButton(
                onPressed: _skipSubscription,
                child: Text(
                  'onboarding.maybe_later'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.remove_red_eye,
        'title': 'onboarding.ocr_feature'.tr(),
        'description': 'onboarding.ocr_feature_desc'.tr(),
      },
      {
        'icon': Icons.lock,
        'title': 'onboarding.security_feature'.tr(),
        'description': 'onboarding.security_feature_desc'.tr(),
      },
      {
        'icon': Icons.cloud_upload,
        'title': 'onboarding.cloud_feature'.tr(),
        'description': 'onboarding.cloud_feature_desc'.tr(),
      },
      {
        'icon': Icons.filter_none,
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
              ))
          .toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20.r,
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
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
