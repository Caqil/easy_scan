// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:icloud_storage_sync/icloud_storage_sync.dart';
// import 'package:path/path.dart' as path;
// import 'package:scanpro/utils/constants.dart';

// // Enum to represent the connection state of iCloud
// enum ICloudState {
//   notConnected, // iCloud is not connected
//   connected, // iCloud is successfully connected
//   connecting, // iCloud is in the process of connecting
// }

// // Enum to represent the result of syncing with iCloud
// enum SyncICloudResult {
//   failed, // Sync operation failed
//   completed, // Sync operation completed successfully
//   skipped // Sync operation was skipped
// }

// /// A service class to handle iCloud backup operations
// class ICloudBackupManager {
//   static final ICloudBackupManager _instance = ICloudBackupManager._internal();
//   factory ICloudBackupManager() => _instance;
  
//   ICloudBackupManager._internal();
  
//   final IcloudStorageSync _iCloudStorage = IcloudStorageSync();
//   ICloudState _iCloudState = ICloudState.notConnected;
  
//   // Get the current iCloud state
//   ICloudState get state => _iCloudState;
  
//   /// Initialize iCloud service
//   Future<bool> initialize() async {
//     try {
//       if (!Platform.isIOS) {
//         return false;
//       }
      
//       _iCloudState = ICloudState.connecting;
      
//       // Check if iCloud is available
//       final bool isAvailable = await isICloudAvailable();
//       if (isAvailable) {
//         // Enable iCloud document storage if available
//         final bool enabled = await _iCloudStorage.enableICloudDocumentStorage();
//         _iCloudState = enabled ? ICloudState.connected : ICloudState.notConnected;
//         return enabled;
//       } else {
//         _iCloudState = ICloudState.notConnected;
//         return false;
//       }
//     } catch (e) {
//       debugPrint('Error initializing iCloud: $e');
//       _iCloudState = ICloudState.notConnected;
//       return false;
//     }
//   }
  
//   /// Check if iCloud is available for the current device
//   Future<bool> isICloudAvailable() async {
//     try {
//       if (!Platform.isIOS) {
//         return false;
//       }
      
//       return await _iCloudStorage.isICloudAvailable();
//     } catch (e) {
//       debugPrint('Error checking iCloud availability: $e');
//       return false;
//     }
//   }
  
//   /// Upload a file to iCloud
//   Future<SyncICloudResult> uploadToICloud(String filePath) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }
      
//       // Get file name
//       final String fileName = path.basename(filePath);
      
//       // Upload file to iCloud
//       final bool success = await _iCloudStorage.uploadFileToICloud(
//         sourcePath: filePath,
//         destinationName: fileName,
//       );
      
//       return success ? SyncICloudResult.completed : SyncICloudResult.failed;
//     } catch (e) {
//       debugPrint('Error uploading to iCloud: $e');
//       return SyncICloudResult.failed;
//     }
//   }
  
//   /// Upload multiple files to iCloud
//   Future<SyncICloudResult> uploadMultipleFilesToICloud(List<String> filePaths) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }
      
//       bool allSucceeded = true;
      
//       // Upload each file to iCloud
//       for (String filePath in filePaths) {
//         final String fileName = path.basename(filePath);
        
//         final bool success = await _iCloudStorage.uploadFileToICloud(
//           sourcePath: filePath,
//           destinationName: fileName,
//         );
        
//         if (!success) {
//           allSucceeded = false;
//         }
//       }
      
//       return allSucceeded ? SyncICloudResult.completed : SyncICloudResult.failed;
//     } catch (e) {
//       debugPrint('Error uploading multiple files to iCloud: $e');
//       return SyncICloudResult.failed;
//     }
//   }
  
//   /// Download a file from iCloud
//   Future<String?> downloadFromICloud(String fileName) async {
//     try {
//       if (!Platform.isIOS) {
//         return null;
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return null;
//         }
//       }
      
//       // Get the file URL from iCloud
//       final String? fileUrl = await _iCloudStorage.getDocumentURL(fileName);
//       if (fileUrl == null) {
//         throw Exception('Could not get iCloud URL for file: $fileName');
//       }
      
//       // Create a temporary directory for the downloaded file
//       final Directory tempDir = await Directory.systemTemp.createTemp();
//       final String tempFilePath = path.join(tempDir.path, fileName);
      
//       // Download the file
//       final bool success = await _iCloudStorage.downloadFileFromICloud(
//         documentURL: fileUrl,
//         destinationPath: tempFilePath,
//       );
      
//       if (!success) {
//         throw Exception('Failed to download file from iCloud');
//       }
      
//       return tempFilePath;
//     } catch (e) {
//       debugPrint('Error downloading from iCloud: $e');
//       return null;
//     }
//   }
  
//   /// Get all cloud files
//   Future<List<CloudFiles>> getCloudFiles() async {
//     try {
//       if (!Platform.isIOS) {
//         return [];
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return [];
//         }
//       }
      
//       // Get cloud files
//       final cloudFiles = await _iCloudStorage.getCloudFiles(containerId: );
//       debugPrint('Cloud files: ${cloudFiles?.length ?? 0}');
      
//       // Filter for backup files if needed
//       final backupFiles = cloudFiles
//           ?.where((file) => file.title.startsWith(AppConstants.backupFilePrefix))
//           .toList() ?? [];
      
//       return backupFiles;
//     } catch (e) {
//       debugPrint('Error getting cloud files: $e');
//       return [];
//     }
//   }
  
//   /// List available backups in iCloud
//   Future<List<Map<String, dynamic>>> listICloudBackups() async {
//     try {
//       if (!Platform.isIOS) {
//         return [];
//       }
      
//       // Use getCloudFiles to get all files
//       final backupFiles = await getCloudFiles();
      
//       // Create backup metadata list
//       List<Map<String, dynamic>> backups = [];
//       for (var file in backupFiles) {
//         backups.add({
//           'id': file.relativePath,
//           'name': file.title,
//           'date': file.lastSyncDt?.toString() ?? 'Unknown',
//           'size': '${(file.sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
//         });
//       }
      
//       // Sort by date (newest first)
//       backups.sort((a, b) {
//         if (a['date'] == 'Unknown' || b['date'] == 'Unknown') {
//           return 0;
//         }
//         return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
//       });
      
//       return backups;
//     } catch (e) {
//       debugPrint('Error listing iCloud backups: $e');
//       return [];
//     }
//   }
  
//   /// Delete a backup file from iCloud
//   Future<SyncICloudResult> deleteICloudBackup(String relativePath) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }
      
//       // Delete the file
//       final bool success = await _iCloudStorage.delete(relativePath);
//       return success ? SyncICloudResult.completed : SyncICloudResult.failed;
//     } catch (e) {
//       debugPrint('Error deleting iCloud backup: $e');
//       return SyncICloudResult.failed;
//     }
//   }
  
//   /// Delete multiple backup files from iCloud
//   Future<SyncICloudResult> deleteMultipleICloudBackups(List<String> relativePaths) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }
      
//       bool allSucceeded = true;
      
//       // Delete each file
//       for (String relativePath in relativePaths) {
//         final bool success = await _iCloudStorage.deleteFile(relativePath);
//         if (!success) {
//           allSucceeded = false;
//         }
//       }
      
//       return allSucceeded ? SyncICloudResult.completed : SyncICloudResult.failed;
//     } catch (e) {
//       debugPrint('Error deleting multiple iCloud backups: $e');
//       return SyncICloudResult.failed;
//     }
//   }
  
//   /// Rename a file in iCloud
//   Future<SyncICloudResult> renameFile(CloudFiles cloudFile, String newName) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }
      
//       // Check if iCloud is available
//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }
      
//       // Download the file first
//       final String? tempFilePath = await downloadFromICloud(cloudFile.relativePath!);
//       if (tempFilePath == null) {
//         return SyncICloudResult.failed;
//       }
      
//       // Delete the old file
//       final bool deleteSuccess = await _iCloudStorage.deleteFile(cloudFile.relativePath!);
//       if (!deleteSuccess) {
//         return SyncICloudResult.failed;
//       }
      
//       // Upload with new name
//       final String fileExtension = path.extension(cloudFile.title);
//       final String newFileName = '$newName$fileExtension';
      
//       final bool uploadSuccess = await _iCloudStorage.uploadFileToICloud(
//         sourcePath: tempFilePath,
//         destinationName: newFileName,
//       );
      
//       // Clean up temp file
//       await File(tempFilePath).delete();
      
//       return uploadSuccess ? SyncICloudResult.completed : SyncICloudResult.failed;
//     } catch (e) {
//       debugPrint('Error renaming iCloud file: $e');
//       return SyncICloudResult.failed;
//     }
//   }
// }

// // CloudFiles class to match the expected format
// class CloudFiles {
//   String? relativePath;
//   String title;
//   String? filePath;
//   int sizeInBytes;
//   DateTime? fileDate;
//   DateTime? lastSyncDt;
  
//   CloudFiles({
//     this.relativePath,
//     required this.title,
//     this.filePath,
//     required this.sizeInBytes,
//     this.fileDate,
//     this.lastSyncDt,
//   });
  
//   factory CloudFiles.fromJson(Map<String, dynamic> json) {
//     return CloudFiles(
//       relativePath: json['relativePath'],
//       title: json['title'] ?? 'Unknown',
//       filePath: json['filePath'],
//       sizeInBytes: json['sizeInBytes'] ?? 0,
//       fileDate: json['fileDate'] != null ? DateTime.parse(json['fileDate']) : null,
//       lastSyncDt: json['lastSyncDt'] != null ? DateTime.parse(json['lastSyncDt']) : null,
//     );
//   }
  
//   Map<String, dynamic> toJson() {
//     return {
//       'relativePath': relativePath,
//       'title': title,
//       'filePath': filePath,
//       'sizeInBytes': sizeInBytes,
//       'fileDate': fileDate?.toIso8601String(),
//       'lastSyncDt': lastSyncDt?.toIso8601String(),
//     };
//   }
// }