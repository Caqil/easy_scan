import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyStep extends StatefulWidget {
  final VoidCallback onPrivacyAccepted;

  const PrivacyStep({
    super.key,
    required this.onPrivacyAccepted,
  });

  @override
  State<PrivacyStep> createState() => _PrivacyStepState();
}

class _PrivacyStepState extends State<PrivacyStep>
    with SingleTickerProviderStateMixin {
  bool _isPrivacyAccepted = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _launchPrivacyPolicy() async {
    // Replace with your actual privacy policy URL
    final Uri url = Uri.parse('https://scanpro.cc/privacy');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch privacy policy'.tr()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(_animationController),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Privacy Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primaryContainer.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.policy_outlined,
                            size: 64.r,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        AutoSizeText(
                          'onboarding.privacy.main_title'.tr(),
                          style: GoogleFonts.slabo27px(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        AutoSizeText(
                          'onboarding.privacy.subtitle'.tr(),
                          style: GoogleFonts.slabo27px(
                            fontSize: 16.sp,
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Privacy Sections
                  _buildPrivacySection(
                    context,
                    icon: Icons.security_outlined,
                    title: 'onboarding.privacy.data_protection.title'.tr(),
                    description:
                        'onboarding.privacy.data_protection.description'.tr(),
                  ),

                  SizedBox(height: 16.h),

                  _buildPrivacySection(
                    context,
                    icon: Icons.lock_outline,
                    title: 'onboarding.privacy.user_control.title'.tr(),
                    description:
                        'onboarding.privacy.user_control.description'.tr(),
                  ),

                  SizedBox(height: 16.h),

                  _buildPrivacySection(
                    context,
                    icon: Icons.visibility_outlined,
                    title: 'onboarding.privacy.transparency.title'.tr(),
                    description:
                        'onboarding.privacy.transparency.description'.tr(),
                  ),

                  SizedBox(height: 24.h),

                  // Privacy Policy Link
                  GestureDetector(
                    onTap: _launchPrivacyPolicy,
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            color: colorScheme.primary,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'onboarding.privacy.full_policy'.tr(),
                                  style: GoogleFonts.slabo27px(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                AutoSizeText(
                                  'onboarding.privacy.full_policy_description'
                                      .tr(),
                                  style: GoogleFonts.slabo27px(
                                    fontSize: 12.sp,
                                    color: colorScheme.onBackground
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: colorScheme.primary,
                            size: 20.r,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Acceptance Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isPrivacyAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            _isPrivacyAccepted = value ?? false;
                          });
                        },
                        activeColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPrivacyAccepted = !_isPrivacyAccepted;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.slabo27px(
                                fontSize: 14.sp,
                                color: colorScheme.onBackground,
                              ),
                              children: [
                                TextSpan(
                                  text: 'onboarding.privacy.acceptance_prefix'
                                      .tr(),
                                ),
                                TextSpan(
                                  text: 'onboarding.privacy.policy_link_text'
                                      .tr(),
                                  style: GoogleFonts.slabo27px(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Continue Button
                  OutlinedButton(
                    onPressed:
                        _isPrivacyAccepted ? widget.onPrivacyAccepted : null,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      disabledBackgroundColor:
                          colorScheme.primary.withOpacity(0.3),
                    ),
                    child: AutoSizeText(
                      'subscription.continue'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.surfaceVariant,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                SizedBox(height: 8.h),
                AutoSizeText(
                  description,
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    color: colorScheme.onBackground.withOpacity(0.7),
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
