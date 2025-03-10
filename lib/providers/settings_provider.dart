import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Box _settingsBox;

  SettingsNotifier(this._settingsBox) : super(AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    if (_settingsBox.containsKey(AppConstants.settingsKey)) {
      state = _settingsBox.get(AppConstants.settingsKey);
    } else {
      _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put(AppConstants.settingsKey, state);
  }

  void toggleDarkMode() {
    state = AppSettings(
      darkMode: !state.darkMode,
      biometricAuthEnabled: state.biometricAuthEnabled,
      defaultSaveLocation: state.defaultSaveLocation,
      autoEnhanceImages: state.autoEnhanceImages,
      cloudBackupEnabled: state.cloudBackupEnabled,
      defaultPdfQuality: state.defaultPdfQuality,
    );
    _saveSettings();
  }

  void toggleBiometricAuth() {
    state = AppSettings(
      darkMode: state.darkMode,
      biometricAuthEnabled: !state.biometricAuthEnabled,
      defaultSaveLocation: state.defaultSaveLocation,
      autoEnhanceImages: state.autoEnhanceImages,
      cloudBackupEnabled: state.cloudBackupEnabled,
      defaultPdfQuality: state.defaultPdfQuality,
    );
    _saveSettings();
  }

  void setDefaultSaveLocation(String location) {
    state = AppSettings(
      darkMode: state.darkMode,
      biometricAuthEnabled: state.biometricAuthEnabled,
      defaultSaveLocation: location,
      autoEnhanceImages: state.autoEnhanceImages,
      cloudBackupEnabled: state.cloudBackupEnabled,
      defaultPdfQuality: state.defaultPdfQuality,
    );
    _saveSettings();
  }

  void toggleAutoEnhanceImages() {
    state = AppSettings(
      darkMode: state.darkMode,
      biometricAuthEnabled: state.biometricAuthEnabled,
      defaultSaveLocation: state.defaultSaveLocation,
      autoEnhanceImages: !state.autoEnhanceImages,
      cloudBackupEnabled: state.cloudBackupEnabled,
      defaultPdfQuality: state.defaultPdfQuality,
    );
    _saveSettings();
  }

  void toggleCloudBackup() {
    state = AppSettings(
      darkMode: state.darkMode,
      biometricAuthEnabled: state.biometricAuthEnabled,
      defaultSaveLocation: state.defaultSaveLocation,
      autoEnhanceImages: state.autoEnhanceImages,
      cloudBackupEnabled: !state.cloudBackupEnabled,
      defaultPdfQuality: state.defaultPdfQuality,
    );
    _saveSettings();
  }

  void setDefaultPdfQuality(int quality) {
    state = AppSettings(
      darkMode: state.darkMode,
      biometricAuthEnabled: state.biometricAuthEnabled,
      defaultSaveLocation: state.defaultSaveLocation,
      autoEnhanceImages: state.autoEnhanceImages,
      cloudBackupEnabled: state.cloudBackupEnabled,
      defaultPdfQuality: quality,
    );
    _saveSettings();
  }
}

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.settingsBoxName);
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return SettingsNotifier(box);
});
