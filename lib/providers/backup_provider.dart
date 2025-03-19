// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive/hive.dart';
// import 'package:scanpro/main.dart';
// import 'package:scanpro/services/backup_service.dart';
// import 'package:scanpro/services/storage_service.dart';
// import 'package:scanpro/utils/constants.dart';

// // State class for backup operations
// class BackupState {
//   final bool isCreatingBackup;
//   final bool isRestoringBackup;
//   final double progress;
//   final String? errorMessage;
//   final String? successMessage;
//   final List<Map<String, dynamic>> availableBackups;
//   final DateTime? lastBackupDate;

//   BackupState({
//     this.isCreatingBackup = false,
//     this.isRestoringBackup = false,
//     this.progress = 0.0,
//     this.errorMessage,
//     this.successMessage,
//     this.availableBackups = const [],
//     this.lastBackupDate,
//   });

//   BackupState copyWith({
//     bool? isCreatingBackup,
//     bool? isRestoringBackup,
//     double? progress,
//     String? errorMessage,
//     String? successMessage,
//     List<Map<String, dynamic>>? availableBackups,
//     DateTime? lastBackupDate,
//     bool clearMessages = false,
//   }) {
//     return BackupState(
//       isCreatingBackup: isCreatingBackup ?? this.isCreatingBackup,
//       isRestoringBackup: isRestoringBackup ?? this.isRestoringBackup,
//       progress: progress ?? this.progress,
//       errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
//       successMessage:
//           clearMessages ? null : (successMessage ?? this.successMessage),
//       availableBackups: availableBackups ?? this.availableBackups,
//       lastBackupDate: lastBackupDate ?? this.lastBackupDate,
//     );
//   }
// }

// // Notifier class for backup operations
// class BackupNotifier extends StateNotifier<BackupState> {
//   final BackupService _backupService = BackupService();

//   BackupNotifier() : super(BackupState()) {
//     // Load last backup date on initialization
//     _loadLastBackupDate();
//   }
//   Future<void> _loadLastBackupDate() async {
//     try {
//       final settingsBox = Hive.box(AppConstants.settingsBoxName);
//       final lastBackupTimestamp =
//           settingsBox.get('last_backup_timestamp') as int?;
//       if (lastBackupTimestamp != null) {
//         state = state.copyWith(
//           lastBackupDate:
//               DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp),
//         );
//       }
//     } catch (e) {
//       debugPrint('Error loading last backup date from Hive: $e');
//     }
//   }

//   // Save last backup date to Hive
//   Future<void> _saveLastBackupDate(DateTime date) async {
//     try {
//       final settingsBox = Hive.box(AppConstants.settingsBoxName);
//       await settingsBox.put(
//           'last_backup_timestamp', date.millisecondsSinceEpoch);
//       state = state.copyWith(lastBackupDate: date);
//     } catch (e) {
//       debugPrint('Error saving last backup date to Hive: $e');
//     }
//   }

//   // Clear any error or success messages
//   void clearMessages() {
//     state = state.copyWith(clearMessages: true);
//   }

//   // Create a backup
//   Future<void> createBackup({
//     required BackupDestination destination,
//     required BuildContext context,
//   }) async {
//     try {
//       state = state.copyWith(
//         isCreatingBackup: true,
//         progress: 0.0,
//         clearMessages: true,
//       );

//       final result = await _backupService.createBackup(
//         destination: destination,
//         context: context,
//         onProgress: (progress) {
//           state = state.copyWith(progress: progress);
//         },
//       );

//       // Save the backup date
//       await _saveLastBackupDate(DateTime.now());

//       state = state.copyWith(
//         isCreatingBackup: false,
//         progress: 1.0,
//         successMessage: result,
//       );

//       // Refresh available backups after creating a new one
//       loadAvailableBackups(destination);
//     } catch (e) {
//       state = state.copyWith(
//         isCreatingBackup: false,
//         errorMessage: 'Error creating backup: ${e.toString()}',
//       );
//     }
//   }

//   Future<void> restoreBackup({
//     required BackupDestination source,
//     required BuildContext context,
//     String? backupId,
//   }) async {
//     try {
//       state = state.copyWith(
//         isRestoringBackup: true,
//         progress: 0.0,
//         clearMessages: true,
//       );

//       // Add specific logging
//       logger
//           .info('Starting backup restoration from $source with ID: $backupId');

//       final result = await _backupService.restoreBackup(
//         source: source,
//         context: context,
//         backupId: backupId,
//         onProgress: (progress) {
//           state = state.copyWith(progress: progress);
//         },
//       );

//       logger.info('Backup restoration completed, closing Hive');

//       // Close all boxes to ensure clean reload
//       await Hive.close();

//       logger.info('Re-initializing storage service');

//       // Re-initialize storage service to reload the data
//       final storageService = StorageService();
//       await storageService.initialize();

//       // Force a reload of the last backup date
//       await _loadLastBackupDate();

//       state = state.copyWith(
//         isRestoringBackup: false,
//         progress: 1.0,
//         successMessage: result,
//       );

//       logger.info('Restoration state updated, showing restart dialog');

//       // Show restart recommendation dialog if context is available
//       if (context != null && context.mounted) {
//         _showRestartDialog(context);
//       }
//     } catch (e) {
//       logger.error('Error in restoreBackup: $e');
//       state = state.copyWith(
//         isRestoringBackup: false,
//         errorMessage: 'Error restoring backup: ${e.toString()}',
//       );
//     }
//   }

// // Add this helper method
//   void _showRestartDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         title: Text('Restart Recommended'),
//         content: Text(
//             'To ensure all data is loaded correctly, please restart the app.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Load available backups
//   Future<void> loadAvailableBackups(BackupDestination source) async {
//     try {
//       state = state.copyWith(clearMessages: true);

//       final backups = await _backupService.getAvailableBackups(source: source);

//       state = state.copyWith(availableBackups: backups);
//     } catch (e) {
//       state = state.copyWith(
//         errorMessage: 'Error loading backups: ${e.toString()}',
//       );
//     }
//   }

//   // Check if a platform is supported
//   bool isPlatformSupported(BackupDestination destination) {
//     switch (destination) {
//       case BackupDestination.googleDrive:
//         return Platform.isAndroid || Platform.isIOS;
//       case BackupDestination.local:
//         return true;
//     }
//   }
// }

// // Provider for backup service
// final backupServiceProvider = Provider<BackupService>((ref) {
//   return BackupService();
// });

// // Provider for backup state
// final backupProvider =
//     StateNotifierProvider<BackupNotifier, BackupState>((ref) {
//   return BackupNotifier();
// });
