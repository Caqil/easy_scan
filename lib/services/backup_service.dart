// import 'dart:convert';
// import 'dart:io';
// import 'package:archive/archive.dart';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
// import 'package:scanpro/main.dart';
// import 'package:scanpro/models/document.dart';
// import 'package:scanpro/models/folder.dart';
// import 'package:scanpro/utils/backup_archive.dart';
// import 'package:scanpro/utils/constants.dart';
// import 'package:scanpro/utils/file_utils.dart';
// import 'package:scanpro/utils/local_storage_manager.dart';

// // Backup Types
// enum BackupDestination { googleDrive, local }

// class BackupService {
//   // Static keys for backup files
//   static const String _backupMetadataFileName = 'backup_metadata.json';
//   static const String _folderBackupFileName = 'folders_backup.hive';
//   static const String _documentBackupFileName = 'documents_backup.hive';
//   static const String _settingsBackupFileName = 'settings_backup.hive';

//   // Google Sign In instance
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       'https://www.googleapis.com/auth/drive.file',
//     ],
//   );
//   Future<String> createBackup({
//     required BackupDestination destination,
//     BuildContext? context,
//     Function(double)? onProgress,
//   }) async {
//     try {
//       onProgress?.call(0.05);
//       final tempDir = await getTemporaryDirectory();
//       final backupDir = Directory('${tempDir.path}/backup');

//       if (await backupDir.exists()) {
//         await backupDir.delete(recursive: true);
//       }
//       await backupDir.create(recursive: true);

//       onProgress?.call(0.1);
//       await _exportHiveBoxes(backupDir.path, onProgress);
//       onProgress?.call(0.5);

//       final metadata = await _createBackupMetadata();
//       final metadataFile = File('${backupDir.path}/$_backupMetadataFileName');
//       await metadataFile.writeAsString(jsonEncode(metadata));

//       final settingsBox = Hive.box(AppConstants.settingsBoxName);
//       debugPrint('Settings box before backup: ${settingsBox.toMap()}');
//       final appSettings = settingsBox.get('app_settings');
//       debugPrint('AppSettings instance: $appSettings');

//       onProgress?.call(0.6);
//       final backupFilePath = await _createBackupZip(backupDir.path);
//       onProgress?.call(0.7);

//       String resultMessage;
//       switch (destination) {
//         case BackupDestination.googleDrive:
//           resultMessage =
//               await _uploadToGoogleDrive(backupFilePath, onProgress);
//           break;
//         case BackupDestination.local:
//           resultMessage = await _saveToLocalStorage(backupFilePath, onProgress);
//           break;
//       }

//       onProgress?.call(1.0);
//       return resultMessage;
//     } catch (e) {
//       debugPrint('Error creating backup: $e');
//       rethrow;
//     }
//   }

// // Update this method in your BackupService class to make context optional
//   Future<String> restoreBackup({
//     required BackupDestination source,
//     BuildContext? context, // Make context optional
//     String? backupId,
//     Function(double)? onProgress,
//   }) async {
//     try {
//       onProgress?.call(0.05);

//       // 1. Get backup file from source
//       String backupFilePath;
//       switch (source) {
//         case BackupDestination.googleDrive:
//           backupFilePath =
//               await _downloadFromGoogleDrive(backupId!, onProgress);
//           break;

//         case BackupDestination.local:
//           backupFilePath = await _getFromLocalStorage(onProgress);
//           break;
//       }

//       onProgress?.call(0.3);
//       await _inspectZipFile(backupFilePath);
//       final extractedDir = await _extractBackupZip(backupFilePath);

//       onProgress?.call(0.4);

//       // 3. Validate backup metadata
//       final metadataFile =
//           File('${extractedDir.path}/$_backupMetadataFileName');
//       if (!await metadataFile.exists()) {
//         throw Exception('Invalid backup file: metadata missing');
//       }

//       final metadata = jsonDecode(await metadataFile.readAsString());

//       // Check app version compatibility here if needed

//       onProgress?.call(0.5);

//       // 4. Close Hive boxes before importing
//       await Hive.close();

//       // 5. Import Hive boxes
//       await _importHiveBoxes(extractedDir.path, onProgress);

//       onProgress?.call(0.8);

//       // 6. Copy document files to their correct locations
//       await _restoreDocumentFiles(extractedDir.path, metadata, onProgress);

//       onProgress?.call(0.9);

//       // 7. Clean up temp files
//       await _cleanupTempFiles(extractedDir.path, backupFilePath);

//       onProgress?.call(1.0);
//       return 'Backup restored successfully';
//     } catch (e) {
//       debugPrint('Error restoring backup: $e');
//       rethrow;
//     }
//   }

//   // Get a list of available backups
//   Future<List<Map<String, dynamic>>> getAvailableBackups({
//     required BackupDestination source,
//   }) async {
//     try {
//       switch (source) {
//         case BackupDestination.googleDrive:
//           return await _getGoogleDriveBackups();
//         case BackupDestination.local:
//           return await _getLocalBackups();
//       }
//     } catch (e) {
//       debugPrint('Error getting available backups: $e');
//       return [];
//     }
//   }

//   // Export Hive boxes to backup directory
//   Future<void> _exportHiveBoxes(
//       String backupDirPath, Function(double)? onProgress) async {
//     // Export documents box
//     final docsBox = Hive.box<Document>(AppConstants.documentsBoxName);
//     final docsBackupPath = '$backupDirPath/$_documentBackupFileName';
//     await docsBox.compact();
//     await File(docsBox.path!).copy(docsBackupPath);

//     onProgress?.call(0.2);

//     // Export folders box
//     final foldersBox = Hive.box<Folder>(AppConstants.foldersBoxName);
//     final foldersBackupPath = '$backupDirPath/$_folderBackupFileName';
//     await foldersBox.compact();
//     await File(foldersBox.path!).copy(foldersBackupPath);

//     onProgress?.call(0.3);

//     // Export settings box
//     final settingsBox = Hive.box(AppConstants.settingsBoxName);
//     final settingsBackupPath = '$backupDirPath/$_settingsBackupFileName';
//     await settingsBox.compact();
//     await File(settingsBox.path!).copy(settingsBackupPath);

//     onProgress?.call(0.4);
//   }

//   // Import Hive boxes from backup directory
//   Future<void> _importHiveBoxes(
//       String backupDirPath, Function(double)? onProgress) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final hivePath = '${appDir.path}/db';

//     // Ensure directory exists
//     final hiveDir = Directory(hivePath);
//     if (!await hiveDir.exists()) {
//       await hiveDir.create(recursive: true);
//     }

//     // Import documents box
//     final docsBackupPath = '$backupDirPath/$_documentBackupFileName';
//     if (await File(docsBackupPath).exists()) {
//       final docsTargetPath = '$hivePath/${AppConstants.documentsBoxName}.hive';
//       await File(docsBackupPath).copy(docsTargetPath);
//     }

//     onProgress?.call(0.6);

//     // Import folders box
//     final foldersBackupPath = '$backupDirPath/$_folderBackupFileName';
//     if (await File(foldersBackupPath).exists()) {
//       final foldersTargetPath = '$hivePath/${AppConstants.foldersBoxName}.hive';
//       await File(foldersBackupPath).copy(foldersTargetPath);
//     }

//     onProgress?.call(0.7);

//     // Import settings box
//     final settingsBackupPath = '$backupDirPath/$_settingsBackupFileName';
//     if (await File(settingsBackupPath).exists()) {
//       final settingsTargetPath =
//           '$hivePath/${AppConstants.settingsBoxName}.hive';
//       await File(settingsBackupPath).copy(settingsTargetPath);
//     }

//     // Reopen Hive boxes
//     await Hive.openBox<Document>(AppConstants.documentsBoxName);
//     await Hive.openBox<Folder>(AppConstants.foldersBoxName);
//     await Hive.openBox(AppConstants.settingsBoxName);

//     onProgress?.call(0.75);
//   }

//   Future<Map<String, dynamic>> _createBackupMetadata() async {
//     final docsBox = Hive.box<Document>(AppConstants.documentsBoxName);
//     final foldersBox = Hive.box<Folder>(AppConstants.foldersBoxName);

//     // Get document file paths for copying
//     final List<String> documentPaths = [];
//     for (var doc in docsBox.values) {
//       if (await File(doc.pdfPath).exists()) {
//         documentPaths.add(doc.pdfPath);
//       }

//       if (doc.thumbnailPath != null &&
//           await File(doc.thumbnailPath!).exists()) {
//         documentPaths.add(doc.thumbnailPath!);
//       }

//       for (var page in doc.pagesPaths) {
//         if (await File(page).exists()) {
//           documentPaths.add(page);
//         }
//       }
//     }

//     // Creating backup metadata
//     final metadata = {
//       'version': '1.0',
//       'timestamp': DateTime.now().toIso8601String(),
//       'documentCount': docsBox.length,
//       'folderCount': foldersBox.length,
//       'documentPaths': documentPaths,
//     };

//     logger.info('Created backup metadata: ${jsonEncode(metadata)}');
//     return metadata;
//   }

//   Future<String> _createBackupZip(String backupDirPath) async {
//     try {
//       // Create metadata file
//       final metadata = await _createBackupMetadata();
//       final metadataFile = File('$backupDirPath/$_backupMetadataFileName');
//       await metadataFile.writeAsString(jsonEncode(metadata));
//       logger.info('Metadata file created at: ${metadataFile.path}');

//       final appDir = await getApplicationDocumentsDirectory();
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final zipName = '${AppConstants.backupFilePrefix}$timestamp.zip';
//       final backupsDir = Directory('${appDir.path}/backups');

//       if (!await backupsDir.exists()) {
//         await backupsDir.create(recursive: true);
//       }
//       final zipPath = path.join(backupsDir.path, zipName);

//       // Use the BackupArchiver utility to create the zip file
//       logger.info(
//           'Creating backup zip at: $zipPath from directory: $backupDirPath');
//       final actualZipPath =
//           await BackupArchiver.createZipFromDirectory(backupDirPath, zipName);

//       // Verify the zip file was created
//       final zipFile = File(actualZipPath);
//       if (await zipFile.exists()) {
//         final size = await zipFile.length();
//         logger.info(
//             'Backup zip created successfully at: $actualZipPath, size: $size bytes');
//         return actualZipPath;
//       } else {
//         throw Exception('Backup zip file not created: $actualZipPath');
//       }
//     } catch (e) {
//       logger.error('Error creating backup zip: $e', e);
//       rethrow;
//     }
//   }

//   Future<Directory> _extractBackupZip(String zipFilePath) async {
//     try {
//       // Create a unique extraction directory
//       final tempDir = await getTemporaryDirectory();
//       final extractDirName = 'extract_${DateTime.now().millisecondsSinceEpoch}';
//       final extractDir = Directory(path.join(tempDir.path, extractDirName));

//       if (await extractDir.exists()) {
//         await extractDir.delete(recursive: true);
//       }
//       await extractDir.create(recursive: true);

//       logger.info('Extracting zip file: $zipFilePath to ${extractDir.path}');

//       // Use the BackupArchiver utility to extract the zip
//       final extractedPath =
//           await BackupArchiver.extractZipToDirectory(zipFilePath);

//       // Copy contents if extracted to a different path
//       if (extractedPath != extractDir.path) {
//         final sourceDir = Directory(extractedPath);
//         final entities = await sourceDir.list().toList();

//         for (var entity in entities) {
//           final basename = path.basename(entity.path);
//           final targetPath = path.join(extractDir.path, basename);

//           if (entity is File) {
//             logger.info(
//                 'Copying file from extraction: ${entity.path} to $targetPath');
//             await entity.copy(targetPath);
//           } else if (entity is Directory) {
//             logger.info(
//                 'Copying directory from extraction: ${entity.path} to $targetPath');
//             await _copyDirectory(entity.path, targetPath);
//           }
//         }
//       }

//       // Check for metadata file (this is the part failing)
//       final metadataFile = File('${extractDir.path}/$_backupMetadataFileName');
//       if (!await metadataFile.exists()) {
//         // Try to locate the metadata file in any subdirectory
//         bool found = false;
//         final dirs =
//             await extractDir.list().where((e) => e is Directory).toList();
//         for (var dir in dirs) {
//           final possibleMetadata = File('${dir.path}/$_backupMetadataFileName');
//           if (await possibleMetadata.exists()) {
//             // Copy metadata to root extraction dir
//             await possibleMetadata.copy(metadataFile.path);
//             found = true;
//             break;
//           }
//         }

//         // If still not found, create a simple metadata file to allow restore to proceed
//         if (!found) {
//           logger.warning(
//               'Metadata file not found in backup, creating minimal placeholder');
//           final placeholderMetadata = {
//             'version': '1.0',
//             'timestamp': DateTime.now().toIso8601String(),
//             'documentCount': 0,
//             'folderCount': 0,
//             'documentPaths': []
//           };
//           await metadataFile.writeAsString(jsonEncode(placeholderMetadata));
//         }
//       }

//       logger.info('Zip file extracted successfully to: ${extractDir.path}');
//       return extractDir;
//     } catch (e) {
//       logger.error('Error extracting backup zip: $e', e);
//       rethrow;
//     }
//   }

//   Future<void> _inspectZipFile(String zipFilePath) async {
//     try {
//       logger.info('Inspecting zip file: $zipFilePath');

//       final file = File(zipFilePath);
//       if (!await file.exists()) {
//         logger.error('Zip file does not exist: $zipFilePath');
//         return;
//       }

//       final bytes = await file.readAsBytes();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       logger.info('Zip file contains ${archive.length} entries:');
//       for (final file in archive) {
//         logger.info('- ${file.name} (${file.isFile ? "File" : "Directory"})');
//       }
//     } catch (e) {
//       logger.error('Error inspecting zip file: $e');
//     }
//   }

// // Helper to copy directories recursively
//   Future<void> _copyDirectory(String source, String destination) async {
//     final sourceDir = Directory(source);
//     final destDir = Directory(destination);

//     if (!await destDir.exists()) {
//       await destDir.create(recursive: true);
//     }

//     await for (var entity in sourceDir.list(recursive: false)) {
//       final basename = path.basename(entity.path);
//       final newPath = path.join(destination, basename);

//       if (entity is File) {
//         await entity.copy(newPath);
//       } else if (entity is Directory) {
//         await _copyDirectory(entity.path, newPath);
//       }
//     }
//   }

//   Future<void> _restoreDocumentFiles(String extractedDirPath,
//       Map<String, dynamic> metadata, Function(double)? onProgress) async {
//     try {
//       final docFilesDir = Directory('$extractedDirPath/document_files');
//       if (!await docFilesDir.exists()) {
//         logger.warning('No document_files directory found in backup');
//         return;
//       }

//       final appDocDir = await getApplicationDocumentsDirectory();
//       final documentsDir = Directory('${appDocDir.path}/documents');

//       if (!await documentsDir.exists()) {
//         await documentsDir.create(recursive: true);
//       }

//       // Get all files from backup
//       final files = await docFilesDir.list().toList();
//       final fileCount = files.length;

//       logger.info(
//           'Restoring ${fileCount} document files to ${documentsDir.path}');

//       for (int i = 0; i < files.length; i++) {
//         if (files[i] is File) {
//           final File file = files[i] as File;
//           final String fileName = path.basename(file.path);
//           final targetPath = '${documentsDir.path}/$fileName';

//           logger.info('Copying file: ${file.path} to $targetPath');

//           try {
//             await file.copy(targetPath);
//             final targetFile = File(targetPath);
//             if (await targetFile.exists()) {
//               logger.info('Successfully copied file to: $targetPath');
//             } else {
//               logger.error(
//                   'File copy appeared to succeed but target file doesn\'t exist: $targetPath');
//             }
//           } catch (e) {
//             logger.error('Error copying file ${file.path} to $targetPath: $e');
//           }

//           // Update progress
//           if (onProgress != null && fileCount > 0) {
//             onProgress(0.8 + (i / fileCount) * 0.1);
//           }
//         }
//       }

//       logger.info('Document file restoration completed');
//     } catch (e) {
//       logger.error('Error restoring document files: $e', e);
//     }
//   }

//   // Clean up temporary files after restore
//   Future<void> _cleanupTempFiles(
//       String extractedDirPath, String zipFilePath) async {
//     try {
//       final extractDir = Directory(extractedDirPath);
//       if (await extractDir.exists()) {
//         await extractDir.delete(recursive: true);
//       }

//       final zipFile = File(zipFilePath);
//       if (await zipFile.exists()) {
//         await zipFile.delete();
//       }
//     } catch (e) {
//       debugPrint('Error cleaning up temp files: $e');
//     }
//   }

//   // GOOGLE DRIVE IMPLEMENTATIONS

//   // Upload backup to Google Drive
//   Future<String> _uploadToGoogleDrive(
//       String backupFilePath, Function(double)? onProgress) async {
//     try {
//       onProgress?.call(0.7);

//       // Sign in to Google
//       final account = await _googleSignIn.signIn();
//       if (account == null) {
//         throw Exception('Google Sign-In was cancelled');
//       }

//       // Get HTTP client with auth
//       final httpClient = await _googleSignIn.authenticatedClient();
//       if (httpClient == null) {
//         throw Exception('Failed to get authenticated client');
//       }

//       // Create Drive API client
//       final driveApi = drive.DriveApi(httpClient);

//       // Create app folder if it doesn't exist
//       String? folderId = await _getOrCreateAppFolder(driveApi);

//       onProgress?.call(0.8);

//       // Create file metadata
//       final timestamp = DateTime.now().toString().replaceAll(':', '-');
//       final fileName = 'EasyScan_Backup_$timestamp.zip';

//       var driveFile = drive.File()
//         ..name = fileName
//         ..parents = [folderId];

//       // Upload file
//       final fileContent = await File(backupFilePath).readAsBytes();
//       final media = drive.Media(
//         Stream.value(fileContent),
//         fileContent.length,
//       );

//       final result = await driveApi.files.create(
//         driveFile,
//         uploadMedia: media,
//       );

//       onProgress?.call(0.9);

//       return 'Backup uploaded to Google Drive: ${result.name}';
//     } catch (e) {
//       debugPrint('Error uploading to Google Drive: $e');
//       rethrow;
//     }
//   }

//   // Download backup from Google Drive
//   Future<String> _downloadFromGoogleDrive(
//       String fileId, Function(double)? onProgress) async {
//     try {
//       onProgress?.call(0.1);

//       // Sign in to Google
//       final account = await _googleSignIn.signIn();
//       if (account == null) {
//         throw Exception('Google Sign-In was cancelled');
//       }

//       // Get HTTP client with auth
//       final httpClient = await _googleSignIn.authenticatedClient();
//       if (httpClient == null) {
//         throw Exception('Failed to get authenticated client');
//       }

//       // Create Drive API client
//       final driveApi = drive.DriveApi(httpClient);

//       onProgress?.call(0.15);

//       // Get file metadata
//       final file = await driveApi.files.get(fileId, $fields: 'name,size');

//       // Create the destination file
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/${file.toString()}');

//       // Download the file
//       final media = await driveApi.files.get(
//         fileId,
//         downloadOptions: drive.DownloadOptions.fullMedia,
//       ) as drive.Media;

//       final fileStream = media.stream;
//       final fileBytes = await fileStream.toList();
//       final bytes = fileBytes.expand((byte) => byte).toList();

//       await tempFile.writeAsBytes(bytes);

//       onProgress?.call(0.25);

//       return tempFile.path;
//     } catch (e) {
//       debugPrint('Error downloading from Google Drive: $e');
//       rethrow;
//     }
//   }

//   // Get available backups from Google Drive
//   Future<List<Map<String, dynamic>>> _getGoogleDriveBackups() async {
//     try {
//       // Sign in to Google
//       final account = await _googleSignIn.signIn();
//       if (account == null) {
//         throw Exception('Google Sign-In was cancelled');
//       }

//       // Get HTTP client with auth
//       final httpClient = await _googleSignIn.authenticatedClient();
//       if (httpClient == null) {
//         throw Exception('Failed to get authenticated client');
//       }

//       // Create Drive API client
//       final driveApi = drive.DriveApi(httpClient);

//       // Get app folder
//       String? folderId = await _getAppFolderId(driveApi);
//       if (folderId == null) {
//         return [];
//       }

//       // Search for backups in the app folder
//       final fileList = await driveApi.files.list(
//         q: "'$folderId' in parents and name contains 'EasyScan_Backup' and trashed = false",
//         $fields: 'files(id, name, createdTime, size)',
//         orderBy: 'createdTime desc',
//       );

//       final backups = fileList.files?.map((file) {
//             return {
//               'id': file.id,
//               'name': file.name,
//               'date': file.createdTime?.toLocal().toString() ?? 'Unknown',
//               'size': file.size != null
//                   ? FileUtils.formatFileSize(int.parse(file.size!))
//                   : 'Unknown',
//             };
//           }).toList() ??
//           [];

//       return backups;
//     } catch (e) {
//       debugPrint('Error getting Google Drive backups: $e');
//       return [];
//     }
//   }

//   // Get or create app folder in Google Drive
//   Future<String> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
//     String? folderId = await _getAppFolderId(driveApi);

//     if (folderId != null) {
//       return folderId;
//     }

//     // Create app folder
//     var folder = drive.File()
//       ..name = 'EasyScan Backups'
//       ..mimeType = 'application/vnd.google-apps.folder';

//     final result = await driveApi.files.create(folder);
//     return result.id!;
//   }

//   // Get app folder ID if it exists
//   Future<String?> _getAppFolderId(drive.DriveApi driveApi) async {
//     try {
//       final fileList = await driveApi.files.list(
//         q: "name = 'EasyScan Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
//         $fields: 'files(id)',
//       );

//       if (fileList.files != null && fileList.files!.isNotEmpty) {
//         return fileList.files!.first.id;
//       }

//       return null;
//     } catch (e) {
//       debugPrint('Error getting app folder: $e');
//       return null;
//     }
//   }

//   /// Save backup to local storage
//   Future<String> _saveToLocalStorage(
//       String backupFilePath, Function(double)? onProgress) async {
//     try {
//       onProgress?.call(0.75);

//       // Use the LocalBackupManager to save the file
//       final localManager = LocalBackupManager();
//       final targetPath = await localManager.saveBackupToLocal(backupFilePath);

//       onProgress?.call(0.95);

//       return 'Backup saved to local storage: ${path.basename(targetPath)}';
//     } catch (e) {
//       debugPrint('Error saving to local storage: $e');
//       rethrow;
//     }
//   }

//   /// Get backup from local storage
//   Future<String> _getFromLocalStorage(Function(double)? onProgress) async {
//     try {
//       onProgress?.call(0.1);

//       // Use the LocalBackupManager to pick a backup file
//       final localManager = LocalBackupManager();
//       final filePath = await localManager.pickBackupFile();

//       // Verify it's a valid backup file
//       if (!path.basename(filePath).startsWith(AppConstants.backupFilePrefix)) {
//         throw Exception('The selected file is not a valid EasyScan backup');
//       }

//       onProgress?.call(0.2);
//       return filePath;
//     } catch (e) {
//       debugPrint('Error getting from local storage: $e');
//       rethrow;
//     }
//   }

//   Future<Map<String, dynamic>> verifyRestoredDocuments() async {
//     try {
//       int totalDocs = 0;
//       int validDocs = 0;
//       int missingFiles = 0;

//       final docsBox = Hive.box<Document>(AppConstants.documentsBoxName);
//       totalDocs = docsBox.length;

//       for (var doc in docsBox.values) {
//         final file = File(doc.pdfPath);
//         if (await file.exists()) {
//           validDocs++;
//         } else {
//           missingFiles++;
//           logger.warning('Missing file after restore: ${doc.pdfPath}');
//         }
//       }

//       return {
//         'totalDocs': totalDocs,
//         'validDocs': validDocs,
//         'missingFiles': missingFiles,
//       };
//     } catch (e) {
//       logger.error('Error verifying restored documents: $e');
//       return {'error': e.toString()};
//     }
//   }

//   /// Get available backups from local storage
//   Future<List<Map<String, dynamic>>> _getLocalBackups() async {
//     try {
//       // Use the LocalBackupManager to list backups
//       final localManager = LocalBackupManager();
//       return await localManager.listLocalBackups();
//     } catch (e) {
//       debugPrint('Error getting local backups: $e');
//       return [];
//     }
//   }
// }
