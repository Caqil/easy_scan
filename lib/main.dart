import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:scanpro/app.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/file_limit_service.dart';
import 'package:scanpro/services/logger_service.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'services/storage_service.dart';
import 'firebase_options.dart';

final logger = LoggerService();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final storageService = StorageService();
  await storageService.initialize();
  Locale initialLocale = const Locale('en', 'US'); // Default
  final settingsBox = await Hive.openBox('settings');
  final storedLocale = settingsBox.get('locale');
  if (storedLocale != null) {
    initialLocale =
        Locale(storedLocale['languageCode'], storedLocale['countryCode']);
    logger.info(
        'Starting app with saved locale: ${initialLocale.languageCode}_${initialLocale.countryCode}');
  }
  final container = ProviderContainer();
  await container.read(subscriptionServiceProvider).initialize();
  await container.read(documentsProvider.notifier).loadAll();
  await container.read(subscriptionServiceProvider).refreshSubscriptionStatus();
  runApp(
    ProviderScope(
      overrides: [
        fileLimitServiceProvider,
        remainingFilesProvider,
        maxAllowedFilesProvider,
        hasReachedFileLimitProvider,
        totalFilesProvider,
      ],
      child: EasyLocalization(
          path: 'assets/languages',
          fallbackLocale: Locale('en', 'US'),
          startLocale: initialLocale,
          supportedLocales: const [
            Locale("en", "US"),
            Locale("id", "ID"),
          ],
          useOnlyLangCode: true,
          child: DocApp()),
    ),
  );
}
