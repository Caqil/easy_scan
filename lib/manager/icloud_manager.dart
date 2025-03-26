// import 'dart:io';
// import 'dart:math';
// import 'package:icloud_storage/icloud_storage.dart';
// import 'package:path/path.dart' as path;
// import 'package:scanpro/main.dart';
// import 'package:scanpro/utils/constants.dart';

// // Assuming logger is defined elsewhere
// // import 'package:scanpro/main.dart';

// // Enum to represent the connection state of iCloud
// enum ICloudState {
//   notConnected,
//   connected,
//   connecting,
// }

// enum SyncICloudResult {
//   failed,
//   completed,
//   skipped,
// }

// class ICloudBackupManager {
//   static final ICloudBackupManager _instance = ICloudBackupManager._internal();
//   factory ICloudBackupManager() => _instance;

//   ICloudBackupManager._internal();

//   late final ICloudStorage _iCloudStorage;
//   ICloudState _iCloudState = ICloudState.notConnected;

//   ICloudState get state => _iCloudState;

//   Future<bool> initialize() async {
//     try {
//       if (!Platform.isIOS) {
//         return false;
//       }

//       _iCloudState = ICloudState.connecting;
//       _iCloudStorage =
//           ICloudStorage(containerId: AppConstants.iCloudContainerId);

//       // Check iCloud availability
//       final bool isAvailable = await _iCloudStorage.isAvailable();
//       _iCloudState =
//           isAvailable ? ICloudState.connected : ICloudState.notConnected;
//       return isAvailable;
//     } catch (e) {
//       logger.error('Error initializing iCloud: $e');
//       _iCloudState = ICloudState.notConnected;
//       return false;
//     }
//   }

//   Future<bool> isICloudAvailable() async {
//     try {
//       if (!Platform.isIOS) {
//         return false;
//       }
//       return await _iCloudStorage.isAvailable();
//     } catch (e) {
//       logger.error('Error checking iCloud availability: $e');
//       return false;
//     }
//   }

//   Future<SyncICloudResult> uploadToICloud(String filePath) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }

//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }

//       final String fileName = path.basename(filePath);

//       await _iCloudStorage.startUpload(
//         filePath: filePath,
//         destinationFileName: fileName,
//         onProgress: (progress) {
//           logger
//               .info('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
//         },
//       );

//       return SyncICloudResult.completed;
//     } catch (e) {
//       logger.error('Error uploading to iCloud: $e');
//       return SyncICloudResult.failed;
//     }
//   }

//   Future<SyncICloudResult> uploadMultipleFilesToICloud(
//       List<String> filePaths) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }

//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }

//       bool allSucceeded = true;
//       for (String filePath in filePaths) {
//         final String fileName = path.basename(filePath);
//         try {
//           await _iCloudStorage.startUpload(
//             filePath: filePath,
//             destinationFileName: fileName,
//           );
//         } catch (e) {
//           allSucceeded = false;
//           logger.error('Error uploading file $fileName: $e');
//         }
//       }

//       return allSucceeded
//           ? SyncICloudResult.completed
//           : SyncICloudResult.failed;
//     } catch (e) {
//       logger.error('Error uploading multiple files to iCloud: $e');
//       return SyncICloudResult.failed;
//     }
//   }

//   Future<String?> downloadFromICloud(String fileName) async {
//     try {
//       if (!Platform.isIOS) {
//         return null;
//       }

//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return null;
//         }
//       }

//       final String tempPath = await _createTempPath(fileName);

//       await _iCloudStorage.startDownload(
//         cloudFileName: fileName,
//         destinationFilePath: tempPath,
//         onProgress: (progress) {
//           logger.info(
//               'Download progress: ${(progress * 100).toStringAsFixed(1)}%');
//         },
//       );

//       logger.info('Downloaded file from iCloud: $tempPath');
//       return tempPath;
//     } catch (e) {
//       logger.error('Error downloading from iCloud: $e');
//       return null;
//     }
//   }

//   Future<String> _createTempPath(String fileName) async {
//     final Directory tempDir = await Directory.systemTemp.createTemp();
//     return path.join(tempDir.path, fileName);
//   }

//   Future<List<ICloudFile>> getCloudFiles() async {
//     try {
//       if (!Platform.isIOS) {
//         return [];
//       }

//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return [];
//         }
//       }

//       final files = await _iCloudStorage.getAllFiles();
//       logger.info('Cloud files found: ${files.length}');

//       final backupFiles = files
//           .where((file) =>
//               file.relativePath.startsWith(AppConstants.backupFilePrefix))
//           .toList();

//       return backupFiles;
//     } catch (e) {
//       logger.error('Error getting cloud files: $e');
//       return [];
//     }
//   }

//   Future<List<Map<String, dynamic>>> listICloudBackups() async {
//     try {
//       if (!Platform.isIOS) {
//         return [];
//       }

//       final backupFiles = await getCloudFiles();

//       List<Map<String, dynamic>> backups = backupFiles.map((file) {
//         return {
//           'id': file.relativePath,
//           'name': file.relativePath,
//           'date': file.lastModified?.toString() ?? 'Unknown',
//           'size': _formatSize(file.size ?? 0),
//         };
//       }).toList();

//       backups.sort((a, b) {
//         if (a['date'] == 'Unknown' || b['date'] == 'Unknown') return 0;
//         return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
//       });

//       return backups;
//     } catch (e) {
//       logger.error('Error listing iCloud backups: $e');
//       return [];
//     }
//   }

//   Future<SyncICloudResult> deleteICloudBackup(String fileName) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }

//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }

//       await _iCloudStorage.delete(fileName);
//       return SyncICloudResult.completed;
//     } catch (e) {
//       logger.error('Error deleting iCloud backup: $e');
//       return SyncICloudResult.failed;
//     }
//   }

//   Future<SyncICloudResult> deleteMultipleICloudBackups(
//       List<String> fileNames) async {
//     try {
//       if (!Platform.isIOS) {
//         return SyncICloudResult.skipped;
//       }

//       if (_iCloudState != ICloudState.connected) {
//         final bool isInitialized = await initialize();
//         if (!isInitialized) {
//           return SyncICloudResult.failed;
//         }
//       }

//       bool allSucceeded = true;
//       for (String fileName in fileNames) {
//         try {
//           await _iCloudStorage.delete(fileName);
//         } catch (e) {
//           allSucceeded = false;
//           logger.error('Error deleting file $fileName: $e');
//         }
//       }

//       return allSucceeded
//           ? SyncICloudResult.completed
//           : SyncICloudResult.failed;
//     } catch (e) {
//       logger.error('Error deleting multiple iCloud backups: $e');
//       return SyncICloudResult.failed;
//     }
//   }

//   String _formatSize(int bytes) {
//     if (bytes <= 0) return '0 B';
//     const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
//     var i = (log(bytes) / log(1024)).floor();
//     return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
//   }
// }
