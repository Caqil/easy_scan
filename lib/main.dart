import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/app.dart';
import 'package:scanpro/services/logger_service.dart';
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
  runApp(
    ProviderScope(
      child: EasyLocalization(
          path: 'assets/languages',
          fallbackLocale: Locale('en', 'US'),
          startLocale: Locale('en', 'US'),
          supportedLocales: const [
            Locale("en", "US"),
            Locale("id", "ID"),
          ],
          useOnlyLangCode: true,
          child: DocApp()),
    ),
  );
}
