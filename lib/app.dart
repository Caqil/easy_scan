import 'package:easy_scan/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
class DocApp extends ConsumerWidget {
  const DocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'CamScanner App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRoutes.generateRoute,

      // Change this to use the named route
      initialRoute: AppRoutes.home,
    );
  }
}
