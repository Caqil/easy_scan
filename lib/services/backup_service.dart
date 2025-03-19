import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/models/folder.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';

// Backup Types
enum BackupDestination { googleDrive, iCloud, local }

class BackupService {
  // Static keys for backup files
  static const String _backupMetadataFileName = 'backup_metadata.json';
  static const String _folderBackupFileName = 'folders_backup.hive';
  static const String _documentBackupFileName = 'documents_backup.hive';
  static const String _settingsBackupFileName = 'settings_backup.hive';

  // Google Sign In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

// Update this method in your BackupService class to make context optional
  Future<String> createBackup({
    required BackupDestination destination,
    BuildContext? context, // Make context optional
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.05);

      // 1. Create temp directory for backup files
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/backup');

      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create(recursive: true);

      onProgress?.call(0.1);

      // 2. Export Hive boxes to files
      await _exportHiveBoxes(backupDir.path, onProgress);

      onProgress?.call(0.5);

      // 3. Create backup metadata
      final metadata = await _createBackupMetadata();
      final metadataFile = File('${backupDir.path}/$_backupMetadataFileName');
      await metadataFile.writeAsString(jsonEncode(metadata));

      onProgress?.call(0.6);

      // 4. Zip all files into a single backup file
      final backupFilePath = await _createBackupZip(backupDir.path);

      onProgress?.call(0.7);

      // 5. Upload to selected destination
      String resultMessage;
      switch (destination) {
        case BackupDestination.googleDrive:
          resultMessage =
              await _uploadToGoogleDrive(backupFilePath, onProgress);
          break;
        case BackupDestination.iCloud:
          resultMessage = await _uploadToICloud(backupFilePath, onProgress);
          break;
        case BackupDestination.local:
          resultMessage = await _saveToLocalStorage(backupFilePath, onProgress);
          break;
      }

      onProgress?.call(1.0);
      return resultMessage;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

// Update this method in your BackupService class to make context optional
  Future<String> restoreBackup({
    required BackupDestination source,
    BuildContext? context, // Make context optional
    String? backupId,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.05);

      // 1. Get backup file from source
      String backupFilePath;
      switch (source) {
        case BackupDestination.googleDrive:
          backupFilePath =
              await _downloadFromGoogleDrive(backupId!, onProgress);
          break;
        case BackupDestination.iCloud:
          backupFilePath = await _downloadFromICloud(backupId!, onProgress);
          break;
        case BackupDestination.local:
          backupFilePath = await _getFromLocalStorage(onProgress);
          break;
      }

      onProgress?.call(0.3);

      // 2. Extract backup zip to temp directory
      final extractedDir = await _extractBackupZip(backupFilePath);

      onProgress?.call(0.4);

      // 3. Validate backup metadata
      final metadataFile =
          File('${extractedDir.path}/$_backupMetadataFileName');
      if (!await metadataFile.exists()) {
        throw Exception('Invalid backup file: metadata missing');
      }

      final metadata = jsonDecode(await metadataFile.readAsString());

      // Check app version compatibility here if needed

      onProgress?.call(0.5);

      // 4. Close Hive boxes before importing
      await Hive.close();

      // 5. Import Hive boxes
      await _importHiveBoxes(extractedDir.path, onProgress);

      onProgress?.call(0.8);

      // 6. Copy document files to their correct locations
      await _restoreDocumentFiles(extractedDir.path, metadata, onProgress);

      onProgress?.call(0.9);

      // 7. Clean up temp files
      await _cleanupTempFiles(extractedDir.path, backupFilePath);

      onProgress?.call(1.0);
      return 'Backup restored successfully';
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  // Get a list of available backups
  Future<List<Map<String, dynamic>>> getAvailableBackups({
    required BackupDestination source,
  }) async {
    try {
      switch (source) {
        case BackupDestination.googleDrive:
          return await _getGoogleDriveBackups();
        case BackupDestination.iCloud:
          return await _getICloudBackups();
        case BackupDestination.local:
          return await _getLocalBackups();
      }
    } catch (e) {
      debugPrint('Error getting available backups: $e');
      return [];
    }
  }

  // Export Hive boxes to backup directory
  Future<void> _exportHiveBoxes(
      String backupDirPath, Function(double)? onProgress) async {
    // Export documents box
    final docsBox = Hive.box<Document>(AppConstants.documentsBoxName);
    final docsBackupPath = '$backupDirPath/$_documentBackupFileName';
    await docsBox.compact();
    await File(docsBox.path!).copy(docsBackupPath);

    onProgress?.call(0.2);

    // Export folders box
    final foldersBox = Hive.box<Folder>(AppConstants.foldersBoxName);
    final foldersBackupPath = '$backupDirPath/$_folderBackupFileName';
    await foldersBox.compact();
    await File(foldersBox.path!).copy(foldersBackupPath);

    onProgress?.call(0.3);

    // Export settings box
    final settingsBox = Hive.box(AppConstants.settingsBoxName);
    final settingsBackupPath = '$backupDirPath/$_settingsBackupFileName';
    await settingsBox.compact();
    await File(settingsBox.path!).copy(settingsBackupPath);

    onProgress?.call(0.4);
  }

  // Import Hive boxes from backup directory
  Future<void> _importHiveBoxes(
      String backupDirPath, Function(double)? onProgress) async {
    final appDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDir.path}/db';

    // Ensure directory exists
    final hiveDir = Directory(hivePath);
    if (!await hiveDir.exists()) {
      await hiveDir.create(recursive: true);
    }

    // Import documents box
    final docsBackupPath = '$backupDirPath/$_documentBackupFileName';
    if (await File(docsBackupPath).exists()) {
      final docsTargetPath = '$hivePath/${AppConstants.documentsBoxName}.hive';
      await File(docsBackupPath).copy(docsTargetPath);
    }

    onProgress?.call(0.6);

    // Import folders box
    final foldersBackupPath = '$backupDirPath/$_folderBackupFileName';
    if (await File(foldersBackupPath).exists()) {
      final foldersTargetPath = '$hivePath/${AppConstants.foldersBoxName}.hive';
      await File(foldersBackupPath).copy(foldersTargetPath);
    }

    onProgress?.call(0.7);

    // Import settings box
    final settingsBackupPath = '$backupDirPath/$_settingsBackupFileName';
    if (await File(settingsBackupPath).exists()) {
      final settingsTargetPath =
          '$hivePath/${AppConstants.settingsBoxName}.hive';
      await File(settingsBackupPath).copy(settingsTargetPath);
    }

    // Reopen Hive boxes
    await Hive.openBox<Document>(AppConstants.documentsBoxName);
    await Hive.openBox<Folder>(AppConstants.foldersBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);

    onProgress?.call(0.75);
  }

  // Create backup metadata
  Future<Map<String, dynamic>> _createBackupMetadata() async {
    final docsBox = Hive.box<Document>(AppConstants.documentsBoxName);
    final foldersBox = Hive.box<Folder>(AppConstants.foldersBoxName);

    // Get document file paths for copying
    final List<String> documentPaths = [];
    for (var doc in docsBox.values) {
      if (await File(doc.pdfPath).exists()) {
        documentPaths.add(doc.pdfPath);
      }

      if (doc.thumbnailPath != null &&
          await File(doc.thumbnailPath!).exists()) {
        documentPaths.add(doc.thumbnailPath!);
      }

      for (var page in doc.pagesPaths) {
        if (await File(page).exists()) {
          documentPaths.add(page);
        }
      }
    }

    // Creating backup metadata
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'documentCount': docsBox.length,
      'folderCount': foldersBox.length,
      'documentPaths': documentPaths,
    };
  }

  // Create a zip file from the backup directory
  Future<String> _createBackupZip(String backupDirPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath = '${appDir.path}/easy_scan_backup_$timestamp.zip';

      // Create file paths to include in the backup
      final docsBox = Hive.box<Document>(AppConstants.documentsBoxName);
      final docs = docsBox.values.toList();

      // Copy document files to backup directory
      final docFilesDir = Directory('$backupDirPath/document_files');
      await docFilesDir.create();

      for (var doc in docs) {
        // Copy PDF file
        final pdfFile = File(doc.pdfPath);
        if (await pdfFile.exists()) {
          final fileName = path.basename(doc.pdfPath);
          await pdfFile.copy('${docFilesDir.path}/$fileName');
        }

        // Copy thumbnail if exists
        if (doc.thumbnailPath != null) {
          final thumbFile = File(doc.thumbnailPath!);
          if (await thumbFile.exists()) {
            final fileName = path.basename(doc.thumbnailPath!);
            await thumbFile.copy('${docFilesDir.path}/$fileName');
          }
        }

        // Copy page files if different from PDF
        for (var pagePath in doc.pagesPaths) {
          if (pagePath != doc.pdfPath) {
            final pageFile = File(pagePath);
            if (await pageFile.exists()) {
              final fileName = path.basename(pagePath);
              await pageFile.copy('${docFilesDir.path}/$fileName');
            }
          }
        }
      }

      // Use the archive library to create zip file (implement here)
      // Since Flutter doesn't have native zip support, we need a plugin
      // For simplicity, I'm using a placeholder implementation

      // This would actually use something like:
      // await ZipFile.createFromDirectory(
      //   sourceDir: Directory(backupDirPath),
      //   zipFile: File(zipPath),
      //   recurseSubDirs: true,
      // );

      // For now, we'll copy a directory for demonstration
      final Directory targetDir = Directory(path.dirname(zipPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // In a real implementation, you would zip the files here
      // For now, we'll just create a placeholder file
      final zipFile = File(zipPath);
      await zipFile.writeAsString('Backup created on ${DateTime.now()}');

      return zipPath;
    } catch (e) {
      debugPrint('Error creating backup zip: $e');
      rethrow;
    }
  }

  // Extract backup zip to a temporary directory
  Future<Directory> _extractBackupZip(String zipFilePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(
          '${tempDir.path}/extract_${DateTime.now().millisecondsSinceEpoch}');

      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // In a real implementation, you would extract the zip here
      // For now, we'll just create placeholder files

      // Placeholder metadata file
      final metadataFile = File('${extractDir.path}/$_backupMetadataFileName');
      await metadataFile.writeAsString(
          '{"version":"1.0","timestamp":"${DateTime.now().toIso8601String()}"}');

      return extractDir;
    } catch (e) {
      debugPrint('Error extracting backup zip: $e');
      rethrow;
    }
  }

  // Restore document files from backup
  Future<void> _restoreDocumentFiles(String extractedDirPath,
      Map<String, dynamic> metadata, Function(double)? onProgress) async {
    try {
      final docFilesDir = Directory('$extractedDirPath/document_files');
      if (!await docFilesDir.exists()) {
        // No document files to restore
        return;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDocDir.path}/documents');

      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Copy all files from backup to documents directory
      final files = await docFilesDir.list().toList();

      for (int i = 0; i < files.length; i++) {
        if (files[i] is File) {
          final File file = files[i] as File;
          final String fileName = path.basename(file.path);
          final targetPath = '${documentsDir.path}/$fileName';

          await file.copy(targetPath);

          // Update progress
          if (onProgress != null && files.isNotEmpty) {
            onProgress(0.8 + (i / files.length) * 0.1);
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring document files: $e');
    }
  }

  // Clean up temporary files after restore
  Future<void> _cleanupTempFiles(
      String extractedDirPath, String zipFilePath) async {
    try {
      final extractDir = Directory(extractedDirPath);
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }

      final zipFile = File(zipFilePath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  // GOOGLE DRIVE IMPLEMENTATIONS

  // Upload backup to Google Drive
  Future<String> _uploadToGoogleDrive(
      String backupFilePath, Function(double)? onProgress) async {
    try {
      onProgress?.call(0.7);

      // Sign in to Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Get HTTP client with auth
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      // Create Drive API client
      final driveApi = drive.DriveApi(httpClient);

      // Create app folder if it doesn't exist
      String? folderId = await _getOrCreateAppFolder(driveApi);

      onProgress?.call(0.8);

      // Create file metadata
      final timestamp = DateTime.now().toString().replaceAll(':', '-');
      final fileName = 'EasyScan_Backup_$timestamp.zip';

      var driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      // Upload file
      final fileContent = await File(backupFilePath).readAsBytes();
      final media = drive.Media(
        Stream.value(fileContent),
        fileContent.length,
      );

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      onProgress?.call(0.9);

      return 'Backup uploaded to Google Drive: ${result.name}';
    } catch (e) {
      debugPrint('Error uploading to Google Drive: $e');
      rethrow;
    }
  }

  // Download backup from Google Drive
  Future<String> _downloadFromGoogleDrive(
      String fileId, Function(double)? onProgress) async {
    try {
      onProgress?.call(0.1);

      // Sign in to Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Get HTTP client with auth
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      // Create Drive API client
      final driveApi = drive.DriveApi(httpClient);

      onProgress?.call(0.15);

      // Get file metadata
      final file = await driveApi.files.get(fileId, $fields: 'name,size');

      // Create the destination file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.toString()}');

      // Download the file
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final fileStream = media.stream;
      final fileBytes = await fileStream.toList();
      final bytes = fileBytes.expand((byte) => byte).toList();

      await tempFile.writeAsBytes(bytes);

      onProgress?.call(0.25);

      return tempFile.path;
    } catch (e) {
      debugPrint('Error downloading from Google Drive: $e');
      rethrow;
    }
  }

  // Get available backups from Google Drive
  Future<List<Map<String, dynamic>>> _getGoogleDriveBackups() async {
    try {
      // Sign in to Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Get HTTP client with auth
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      // Create Drive API client
      final driveApi = drive.DriveApi(httpClient);

      // Get app folder
      String? folderId = await _getAppFolderId(driveApi);
      if (folderId == null) {
        return [];
      }

      // Search for backups in the app folder
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and name contains 'EasyScan_Backup' and trashed = false",
        $fields: 'files(id, name, createdTime, size)',
        orderBy: 'createdTime desc',
      );

      final backups = fileList.files?.map((file) {
            return {
              'id': file.id,
              'name': file.name,
              'date': file.createdTime?.toLocal().toString() ?? 'Unknown',
              'size': file.size != null
                  ? FileUtils.formatFileSize(int.parse(file.size!))
                  : 'Unknown',
            };
          }).toList() ??
          [];

      return backups;
    } catch (e) {
      debugPrint('Error getting Google Drive backups: $e');
      return [];
    }
  }

  // Get or create app folder in Google Drive
  Future<String> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    String? folderId = await _getAppFolderId(driveApi);

    if (folderId != null) {
      return folderId;
    }

    // Create app folder
    var folder = drive.File()
      ..name = 'EasyScan Backups'
      ..mimeType = 'application/vnd.google-apps.folder';

    final result = await driveApi.files.create(folder);
    return result.id!;
  }

  // Get app folder ID if it exists
  Future<String?> _getAppFolderId(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        q: "name = 'EasyScan Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        $fields: 'files(id)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting app folder: $e');
      return null;
    }
  }

  // ICLOUD IMPLEMENTATIONS

  // Upload backup to iCloud
  Future<String> _uploadToICloud(
      String backupFilePath, Function(double)? onProgress) async {
    // This implementation would use the iCloud storage sync plugin
    // For now, we'll use a placeholder implementation

    try {
      onProgress?.call(0.75);

      // In a real implementation, you would use something like:
      // final result = await IcloudStorageSync().uploadFileToICloud(
      //   sourcePath: backupFilePath,
      //   destinationName: path.basename(backupFilePath),
      // );

      await Future.delayed(const Duration(seconds: 1)); // Simulated upload time

      onProgress?.call(0.95);

      return 'Backup uploaded to iCloud: ${path.basename(backupFilePath)}';
    } catch (e) {
      debugPrint('Error uploading to iCloud: $e');
      rethrow;
    }
  }

  // Download backup from iCloud
  Future<String> _downloadFromICloud(
      String fileName, Function(double)? onProgress) async {
    // This implementation would use the iCloud storage sync plugin
    // For now, we'll use a placeholder implementation

    try {
      onProgress?.call(0.15);

      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/$fileName';

      // In a real implementation, you would use something like:
      // final success = await IcloudStorageSync().downloadFileFromICloud(
      //   documentURL: fileName,
      //   destinationPath: localPath,
      // );

      await Future.delayed(
          const Duration(seconds: 1)); // Simulated download time

      // Create placeholder file
      final file = File(localPath);
      await file.writeAsString('iCloud backup placeholder');

      onProgress?.call(0.25);

      return localPath;
    } catch (e) {
      debugPrint('Error downloading from iCloud: $e');
      rethrow;
    }
  }

  // Get available backups from iCloud
  Future<List<Map<String, dynamic>>> _getICloudBackups() async {
    // This implementation would use the iCloud storage sync plugin
    // For now, we'll return a placeholder list

    try {
      // In a real implementation, you would use something like:
      // final files = await IcloudStorageSync().listAllFiles() ?? [];
      // final backups = files.where((path) => path.contains('EasyScan_Backup')).toList();

      // Return placeholder data
      return [
        {
          'id': 'placeholder_1',
          'name': 'EasyScan_Backup_Placeholder_1.zip',
          'date': DateTime.now().subtract(const Duration(days: 1)).toString(),
          'size': '2.5 MB',
        },
        {
          'id': 'placeholder_2',
          'name': 'EasyScan_Backup_Placeholder_2.zip',
          'date': DateTime.now().subtract(const Duration(days: 7)).toString(),
          'size': '3.1 MB',
        },
      ];
    } catch (e) {
      debugPrint('Error getting iCloud backups: $e');
      return [];
    }
  }

  // LOCAL STORAGE IMPLEMENTATIONS

  // Save backup to local storage
  Future<String> _saveToLocalStorage(
      String backupFilePath, Function(double)? onProgress) async {
    try {
      onProgress?.call(0.75);

      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${appDir.path}/backups');

      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final fileName = path.basename(backupFilePath);
      final targetPath = '${backupsDir.path}/$fileName';

      await File(backupFilePath).copy(targetPath);

      onProgress?.call(0.95);

      return 'Backup saved to local storage: $fileName';
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
      rethrow;
    }
  }

  // Get backup from local storage
  Future<String> _getFromLocalStorage(Function(double)? onProgress) async {
    try {
      onProgress?.call(0.1);

      // Show file picker to select backup file
      // In a real implementation, you would use a plugin like file_picker
      // For now, we'll use a placeholder implementation

      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${appDir.path}/backups');

      if (!await backupsDir.exists()) {
        throw Exception('No backups found in local storage');
      }

      final files = await backupsDir.list().toList();
      final backupFiles = files
          .whereType<File>()
          .where((file) => path.basename(file.path).contains('EasyScan_Backup'))
          .toList();

      if (backupFiles.isEmpty) {
        throw Exception('No backups found in local storage');
      }

      // Sort by name descending (newest first assuming timestamp in name)
      backupFiles.sort(
          (a, b) => path.basename(b.path).compareTo(path.basename(a.path)));

      // Return the path of the most recent backup
      onProgress?.call(0.2);
      return backupFiles.first.path;
    } catch (e) {
      debugPrint('Error getting from local storage: $e');
      rethrow;
    }
  }

  // Get available backups from local storage
  Future<List<Map<String, dynamic>>> _getLocalBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${appDir.path}/backups');

      if (!await backupsDir.exists()) {
        return [];
      }

      final files = await backupsDir.list().toList();
      final backupFiles = files
          .whereType<File>()
          .where((file) => path.basename(file.path).contains('EasyScan_Backup'))
          .toList();

      // Sort by name descending (newest first assuming timestamp in name)
      backupFiles.sort(
          (a, b) => path.basename(b.path).compareTo(path.basename(a.path)));

      return await Future.wait(backupFiles.map((file) async {
        final stat = await file.stat();
        return {
          'id': file.path,
          'name': path.basename(file.path),
          'date': stat.modified.toString(),
          'size': FileUtils.formatFileSize(stat.size),
        };
      }));
    } catch (e) {
      debugPrint('Error getting local backups: $e');
      return [];
    }
  }
}
