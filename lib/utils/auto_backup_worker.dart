import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/backup_setting.dart';
import 'package:scanpro/providers/backup_setting_provider.dart';
import 'package:scanpro/services/cloud_service.dart';
import 'package:scanpro/services/storage_service.dart';

/// A worker class that handles automatic backups in the background
class AutoBackupWorker {
  static final AutoBackupWorker _instance = AutoBackupWorker._internal();
  factory AutoBackupWorker() => _instance;

  AutoBackupWorker._internal();

  Timer? _backupCheckTimer;
  bool _isRunningBackup = false;
  Ref? _ref;

  /// Initialize the background backup worker
  Future<void> initialize(Ref ref) async {
    _ref = ref;
    logger.info('Initializing auto backup worker');

    // Cancel any existing timer
    _backupCheckTimer?.cancel();

    // Start a periodic timer to check if a backup is due
    _backupCheckTimer = Timer.periodic(
      const Duration(hours: 1), // Check every hour
      (_) => _checkForScheduledBackup(),
    );

    // Also check immediately on startup
    await _checkForScheduledBackup();
  }

  /// Check if a scheduled backup is due
  Future<void> _checkForScheduledBackup() async {
    try {
      // Avoid running multiple backups at once
      if (_isRunningBackup || _ref == null) return;

      // Get backup settings
      final storageService = _ref!.read(storageServiceProvider);
      final settings = await storageService.getBackupSettings();

      // Check if auto-backup is enabled and due
      if (settings.autoBackupEnabled && settings.isBackupDue()) {
        await _performScheduledBackup(settings);
      }
    } catch (e) {
      logger.error('Error checking for scheduled backup: $e');
    }
  }

  /// Perform a scheduled backup
  Future<void> _performScheduledBackup(BackupSettings settings) async {
    try {
      _isRunningBackup = true;
      logger.info('Starting scheduled backup');

      // Select the backup destination
      final destination = settings.backupDestination;

      // Check if the destination is supported on this platform
      if (!await _isPlatformSupported(destination)) {
        logger.warning(
            'Backup destination not supported on this platform: $destination');
        _isRunningBackup = false;
        return;
      }

      // Get the cloud backup service
      final cloudBackupService = _ref!.read(cloudBackupServiceProvider);

      // Perform the backup
      final result = await cloudBackupService.createBackup(
        destination: destination,
        ref: _ref!,
        onProgress: null, // No progress callback for background backup
      );

      // Update backup settings
      if (result == BackupResult.success) {
        logger.info('Scheduled backup completed successfully');
        final updatedSettings = settings.updateAfterBackup();
        await storageService.saveBackupSettings(updatedSettings);

        // Also save last backup date
        await storageService.saveLastBackupDate(DateTime.now());
      } else {
        logger.warning('Scheduled backup failed: $result');
      }
    } catch (e) {
      logger.error('Error performing scheduled backup: $e');
    } finally {
      _isRunningBackup = false;
    }
  }

  /// Check if the backup destination is supported on this platform
  Future<bool> _isPlatformSupported(BackupDestination destination) async {
    if (_ref == null) return false;

    final cloudBackupService = _ref!.read(cloudBackupServiceProvider);
    return await cloudBackupService.isBackupServiceAvailable(destination);
  }

  /// Force a backup now, regardless of schedule
  Future<void> forceBackup(BackupDestination destination) async {
    try {
      // Avoid running multiple backups at once
      if (_isRunningBackup || _ref == null) return;

      _isRunningBackup = true;
      logger.info('Starting forced backup');

      // Check if the destination is supported on this platform
      if (!await _isPlatformSupported(destination)) {
        logger.warning(
            'Backup destination not supported on this platform: $destination');
        _isRunningBackup = false;
        return;
      }

      // Get services
      final cloudBackupService = _ref!.read(cloudBackupServiceProvider);
      final storageService = _ref!.read(storageServiceProvider);

      // Perform the backup
      final result = await cloudBackupService.createBackup(
        destination: destination,
        ref: _ref!,
        onProgress: null, // No progress callback for background backup
      );

      // Update backup settings
      if (result == BackupResult.success) {
        logger.info('Forced backup completed successfully');

        // Get and update backup settings
        final settings = await storageService.getBackupSettings();
        final updatedSettings = settings.updateAfterBackup();
        await storageService.saveBackupSettings(updatedSettings);

        // Also save last backup date
        await storageService.saveLastBackupDate(DateTime.now());
      } else {
        logger.warning('Forced backup failed: $result');
      }
    } catch (e) {
      logger.error('Error forcing backup: $e');
    } finally {
      _isRunningBackup = false;
    }
  }

  /// Cleanup old backups to prevent excessive storage usage
  Future<void> cleanupOldBackups() async {
    try {
      if (_ref == null) return;

      final storageService = _ref!.read(storageServiceProvider);
      final cloudBackupService = _ref!.read(cloudBackupServiceProvider);

      // Get backup settings
      final settings = await storageService.getBackupSettings();

      // Clean up local backups
      await _cleanupLocalBackups(settings.maxLocalBackups);

      // Clean up cloud backups based on destination
      if (settings.backupDestination == BackupDestination.iCloud &&
          Platform.isIOS) {
        await _cleanupICloudBackups(settings.maxLocalBackups);
      } else if (settings.backupDestination == BackupDestination.googleDrive) {
        await _cleanupGoogleDriveBackups(settings.maxLocalBackups);
      }
    } catch (e) {
      logger.error('Error cleaning up old backups: $e');
    }
  }

  /// Clean up old local backups
  Future<void> _cleanupLocalBackups(int maxBackups) async {
    try {
      if (_ref == null) return;

      final cloudBackupService = _ref!.read(cloudBackupServiceProvider);

      // Get all local backups
      final backups = await cloudBackupService.getAvailableBackups(
        BackupDestination.local,
      );

      // If we have more than the limit, delete the oldest ones
      if (backups.length > maxBackups) {
        // Sort by date (oldest first)
        backups.sort((a, b) {
          try {
            return DateTime.parse(a['date'])
                .compareTo(DateTime.parse(b['date']));
          } catch (e) {
            return 0; // If dates can't be parsed, don't change order
          }
        });

        // Delete oldest backups until we are within limits
        for (int i = 0; i < backups.length - maxBackups; i++) {
          await cloudBackupService.deleteBackup(
            BackupDestination.local,
            backups[i]['id'],
          );
          logger.info('Deleted old local backup: ${backups[i]['name']}');
        }
      }
    } catch (e) {
      logger.error('Error cleaning up local backups: $e');
    }
  }

  /// Clean up old iCloud backups
  Future<void> _cleanupICloudBackups(int maxBackups) async {
    try {
      if (_ref == null || !Platform.isIOS) return;

      final cloudBackupService = _ref!.read(cloudBackupServiceProvider);

      // Get all iCloud backups
      final backups = await cloudBackupService.getAvailableBackups(
        BackupDestination.iCloud,
      );

      // If we have more than the limit, delete the oldest ones
      if (backups.length > maxBackups) {
        // Sort by date (oldest first)
        backups.sort((a, b) {
          try {
            return DateTime.parse(a['date'])
                .compareTo(DateTime.parse(b['date']));
          } catch (e) {
            return 0; // If dates can't be parsed, don't change order
          }
        });

        // Delete oldest backups until we are within limits
        for (int i = 0; i < backups.length - maxBackups; i++) {
          await cloudBackupService.deleteBackup(
            BackupDestination.iCloud,
            backups[i]['id'],
          );
          logger.info('Deleted old iCloud backup: ${backups[i]['name']}');
        }
      }
    } catch (e) {
      logger.error('Error cleaning up iCloud backups: $e');
    }
  }

  /// Clean up old Google Drive backups
  Future<void> _cleanupGoogleDriveBackups(int maxBackups) async {
    try {
      if (_ref == null) return;

      final cloudBackupService = _ref!.read(cloudBackupServiceProvider);

      // Get all Google Drive backups
      final backups = await cloudBackupService.getAvailableBackups(
        BackupDestination.googleDrive,
      );

      // If we have more than the limit, delete the oldest ones
      if (backups.length > maxBackups) {
        // Sort by date (oldest first)
        backups.sort((a, b) {
          try {
            return DateTime.parse(a['date'])
                .compareTo(DateTime.parse(b['date']));
          } catch (e) {
            return 0; // If dates can't be parsed, don't change order
          }
        });

        // Delete oldest backups until we are within limits
        for (int i = 0; i < backups.length - maxBackups; i++) {
          await cloudBackupService.deleteBackup(
            BackupDestination.googleDrive,
            backups[i]['id'],
          );
          logger.info('Deleted old Google Drive backup: ${backups[i]['name']}');
        }
      }
    } catch (e) {
      logger.error('Error cleaning up Google Drive backups: $e');
    }
  }

  /// Dispose the worker
  void dispose() {
    _backupCheckTimer?.cancel();
    _backupCheckTimer = null;
    _ref = null;
  }
}

/// Provider for auto backup worker
final autoBackupWorkerProvider = Provider<AutoBackupWorker>((ref) {
  final worker = AutoBackupWorker();
  worker.initialize(ref);

  // Clean up on dispose
  ref.onDispose(() {
    worker.dispose();
  });

  return worker;
});
