import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'firebase_options.dart';

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
  // Initialize storage
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
