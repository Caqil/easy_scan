import 'dart:io';
import 'package:flutter/material.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path/path.dart' as path;
import 'package:scanpro/main.dart';
import 'package:scanpro/utils/constants.dart';

// Enum to represent the connection state of iCloud
enum ICloudState {
  notConnected, // iCloud is not connected
  connected, // iCloud is successfully connected
  connecting, // iCloud is in the process of connecting
}

// Enum to represent the result of syncing with iCloud
enum SyncICloudResult {
  failed, // Sync operation failed
  completed, // Sync operation completed successfully
  skipped // Sync operation was skipped
}

/// A service class to handle iCloud backup operations
class ICloudBackupManager {
  static final ICloudBackupManager _instance = ICloudBackupManager._internal();
  factory ICloudBackupManager() => _instance;

  ICloudBackupManager._internal();

  final ICloudStorage _iCloudStorage = ICloudStorage();
  ICloudState _iCloudState = ICloudState.notConnected;

  // Get the current iCloud state
  ICloudState get state => _iCloudState;

  /// Initialize iCloud service
  Future<bool> initialize() async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      _iCloudState = ICloudState.connecting;

      // Check if iCloud is available
      final bool isAvailable = await isICloudAvailable();
      if (isAvailable) {
        // Enable iCloud document storage if available
        final bool enabled = await _iCloudStorage.enableICloudDocumentStorage();
        _iCloudState =
            enabled ? ICloudState.connected : ICloudState.notConnected;
        return enabled;
      } else {
        _iCloudState = ICloudState.notConnected;
        return false;
      }
    } catch (e) {
      logger.error('Error initializing iCloud: $e');
      _iCloudState = ICloudState.notConnected;
      return false;
    }
  }

  /// Check if iCloud is available for the current device
  Future<bool> isICloudAvailable() async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      return await _iCloudStorage.isICloudAvailable();
    } catch (e) {
      logger.error('Error checking iCloud availability: $e');
      return false;
    }
  }

  /// Upload a file to iCloud
  Future<SyncICloudResult> uploadToICloud(String filePath) async {
    try {
      if (!Platform.isIOS) {
        return SyncICloudResult.skipped;
      }

      // Check if iCloud is available
      if (_iCloudState != ICloudState.connected) {
        final bool isInitialized = await initialize();
        if (!isInitialized) {
          return SyncICloudResult.failed;
        }
      }

      // Get file name
      final String fileName = path.basename(filePath);

      // Upload file to iCloud
      final bool success = await _iCloudStorage.uploadFileToICloud(
        sourcePath: filePath,
        destinationFileName: fileName,
        destinationContainerIdentifier: AppConstants.iCloudContainerId,
      );

      return success ? SyncICloudResult.completed : SyncICloudResult.failed;
    } catch (e) {
      logger.error('Error uploading to iCloud: $e');
      return SyncICloudResult.failed;
    }
  }

  /// Upload multiple files to iCloud
  Future<SyncICloudResult> uploadMultipleFilesToICloud(
      List<String> filePaths) async {
    try {
      if (!Platform.isIOS) {
        return SyncICloudResult.skipped;
      }

      // Check if iCloud is available
      if (_iCloudState != ICloudState.connected) {
        final bool isInitialized = await initialize();
        if (!isInitialized) {
          return SyncICloudResult.failed;
        }
      }

      bool allSucceeded = true;

      // Upload each file to iCloud
      for (String filePath in filePaths) {
        final String fileName = path.basename(filePath);

        final bool success = await _iCloudStorage.uploadFileToICloud(
          sourcePath: filePath,
          destinationFileName: fileName,
          destinationContainerIdentifier: AppConstants.iCloudContainerId,
        );

        if (!success) {
          allSucceeded = false;
        }
      }

      return allSucceeded
          ? SyncICloudResult.completed
          : SyncICloudResult.failed;
    } catch (e) {
      logger.error('Error uploading multiple files to iCloud: $e');
      return SyncICloudResult.failed;
    }
  }

  /// Download a file from iCloud
  Future<String?> downloadFromICloud(String fileName) async {
    try {
      if (!Platform.isIOS) {
        return null;
      }

      // Check if iCloud is available
      if (_iCloudState != ICloudState.connected) {
        final bool isInitialized = await initialize();
        if (!isInitialized) {
          return null;
        }
      }

      // Create a temporary directory for the downloaded file
      final String tempPath = await _createTempPath(fileName);

      // Download the file
      final bool success = await _iCloudStorage.downloadFileFromICloud(
        sourceFileName: fileName,
        destinationPath: tempPath,
        sourceContainerIdentifier: AppConstants.iCloudContainerId,
      );

      if (!success) {
        logger.error('Failed to download file from iCloud: $fileName');
        return null;
      }

      logger.info('Downloaded file from iCloud: $tempPath');
      return tempPath;
    } catch (e) {
      logger.error('Error downloading from iCloud: $e');
      return null;
    }
  }

  /// Create a temporary path for downloads
  Future<String> _createTempPath(String fileName) async {
    final Directory tempDir = await Directory.systemTemp.createTemp();
    return path.join(tempDir.path, fileName);
  }

  /// Get all cloud files
  Future<List<ICloudFile>> getCloudFiles() async {
    try {
      if (!Platform.isIOS) {
        return [];
      }

      // Check if iCloud is available
      if (_iCloudState != ICloudState.connected) {
        final bool isInitialized = await initialize();
        if (!isInitialized) {
          return [];
        }
      }

      // Get cloud files
      final files = await _iCloudStorage.getICloudDocuments(
        containerIdentifier: AppConstants.iCloudContainerId,
      );

      logger.info('Cloud files found: ${files.length}');

      // Filter for backup files if needed
      final backupFiles = files
          .where((file) => file.name.startsWith(AppConstants.backupFilePrefix))
          .toList();

      return backupFiles;
    } catch (e) {
      logger.error('Error getting cloud files: $e');
      return [];
    }
  }

  /// List available backups in iCloud
  Future<List<Map<String, dynamic>>> listICloudBackups() async {
    try {
      if (!Platform.isIOS) {
        return [];
      }

      // Use getCloudFiles to get all files
      final backupFiles = await getCloudFiles();

      // Create backup metadata list
      List<Map<String, dynamic>> backups = [];
      for (var file in backupFiles) {
        backups.add({
          'id': file.name,
          'name': file.name,
          'date': file.modifiedDate?.toString() ?? 'Unknown',
          'size': _formatSize(file.size),
        });
      }

      // Sort by date (newest first)
      backups.sort((a, b) {
        if (a['date'] == 'Unknown' || b['date'] == 'Unknown') {
          return 0;
        }
        return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
      });

      return backups;
    } catch (e) {
      logger.error('Error listing iCloud backups: $e');
      return [];
    }
  }

  /// Delete a backup file from iCloud
  Future<SyncICloudResult> deleteICloudBackup(String fileName) async {
    try {
      if (!Platform.isIOS) {
        return SyncICloudResult.skipped;
      }

      // Check if iCloud is available
      if (_iCloudState != ICloudState.connected) {
        final bool isInitialized = await initialize();
        if (!isInitialized) {
          return SyncICloudResult.failed;
        }
      }

      // Delete the file
      final bool success = await _iCloudStorage.deleteICloudFile(
        fileName: fileName,
        containerIdentifier: AppConstants.iCloudContainerId,
      );

      return success ? SyncICloudResult.completed : SyncICloudResult.failed;
    } catch (e) {
      logger.error('Error deleting iCloud backup: $e');
      return SyncICloudResult.failed;
    }
  }

  /// Delete multiple backup files from iCloud
  Future<SyncICloudResult> deleteMultipleICloudBackups(
      List<String> fileNames) async {
    try {
      if (!Platform.isIOS) {
        return SyncICloudResult.skipped;
      }

      // Check if iCloud is available
      if (_iCloudState != ICloudState.connected) {
        final bool isInitialized = await initialize();
        if (!isInitialized) {
          return SyncICloudResult.failed;
        }
      }

      bool allSucceeded = true;

      // Delete each file
      for (String fileName in fileNames) {
        final bool success = await _iCloudStorage.deleteICloudFile(
          fileName: fileName,
          containerIdentifier: AppConstants.iCloudContainerId,
        );

        if (!success) {
          allSucceeded = false;
        }
      }

      return allSucceeded
          ? SyncICloudResult.completed
          : SyncICloudResult.failed;
    } catch (e) {
      logger.error('Error deleting multiple iCloud backups: $e');
      return SyncICloudResult.failed;
    }
  }

  // Helper method to format file size
  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
