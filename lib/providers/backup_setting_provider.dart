import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/backup_setting.dart';
import 'package:scanpro/models/backup_settings.dart';
import 'package:scanpro/providers/backup_provider.dart';
import 'package:scanpro/services/cloud_service.dart';
import 'package:scanpro/services/storage_service.dart';

/// Notifier class for backup settings
class BackupSettingsNotifier extends AsyncNotifier<BackupSettings> {
  late final StorageService _storageService;

  @override
  Future<BackupSettings> build() async {
    _storageService = ref.read(storageServiceProvider);
    return _loadSettings();
  }

  /// Load backup settings from storage
  Future<BackupSettings> _loadSettings() async {
    try {
      return await _storageService.getBackupSettings();
    } catch (e) {
      logger.error('Error loading backup settings: $e');
      return BackupSettings(); // Return default settings on error
    }
  }

  /// Save backup settings
  Future<void> saveSettings(BackupSettings settings) async {
    try {
      state = const AsyncValue.loading();
      await _storageService.saveBackupSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e) {
      logger.error('Error saving backup settings: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle auto backup
  Future<void> toggleAutoBackup() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(autoBackupEnabled: !settings.autoBackupEnabled),
      );
      state = AsyncValue.data(settings.copyWith(
        autoBackupEnabled: !settings.autoBackupEnabled,
      ));
    } catch (e) {
      logger.error('Error toggling auto backup: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update backup frequency
  Future<void> updateBackupFrequency(BackupFrequency frequency) async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(backupFrequency: frequency),
      );
      state = AsyncValue.data(settings.copyWith(backupFrequency: frequency));
    } catch (e) {
      logger.error('Error updating backup frequency: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update backup destination
  Future<void> updateBackupDestination(BackupDestination destination) async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(backupDestination: destination),
      );
      state = AsyncValue.data(settings.copyWith(
        backupDestination: destination,
      ));
    } catch (e) {
      logger.error('Error updating backup destination: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update max local backups
  Future<void> updateMaxLocalBackups(int maxBackups) async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(maxLocalBackups: maxBackups),
      );
      state = AsyncValue.data(settings.copyWith(maxLocalBackups: maxBackups));
    } catch (e) {
      logger.error('Error updating max local backups: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle include documents
  Future<void> toggleIncludeDocuments() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(includeDocuments: !settings.includeDocuments),
      );
      state = AsyncValue.data(settings.copyWith(
        includeDocuments: !settings.includeDocuments,
      ));
    } catch (e) {
      logger.error('Error toggling include documents: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle include settings
  Future<void> toggleIncludeSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(includeSettings: !settings.includeSettings),
      );
      state = AsyncValue.data(settings.copyWith(
        includeSettings: !settings.includeSettings,
      ));
    } catch (e) {
      logger.error('Error toggling include settings: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle include folders
  Future<void> toggleIncludeFolders() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _loadSettings();
      await _storageService.saveBackupSettings(
        settings.copyWith(includeFolders: !settings.includeFolders),
      );
      state = AsyncValue.data(settings.copyWith(
        includeFolders: !settings.includeFolders,
      ));
    } catch (e) {
      logger.error('Error toggling include folders: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for backup settings
final backupSettingsProvider =
    AsyncNotifierProvider<BackupSettingsNotifier, BackupSettings>(() {
  return BackupSettingsNotifier();
});

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for backup provider
final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final cloudBackupService = ref.watch(cloudBackupServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return BackupNotifier(
    backupService: cloudBackupService,
    storageService: storageService,
    ref: ref,
  );
});
