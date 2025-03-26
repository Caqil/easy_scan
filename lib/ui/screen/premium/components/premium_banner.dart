import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';

class PremiumBanner extends ConsumerWidget {
  final VoidCallback onTap;
  const PremiumBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the premium status with Riverpod
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return isPremiumAsync.when(
      data: (hasAccess) {
        logger.info('user premium: $hasAccess');

        return hasAccess
            ? SizedBox.shrink()
            : GestureDetector(
                onTap: onTap,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[900]!.withOpacity(0.9),
                        Colors.grey[800]!.withOpacity(0.9),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.yellowAccent.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.yellowAccent.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              'subscription.monthly_desc'.tr(),
                              maxLines: 2,
                              style: GoogleFonts.slabo27px(
                                fontSize: 18.adaptiveSp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            AutoSizeText(
                              'onboarding.start_free_trial'.tr(),
                              maxLines: 1,
                              style: GoogleFonts.slabo27px(
                                fontSize: 14.adaptiveSp,
                                fontWeight: FontWeight.w400,
                                color: Colors.yellowAccent.withOpacity(0.9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.yellowAccent.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.yellowAccent.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/ic_icon.png',
                            height: 40.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
      },
      loading: () => SizedBox.shrink(), // Hide banner while loading
      error: (error, stack) {
        logger.error('Error checking premium status: $error');
        return SizedBox.shrink(); // Hide banner on error
      },
    );
  }
}
