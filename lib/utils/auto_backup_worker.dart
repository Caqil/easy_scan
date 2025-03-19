import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:scanpro/models/backup_settings.dart';
import 'package:scanpro/services/backup_service.dart';
import 'package:scanpro/services/storage_service.dart';

/// A worker class that handles automatic backups in the background
class AutoBackupWorker {
  static final AutoBackupWorker _instance = AutoBackupWorker._internal();
  factory AutoBackupWorker() => _instance;

  AutoBackupWorker._internal();

  Timer? _backupCheckTimer;
  bool _isRunningBackup = false;

  final StorageService _storageService = StorageService();
  final BackupService _backupService = BackupService();

  /// Initialize the background backup worker
  Future<void> initialize() async {
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
      if (_isRunningBackup) return;

      // Get backup settings
      final settings = await _storageService.getBackupSettings();

      // Check if auto-backup is enabled and due
      if (settings.autoBackupEnabled && settings.isBackupDue()) {
        await _performScheduledBackup(settings);
      }
    } catch (e) {
      debugPrint('Error checking for scheduled backup: $e');
    }
  }

  /// Perform a scheduled backup
  Future<void> _performScheduledBackup(BackupSettings settings) async {
    try {
      _isRunningBackup = true;

      // Select the backup destination
      final destination = settings.backupDestination;

      // Check if the destination is supported on this platform
      if (_isPlatformSupported(destination)) {
        // Perform the backup
        await _backupService.createBackup(
          destination: destination,
          context: null, // No context for background backup
          onProgress: null, // No progress callback for background backup
        );

        // Update backup settings
        final updatedSettings = settings.updateAfterBackup();
        await _storageService.saveBackupSettings(updatedSettings);
      }
    } catch (e) {
      debugPrint('Error performing scheduled backup: $e');
    } finally {
      _isRunningBackup = false;
    }
  }

  /// Check if the backup destination is supported on this platform
  bool _isPlatformSupported(BackupDestination destination) {
    switch (destination) {
      case BackupDestination.googleDrive:
        return Platform.isAndroid || Platform.isIOS;
      case BackupDestination.local:
        return true;
    }
  }

  /// Force a backup now, regardless of schedule
  Future<void> forceBackup(BackupDestination destination) async {
    try {
      // Avoid running multiple backups at once
      if (_isRunningBackup) return;

      _isRunningBackup = true;

      // Check if the destination is supported on this platform
      if (_isPlatformSupported(destination)) {
        // Perform the backup
        await _backupService.createBackup(
          destination: destination,
          context: null, // No context for background backup
          onProgress: null, // No progress callback for background backup
        );

        // Get and update backup settings
        final settings = await _storageService.getBackupSettings();
        final updatedSettings = settings.updateAfterBackup();
        await _storageService.saveBackupSettings(updatedSettings);
      }
    } catch (e) {
      debugPrint('Error forcing backup: $e');
    } finally {
      _isRunningBackup = false;
    }
  }

  /// Cleanup old backups to prevent excessive storage usage
  Future<void> cleanupOldBackups() async {
    try {
      // Get backup settings
      final settings = await _storageService.getBackupSettings();

      // Clean up local backups
      await _cleanupLocalBackups(settings.maxLocalBackups);

      // TODO: Cloud backup cleanup requires Google Drive and iCloud APIs
      // This is a future enhancement
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// Clean up old local backups
  Future<void> _cleanupLocalBackups(int maxBackups) async {
    try {
      // Get backup directory
      final backupsPath = await _storageService.getBackupsPath();
      final backupsDir = Directory(backupsPath);

      if (!await backupsDir.exists()) return;

      // Get all backup files
      final files = await backupsDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      // Sort by last modified date (newest first)
      files.sort((a, b) {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      });

      // Delete old backups if there are more than maxBackups
      if (files.length > maxBackups) {
        for (int i = maxBackups; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up local backups: $e');
    }
  }

  /// Dispose the worker
  void dispose() {
    _backupCheckTimer?.cancel();
    _backupCheckTimer = null;
  }
}
