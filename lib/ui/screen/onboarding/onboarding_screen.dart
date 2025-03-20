// Create this file at lib/ui/screen/onboarding/onboarding_screen.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/providers/settings_provider.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:scanpro/ui/screen/onboarding/components/language_step.dart';
import 'package:scanpro/ui/screen/onboarding/components/permission_step.dart';
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
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4; // Permissions, Language, Theme, Subscription

  // Initialize with default values
  bool _permissionsGranted = false;
  bool _languageSelected = false;
  bool _themeSelected = false;
  bool _subscriptionHandled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize data in initState
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Get initial states from provider
      final settings = ref.read(settingsProvider);
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
      }
    } catch (e) {
      print('Error initializing onboarding data: $e');
      // Set initialized even on error to prevent endless loading
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
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
    });
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      // Save that onboarding is completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.hasCompletedOnboardingKey, true);

      // Update the provider
      ref.read(hasCompletedOnboardingProvider.notifier).state = true;

      // Notify parent that onboarding is complete
      widget.onComplete();
    } catch (e) {
      print('Error completing onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _currentPage == 0 ? Icons.close : Icons.arrow_back,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      if (_currentPage == 0) {
                        // First page, allow skipping the entire onboarding
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('onboarding.skip_title'.tr()),
                            content: Text('onboarding.skip_message'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('common.cancel'.tr()),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _completeOnboarding();
                                },
                                child: Text('common.skip'.tr()),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Go back to previous page
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: Colors.grey.shade200,
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(width: 48.w), // Space for balance with back button
                ],
              ),
            ),

            // Main content
            Expanded(
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
                  PermissionStep(onPermissionsGranted: _onPermissionsGranted),

                  // Step 2: Language Selection
                  LanguageStep(onLanguageSelected: _onLanguageSelected),

                  // Step 3: Theme Selection
                  ThemeStep(onThemeSelected: _onThemeSelected),

                  // Step 4: Subscription Trial
                  SubscriptionStep(
                      onSubscriptionHandled: _onSubscriptionHandled),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => Container(
                        width: 8.w,
                        height: 8.w,
                        margin: EdgeInsets.only(right: 4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  // Next button
                  ElevatedButton(
                    onPressed: () {
                      switch (_currentPage) {
                        case 0: // Permissions
                          if (_permissionsGranted) _goToNextPage();
                          break;
                        case 1: // Language
                          if (_languageSelected) _goToNextPage();
                          break;
                        case 2: // Theme
                          if (_themeSelected) _goToNextPage();
                          break;
                        case 3: // Subscription
                          if (_subscriptionHandled) _completeOnboarding();
                          break;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currentPage == _totalPages - 1
                              ? 'onboarding.get_started'.tr()
                              : 'onboarding.next'.tr(),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward, size: 18.r),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
