import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive/hive.dart';
import 'package:scanpro/main.dart';
import '../models/language.dart';

class LocalState {
  final Locale? selectedLocale;
  final List<Language> languages;
  final List<Locale> locales;

  LocalState({
    this.selectedLocale,
    this.languages = const [],
    this.locales = const [],
  });

  LocalState copyWith({
    Locale? selectedLocale,
    List<Language>? languages,
    List<Locale>? locales,
  }) {
    return LocalState(
      selectedLocale: selectedLocale ?? this.selectedLocale,
      languages: languages ?? this.languages,
      locales: locales ?? this.locales,
    );
  }
}

class LocalNotifier extends StateNotifier<LocalState> {
  LocalNotifier() : super(LocalState()) {
    _loadLanguages();
    _loadSavedLocale();
  }
  Future<void> _loadSavedLocale() async {
    try {
      final box = await Hive.openBox('settings');
      final storedLocale = box.get('locale');

      if (storedLocale != null) {
        // Create a locale from the stored data
        final locale =
            Locale(storedLocale['languageCode'], storedLocale['countryCode']);

        // Update the state
        state = state.copyWith(selectedLocale: locale);
        logger.info(
            'Loaded saved locale: ${locale.languageCode}_${locale.countryCode}');
      } else {
        logger.info('No saved locale found');
      }
    } catch (e) {
      logger.error('Error loading saved locale: $e');
    }
  }

  void setLanguage(BuildContext context, Locale locale) async {
    logger.info(
        'Setting language to: ${locale.languageCode}_${locale.countryCode}');

    EasyLocalization.of(context)!.setLocale(locale);
    state = state.copyWith(selectedLocale: locale);

    final box = await Hive.openBox('settings');
    await box.put('locale', {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode
    });

    logger.info('Language saved in Hive: ${box.get('locale')}');
  }

  Future<void> _loadLanguages() async {
    final box = await Hive.openBox<Language>('languages');

    if (box.isNotEmpty) {
      final storedLanguages = box.values.toList();
      final locales = storedLanguages
          .map((e) => Locale(e.languageCode, e.countryCode))
          .toList();

      state = state.copyWith(languages: storedLanguages, locales: locales);
    }
  }

  Future<void> initializeLanguages(BuildContext context) async {
    final box = await Hive.openBox<Language>('languages');

    if (box.isEmpty) {
      final load = await DefaultAssetBundle.of(context)
          .loadString("assets/languages/env.json");
      final List<dynamic> jsonData = jsonDecode(load);
      final languages =
          jsonData.map((e) => Language.fromJson(e)).toList().cast<Language>();

      for (var language in languages) {
        await box.add(language); // Use await to ensure proper writing
      }
    }

    final storedLanguages = box.values.toList();
    final locales = storedLanguages
        .map((e) => Locale(e.languageCode, e.countryCode))
        .toList();

    state = state.copyWith(languages: storedLanguages, locales: locales);
  }
}

final localProvider = StateNotifierProvider<LocalNotifier, LocalState>((ref) {
  return LocalNotifier();
});
