import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive/hive.dart';
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
  }

  void setLanguage(BuildContext context, Locale locale) async {
    EasyLocalization.of(context)!.setLocale(locale);
    state = state.copyWith(selectedLocale: locale);

    final box = await Hive.openBox('settings');
    box.put('locale', {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode
    });
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
        box.add(language);
      }

      final locales =
          languages.map((e) => Locale(e.languageCode, e.countryCode)).toList();

      state = state.copyWith(languages: languages, locales: locales);
    }

    final settingsBox = await Hive.openBox('settings');
    final storedLocale = settingsBox.get('locale');

    if (storedLocale != null) {
      final locale =
          Locale(storedLocale['languageCode'], storedLocale['countryCode']);
      setLanguage(context, locale);
    }
  }
}

final localProvider = StateNotifierProvider<LocalNotifier, LocalState>((ref) {
  return LocalNotifier();
});
