import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';

class TrialExplanationSheet extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const TrialExplanationSheet({
    Key? key,
    this.onComplete,
  }) : super(key: key);

  static Future<void> show(BuildContext context,
      {VoidCallback? onComplete}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrialExplanationSheet(onComplete: onComplete),
    );
  }

  @override
  ConsumerState<TrialExplanationSheet> createState() =>
      _TrialExplanationSheetState();
}

class _TrialExplanationSheetState extends ConsumerState<TrialExplanationSheet> {
  bool _isStarting = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF0C2D4D), // Dark blue background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: SingleChildScrollView(
          // Add this
          child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(top: 16.h, right: 16.w),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Title
          AutoSizeText(
            'trial_explanation.title'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40.h),

          // Timeline
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                // Today
                _buildTimelineItem(
                  icon: Icons.lock_open,
                  day: 'trial_explanation.today'.tr(),
                  description: 'trial_explanation.today_desc'.tr(),
                  isFirst: true,
                ),

                // Day 5
                _buildTimelineItem(
                  icon: Icons.notifications,
                  day: 'trial_explanation.day_5'.tr(),
                  description: 'trial_explanation.day_5_desc'.tr(),
                ),

                // Day 7
                _buildTimelineItem(
                  icon: Icons.star,
                  day: 'trial_explanation.day_7'.tr(),
                  description: 'trial_explanation.day_7_desc'.tr(),
                  isLast: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // Price Info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                AutoSizeText(
                  'trial_explanation.price_info_1'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 18.sp,
                    color: Colors.white,
                  ),
                ),
                AutoSizeText(
                  'trial_explanation.price_info_2'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // How to cancel info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'trial_explanation.cancel_title'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                AutoSizeText(
                  'trial_explanation.cancel_desc'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AutoSizeText(
                  _errorMessage,
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(children: [
                OutlinedButton(
                  onPressed: _isStarting ? null : _startTrial,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isStarting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : AutoSizeText(
                          'trial_explanation.start_button'.tr(),
                          style: GoogleFonts.slabo27px(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ])),
          // Start trial button
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                OutlinedButton(
                  onPressed: _isStarting ? null : _startTrial,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isStarting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : AutoSizeText(
                          'Start my free trial now',
                          style: GoogleFonts.slabo27px(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(height: 8.h),
                AutoSizeText(
                  '2 taps to start, super easy to cancel',
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h + MediaQuery.of(context).padding.bottom),
        ],
      )),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String day,
    required String description,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline with icon
        SizedBox(
          width: 60.w,
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24.r,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2.w,
                  height: 60.h,
                  color: Colors.lightBlueAccent.withOpacity(0.5),
                ),
            ],
          ),
        ),

        // Right content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                day,
                style: GoogleFonts.slabo27px(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              AutoSizeText(
                description,
                style: GoogleFonts.slabo27px(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: isLast ? 0 : 24.h),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startTrial() async {
    setState(() {
      _isStarting = true;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.hasActiveSubscription();

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          AppDialogs.showSnackBar(
            context,
            message: 'Your free trial has been activated!',
            type: SnackBarType.success,
          );
          widget.onComplete?.call();
        } else {
          AppDialogs.showSnackBar(
            context,
            message: 'Failed to start free trial. Please try again.',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }
}
