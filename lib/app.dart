// In app.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/main.dart';
import 'package:easy_scan/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
import 'ui/widget/auth_wrapper.dart';
import 'ui/widget/auth_overlay.dart';

class DocApp extends ConsumerWidget {
  const DocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final localState = ref.watch(localProvider);

    // If there's a saved locale, apply it
    final savedLocale = localState.selectedLocale;
    if (savedLocale != null && context.locale != savedLocale) {
      // Use Future.microtask to avoid build-time locale changes
      Future.microtask(() {
        context.setLocale(savedLocale);
        logger.info(
            'Applied saved locale: ${savedLocale.languageCode}_${savedLocale.countryCode}');
      });
    }
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
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
