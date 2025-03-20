import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/ui/screen/onboarding/onboarding_screen.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
import 'ui/widget/auth_wrapper.dart';
import 'ui/widget/auth_overlay.dart';
import 'package:scanpro/services/subscription_service.dart';

class DocApp extends ConsumerStatefulWidget {
  const DocApp({super.key});

  @override
  ConsumerState<DocApp> createState() => _DocAppState();
}

class _DocAppState extends ConsumerState<DocApp> {
  bool _isInitialized = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocale();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize subscription service first
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.initialize();

      // Then check subscription status
      await subscriptionService.refreshSubscriptionStatus();

      // Check if onboarding is needed
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;

      // Set initial state for onboarding provider
      ref.read(hasCompletedOnboardingProvider.notifier).state =
          hasCompletedOnboarding;

      setState(() {
        _showOnboarding = !hasCompletedOnboarding;
        _isInitialized = true;
      });
    } catch (e) {
      // Handle initialization errors
      print('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeLocale() async {
    // Access localeState to trigger locale loading
    final localState = ref.read(localProvider);

    // Log current locale at startup
    logger.info(
        'Current app locale at startup: ${context.locale.languageCode}_${context.locale.countryCode}');

    // If we have a saved locale that's different from current, apply it
    final savedLocale = localState.selectedLocale;
    if (savedLocale != null && context.locale != savedLocale) {
      logger.info(
          'Applying saved locale: ${savedLocale.languageCode}_${savedLocale.countryCode}');

      // Use microtask to apply locale after build is complete
      Future.microtask(() {
        if (mounted) {
          context.setLocale(savedLocale);
          logger.info(
              'Locale set to: ${savedLocale.languageCode}_${savedLocale.countryCode}');
        }
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not yet initialized, show loading screen
    if (!_isInitialized) {
      return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) {
            return MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          });
    }

    // If onboarding is needed, show the onboarding screen
    if (_showOnboarding) {
      return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) {
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: OnboardingScreen(
                onComplete: _onOnboardingComplete,
              ),
            );
          });
    }

    // Regular app with router
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ref.watch(settingsProvider).darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          routerConfig: AppRoutes.router,
          builder: (context, child) {
            return AuthWrapper(
              builder: (context) {
                return Stack(
                  children: [
                    if (child != null) child,
                    const AuthOverlay(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
