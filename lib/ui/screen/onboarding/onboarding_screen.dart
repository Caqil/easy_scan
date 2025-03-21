import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:scanpro/ui/screen/onboarding/components/language_step.dart';
import 'package:scanpro/ui/screen/onboarding/components/permission_step.dart';
import 'package:scanpro/ui/screen/onboarding/components/privacy_step.dart';
import 'package:scanpro/ui/screen/onboarding/components/subscription_step.dart';
import 'package:scanpro/ui/screen/onboarding/components/theme_step.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/permission_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to check if onboarding is completed
final hasCompletedOnboardingProvider = StateProvider<bool>((ref) {
  // Initialize with false and then update in initState
  return false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;

  int _currentPage = 0;
  final int _totalPages =
      5; // Permissions, Language, Theme, Subscription, Privacy

  // Initialize with default values
  bool _permissionsGranted = false;
  bool _languageSelected = false;
  bool _themeSelected = false;
  bool _subscriptionHandled = false;
  bool _privacyAccepted = false;
  bool _isInitialized = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Initialize data in initState
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final localState = ref.read(localProvider);

      // Check permissions
      bool hasCameraPermission = await PermissionUtils.hasCameraPermission();
      bool hasStoragePermission = await PermissionUtils.hasStoragePermissions();

      // Update state only if widget is still mounted
      if (mounted) {
        setState(() {
          _permissionsGranted = hasCameraPermission && hasStoragePermission;
          _languageSelected = localState.selectedLocale != null;
          _themeSelected = true; // We can assume theme is always selected
          _isInitialized = true;
        });

        _animationController.forward();
      }
    } catch (e) {
      print('Error initializing onboarding data: $e');
      // Set initialized even on error to prevent endless loading
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _animationController.reverse().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animationController.forward();
      });
    } else {
      _completeOnboarding();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _animationController.reverse().then((_) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animationController.forward();
      });
    }
  }

  void _onPrivacyAccepted() {
    setState(() {
      _privacyAccepted = true;
    });
    // Complete onboarding on final privacy step
    _completeOnboarding();
  }

  void _onPermissionsGranted() {
    setState(() {
      _permissionsGranted = true;
    });
    _goToNextPage();
  }

  void _onLanguageSelected() {
    setState(() {
      _languageSelected = true;
    });
    _goToNextPage();
  }

  void _onThemeSelected() {
    setState(() {
      _themeSelected = true;
    });
    _goToNextPage();
  }

  void _onSubscriptionHandled() {
    setState(() {
      _subscriptionHandled = true;
      _currentPage++; // Move to privacy step
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      // Save that onboarding is completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.hasCompletedOnboardingKey, true);

      // Update the provider
      ref.read(hasCompletedOnboardingProvider.notifier).state = true;

      // Exit animation
      await _animationController.reverse();

      // Notify parent that onboarding is complete
      widget.onComplete();
    } catch (e) {
      print('Error completing onboarding: $e');
      setState(() {
        _isCompleting = false;
      });
    }
  }

  void _showSkipDialog() {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'onboarding.skip_title'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          content: Text(
            'onboarding.skip_message'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'common.cancel'.tr(),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeOnboarding();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
              child: Text(
                'common.skip'.tr(),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show loading indicator while initializing
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              SizedBox(height: 24.h),
              AutoSizeText(
                'onboarding.initializing'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.sp,
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with progress indicator
            _buildAppBar(colorScheme),

            // Main content
            Expanded(
              child: FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  )),
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable swiping
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      // Step 1: Permissions
                      PermissionStep(
                          onPermissionsGranted: _onPermissionsGranted),

                      // Step 2: Language Selection
                      LanguageStep(onLanguageSelected: _onLanguageSelected),

                      // Step 3: Theme Selection
                      ThemeStep(onThemeSelected: _onThemeSelected),

                      // Step 4: Subscription Trial
                      SubscriptionStep(
                          onSubscriptionHandled: _onSubscriptionHandled),

                      // Step 5: Privacy
                      PrivacyStep(onPrivacyAccepted: _onPrivacyAccepted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back/Close button
          InkWell(
            onTap: () {
              if (_currentPage == 0) {
                // First page, allow skipping the entire onboarding
                _showSkipDialog();
              } else {
                // Go back to previous page
                _goToPreviousPage();
              }
            },
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _currentPage == 0
                    ? Icons.close
                    : _currentPage == _totalPages - 1
                        ? Icons.close
                        : Icons.arrow_back,
                color: colorScheme.primary,
                size: 20.r,
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Progress bar and page indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step name
                AutoSizeText(
                  _getStepName(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: colorScheme.onBackground,
                  ),
                ),

                SizedBox(height: 8.h),

                // Progress bar
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),

                    // Progress
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 6.h,
                      width: MediaQuery.of(context).size.width *
                              (_currentPage + 1) /
                              _totalPages -
                          60.w,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(3.r),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          // Page number
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: AutoSizeText(
              '${_currentPage + 1}/$_totalPages',
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepName() {
    switch (_currentPage) {
      case 0:
        return 'onboarding.step_permissions'.tr();
      case 1:
        return 'onboarding.select_your_language'.tr();
      case 2:
        return 'onboarding.step_theme'.tr();
      case 3:
        return 'onboarding.step_subscription'.tr();
      case 4:
        return 'onboarding.step_privacy'.tr();
      default:
        return '';
    }
  }
}
