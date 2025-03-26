import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:scanpro/main.dart';
import 'package:scanpro/manager/google_drive_manager.dart';
import 'package:scanpro/manager/icloud_manager.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:scanpro/utils/backup_archive.dart';
import 'package:scanpro/services/storage_service.dart';
import 'package:scanpro/utils/icloud_manager.dart';
import 'package:scanpro/providers/settings_provider.dart';

/// Enum to represent different backup destinations
enum BackupDestination {
  local,
  iCloud,
  googleDrive,
}

/// Enum to represent backup operation results
enum BackupResult {
  success,
  failure,
  cancelled,
  notSupported,
}

/// Class to manage backups to different destinations
class CloudBackupService {
  final ICloudBackupManager _iCloudManager = ICloudBackupManager();
  final GoogleDriveManager _googleDriveManager = GoogleDriveManager();
  final StorageService _storageService = StorageService();

  /// Initialize backup services
  Future<void> initialize() async {
    try {
      // Initialize iCloud if on iOS
      if (Platform.isIOS) {
        await _iCloudManager.initialize();
      }

      // Initialize Google Drive
      await _googleDriveManager.initialize();
    } catch (e) {
      logger.error('Error initializing backup services: $e');
    }
  }

  /// Check if backup service is available for a specific destination
  Future<bool> isBackupServiceAvailable(BackupDestination destination) async {
    try {
      switch (destination) {
        case BackupDestination.local:
          return true; // Local backup is always available
        case BackupDestination.iCloud:
          if (!Platform.isIOS) return false;
          return await _iCloudManager.isICloudAvailable();
        case BackupDestination.googleDrive:
          return await _googleDriveManager.isDriveAvailable();
      }
    } catch (e) {
      logger.error('Error checking backup service availability: $e');
      return false;
    }
  }

  /// Create backup to specified destination
  Future<BackupResult> createBackup({
    required BackupDestination destination,
    required WidgetRef ref,
    Function(double)? onProgress,
    BuildContext? context,
  }) async {
    try {
      // Report initial progress
      onProgress?.call(0.1);

      // Check if destination is supported on current platform
      if (!await isBackupServiceAvailable(destination)) {
        logger.warning(
            'Backup destination $destination not supported on this platform');
        return BackupResult.notSupported;
      }

      // Create a timestamp for the backup file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = '${AppConstants.backupFilePrefix}$timestamp';

      // Get app directory to backup
      final appDir = await _storageService.getBackupAppDirectory();

      // Report progress
      onProgress?.call(0.2);

      // Create a ZIP file from the app directory
      final zipPath = await BackupArchiver.createZipFromDirectory(
        appDir,
        '$backupName.zip',
      );

      // Report progress
      onProgress?.call(0.6);

      // Upload the ZIP file to the selected destination
      switch (destination) {
        case BackupDestination.local:
          // Local backup is already done when we created the ZIP
          onProgress?.call(1.0);
          return BackupResult.success;

        case BackupDestination.iCloud:
          if (!Platform.isIOS) return BackupResult.notSupported;

          final result = await _iCloudManager.uploadToICloud(zipPath);
          onProgress?.call(1.0);

          return result == SyncICloudResult.completed
              ? BackupResult.success
              : BackupResult.failure;

        case BackupDestination.googleDrive:
          final result = await _googleDriveManager
              .uploadFileToDrive(File(zipPath), 'application/zip', backupName,
                  onProgress: (progress) {
            // Scale progress from 0.6 to 1.0
            final scaledProgress = 0.6 + (progress * 0.4);
            onProgress?.call(scaledProgress);
          });

          onProgress?.call(1.0);
          return result ? BackupResult.success : BackupResult.failure;
      }
    } catch (e) {
      logger.error('Error creating backup: $e');
      return BackupResult.failure;
    }
  }

  /// Restore backup from specified destination
  Future<BackupResult> restoreBackup({
    required BackupDestination source,
    String? backupId,
    Function(double)? onProgress,
    BuildContext? context,
  }) async {
    try {
      // Report initial progress
      onProgress?.call(0.1);

      // Check if source is supported on current platform
      if (!await isBackupServiceAvailable(source)) {
        logger.warning('Backup source $source not supported on this platform');
        return BackupResult.notSupported;
      }

      String? backupFilePath;

      // Get the backup file from the selected source
      switch (source) {
        case BackupDestination.local:
          // If no backupId provided, show file picker for local backup
          if (backupId == null) {
            logger.error('No backupId provided for local restore');
            return BackupResult.failure;
          }

          backupFilePath = backupId; // For local, backupId is the full path
          break;

        case BackupDestination.iCloud:
          if (!Platform.isIOS) return BackupResult.notSupported;

          // If no backupId provided, user needs to select from iCloud
          if (backupId == null) {
            logger.error('No backupId provided for iCloud restore');
            return BackupResult.failure;
          }

          // Download the file from iCloud
          backupFilePath = await _iCloudManager.downloadFromICloud(backupId);
          if (backupFilePath == null) {
            logger.error('Failed to download backup from iCloud');
            return BackupResult.failure;
          }
          break;

        case BackupDestination.googleDrive:
          // If no backupId provided, user needs to select from Google Drive
          if (backupId == null) {
            logger.error('No backupId provided for Google Drive restore');
            return BackupResult.failure;
          }

          // Download the file from Google Drive
          backupFilePath = await _googleDriveManager
              .downloadFileFromDrive(backupId, onProgress: (progress) {
            // Scale progress from 0.1 to 0.5
            final scaledProgress = 0.1 + (progress * 0.4);
            onProgress?.call(scaledProgress);
          });

          if (backupFilePath == null) {
            logger.error('Failed to download backup from Google Drive');
            return BackupResult.failure;
          }
          break;
      }

      // Report progress
      onProgress?.call(0.5);

      // Extract the zip file
      final extractedDir =
          await BackupArchiver.extractZipToDirectory(backupFilePath);

      // Report progress
      onProgress?.call(0.7);

      // Get the destination app directory
      final appDir = await _storageService.getBackupAppDirectory();

      // Delete current app data
      final appDirEntity = Directory(appDir);
      if (await appDirEntity.exists()) {
        // Delete contents but not the directory itself
        await for (final entity in appDirEntity.list()) {
          await entity.delete(recursive: true);
        }
      }

      // Report progress
      onProgress?.call(0.8);

      // Copy extracted files to app directory
      await _copyDirectory(extractedDir, appDir);

      // Clean up the extracted directory
      await Directory(extractedDir).delete(recursive: true);

      // Try to delete the temporary zip file if it's not needed anymore
      try {
        await File(backupFilePath).delete();
      } catch (e) {
        // Ignore cleanup errors
        logger.warning('Error cleaning up temporary backup file: $e');
      }

      // Report completion
      onProgress?.call(1.0);

      return BackupResult.success;
    } catch (e) {
      logger.error('Error restoring backup: $e');
      return BackupResult.failure;
    }
  }

  /// List available backups from a specific source
  Future<List<Map<String, dynamic>>> getAvailableBackups(
      BackupDestination source) async {
    try {
      switch (source) {
        case BackupDestination.local:
          return await _getLocalBackups();

        case BackupDestination.iCloud:
          if (!Platform.isIOS) return [];
          return await _iCloudManager.listICloudBackups();

        case BackupDestination.googleDrive:
          return await _googleDriveManager.listDriveBackups();
      }
    } catch (e) {
      logger.error('Error listing available backups: $e');
      return [];
    }
  }

  /// Get list of local backups
  Future<List<Map<String, dynamic>>> _getLocalBackups() async {
    try {
      final backupsDir = await _storageService.getBackupsPath();
      final backupsDirEntity = Directory(backupsDir);

      if (!await backupsDirEntity.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await backupsDirEntity
          .list()
          .where((entity) =>
              entity is File &&
              path
                  .basename(entity.path)
                  .startsWith(AppConstants.backupFilePrefix))
          .toList();

      List<Map<String, dynamic>> backups = [];

      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          final fileName = path.basename(file.path);
          final fileSize = await file.length();

          backups.add({
            'id': file.path,
            'name': fileName,
            'date': stat.modified.toString(),
            'size': FileUtils.formatFileSize(fileSize),
          });
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) {
        return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
      });

      return backups;
    } catch (e) {
      logger.error('Error getting local backups: $e');
      return [];
    }
  }

  /// Delete a backup from a specific source
  Future<bool> deleteBackup(BackupDestination source, String backupId) async {
    try {
      switch (source) {
        case BackupDestination.local:
          final file = File(backupId);
          if (await file.exists()) {
            await file.delete();
            return true;
          }
          return false;

        case BackupDestination.iCloud:
          if (!Platform.isIOS) return false;
          final result = await _iCloudManager.deleteICloudBackup(backupId);
          return result == SyncICloudResult.completed;

        case BackupDestination.googleDrive:
          return await _googleDriveManager.deleteFileFromDrive(backupId);
      }
    } catch (e) {
      logger.error('Error deleting backup: $e');
      return false;
    }
  }

  /// Helper method to copy a directory recursively
  Future<void> _copyDirectory(String source, String destination) async {
    final sourceDir = Directory(source);
    final destDir = Directory(destination);

    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: false)) {
      final String newPath = path.join(
        destination,
        path.basename(entity.path),
      );

      if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }
}

/// Provider for the cloud backup service
final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService();
});

/// Provider to track the last backup date
final lastBackupDateProvider = FutureProvider<DateTime?>((ref) async {
  try {
    final settingsBox = ref.watch(settingsBoxProvider);
    final lastBackupTimestamp =
        settingsBox.get('last_backup_timestamp') as int?;

    if (lastBackupTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp);
    }

    return null;
  } catch (e) {
    logger.error('Error getting last backup date: $e');
    return null;
  }
});

/// Provider for available backup destinations
final availableBackupDestinationsProvider =
    FutureProvider<List<BackupDestination>>((ref) async {
  final cloudBackupService = ref.watch(cloudBackupServiceProvider);

  final List<BackupDestination> available = [];

  // Local backup is always available
  available.add(BackupDestination.local);

  // Check iCloud availability (iOS only)
  if (Platform.isIOS &&
      await cloudBackupService
          .isBackupServiceAvailable(BackupDestination.iCloud)) {
    available.add(BackupDestination.iCloud);
  }

  // Check Google Drive availability
  if (await cloudBackupService
      .isBackupServiceAvailable(BackupDestination.googleDrive)) {
    available.add(BackupDestination.googleDrive);
  }

  return available;
});
