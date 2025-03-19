import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scanpro/utils/constants.dart';

/// A service class to handle local storage backup operations
class LocalBackupManager {
  static final LocalBackupManager _instance = LocalBackupManager._internal();
  factory LocalBackupManager() => _instance;

  LocalBackupManager._internal();

  /// Get the backup directory path
  Future<String> getBackupDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String backupDirPath = path.join(appDocDir.path, 'backups');

    // Ensure the directory exists
    final Directory backupDir = Directory(backupDirPath);
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDirPath;
  }

  /// Create a zip file of the provided directory
  Future<String> createZipFile(String sourceDir, String zipName) async {
    try {
      final backupDir = await getBackupDirectory();
      final String zipPath = path.join(backupDir, zipName);

      // Create an encoder
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // Add the entire directory to the zip
      await encoder.addDirectory(Directory(sourceDir));

      // Close the encoder
      encoder.close();

      return zipPath;
    } catch (e) {
      debugPrint('Error creating zip file: $e');
      rethrow;
    }
  }

  /// Extract a zip file to a directory
  Future<String> extractZipFile(String zipPath) async {
    try {
      // Create a temporary directory to extract to
      final tempDir = await Directory.systemTemp.createTemp('backup_extract_');
      final tempPath = tempDir.path;

      // Read the zip file
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract the contents
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(path.join(tempPath, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(path.join(tempPath, filename)).createSync(recursive: true);
        }
      }

      return tempPath;
    } catch (e) {
      debugPrint('Error extracting zip file: $e');
      rethrow;
    }
  }

  /// Save a backup file to local storage
  Future<String> saveBackupToLocal(String filePath) async {
    try {
      final backupDir = await getBackupDirectory();
      final String fileName = path.basename(filePath);
      final String targetPath = path.join(backupDir, fileName);

      // Copy the file to the backup directory
      await File(filePath).copy(targetPath);

      return targetPath;
    } catch (e) {
      debugPrint('Error saving backup to local storage: $e');
      rethrow;
    }
  }

  /// Get a backup file from local storage
  Future<String> pickBackupFile() async {
    try {
      // Let the user pick a backup file
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select Backup File',
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null) {
        throw Exception('No backup file selected');
      }

      return result.files.first.path!;
    } catch (e) {
      debugPrint('Error picking backup file: $e');
      rethrow;
    }
  }

  /// List available backups in local storage
  Future<List<Map<String, dynamic>>> listLocalBackups() async {
    try {
      final backupDir = await getBackupDirectory();

      // Get all files in the backup directory
      final List<FileSystemEntity> entities =
          await Directory(backupDir).list().toList();
      final List<File> files = entities
          .whereType<File>()
          .where((file) => path
              .basename(file.path)
              .startsWith(AppConstants.backupFilePrefix))
          .toList();

      // Get file metadata
      List<Map<String, dynamic>> backups = [];
      for (var file in files) {
        try {
          final FileStat stat = await file.stat();

          backups.add({
            'id': file.path,
            'name': path.basename(file.path),
            'date': stat.modified.toString(),
            'size': _formatFileSize(stat.size),
          });
        } catch (e) {
          debugPrint('Error getting metadata for file ${file.path}: $e');
        }
      }

      // Sort by modification date (newest first)
      backups.sort((a, b) {
        return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
      });

      return backups;
    } catch (e) {
      debugPrint('Error listing local backups: $e');
      return [];
    }
  }

  /// Delete a backup file from local storage
  Future<bool> deleteLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting local backup: $e');
      return false;
    }
  }

  /// Share a backup file
  Future<void> shareBackup(String filePath) async {
    try {
      // Implementation depends on platform-specific sharing mechanism
      // For example, using the share_plus package:
      // return Share.shareFiles([filePath], text: 'Easy Scan Backup');

      // This is a placeholder for actual implementation
      debugPrint('Sharing backup file: $filePath');
    } catch (e) {
      debugPrint('Error sharing backup: $e');
    }
  }

  // Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
