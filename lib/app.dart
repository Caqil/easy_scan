// In app.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/utils/auto_backup_worker.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
import 'ui/widget/auth_wrapper.dart';
import 'ui/widget/auth_overlay.dart';

class DocApp extends ConsumerStatefulWidget {
  const DocApp({super.key});

  @override
  ConsumerState<DocApp> createState() => _DocAppState();
}

class _DocAppState extends ConsumerState<DocApp> {
  final AutoBackupWorker _autoBackupWorker = AutoBackupWorker();

  @override
  void initState() {
    super.initState();

    // Initialize the auto-backup worker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoBackupWorker.initialize();
    });
  }

  @override
  void dispose() {
    _autoBackupWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

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
