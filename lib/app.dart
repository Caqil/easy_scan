import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
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

void main() {
  runApp(ProviderScope(child: DocApp()));
}

class DocApp extends ConsumerStatefulWidget {
  const DocApp({super.key});

  @override
  ConsumerState<DocApp> createState() => _DocAppState();
}

class _DocAppState extends ConsumerState<DocApp>
    with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  bool _showOnboarding = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _initializeApp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocale();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.initialize();
      await subscriptionService.refreshSubscriptionStatus();

      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;

      ref.read(hasCompletedOnboardingProvider.notifier).state =
          hasCompletedOnboarding;

      setState(() {
        _showOnboarding = !hasCompletedOnboarding;
        _isInitialized = true;
      });
    } catch (e) {
      logger.error('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeLocale() async {
    final localState = ref.read(localProvider);
    logger.info(
        'Current app locale at startup: ${context.locale.languageCode}_${context.locale.countryCode}');

    final savedLocale = localState.selectedLocale;
    if (savedLocale != null && context.locale != savedLocale) {
      logger.info(
          'Applying saved locale: ${savedLocale.languageCode}_${savedLocale.countryCode}');
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: !_isInitialized
              ? SplashScreen(animation: _animation)
              : _showOnboarding
                  ? OnboardingScreen(onComplete: _onOnboardingComplete)
                  : const MainApp(),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ref.watch(settingsProvider).darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Animation<double> animation;

  const SplashScreen({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: animation,
              child: Container(
                width: 150.adaptiveW,
                height: 150.adaptiveH,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/icons/ic_icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.adaptiveH),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 20.adaptiveH),
            AutoSizeText(
              'common.loading'.tr(), // Using easy_localization
              style: GoogleFonts.slabo27px(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(settingsProvider).darkMode
          ? ThemeMode.dark
          : ThemeMode.light,
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
  }
}
