import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/services/backup_service.dart';
import '../services/backup_service.dart';

// State class for backup operations
class BackupState {
  final bool isCreatingBackup;
  final bool isRestoringBackup;
  final double progress;
  final String? errorMessage;
  final String? successMessage;
  final List<Map<String, dynamic>> availableBackups;
  final DateTime? lastBackupDate;

  BackupState({
    this.isCreatingBackup = false,
    this.isRestoringBackup = false,
    this.progress = 0.0,
    this.errorMessage,
    this.successMessage,
    this.availableBackups = const [],
    this.lastBackupDate,
  });

  BackupState copyWith({
    bool? isCreatingBackup,
    bool? isRestoringBackup,
    double? progress,
    String? errorMessage,
    String? successMessage,
    List<Map<String, dynamic>>? availableBackups,
    DateTime? lastBackupDate,
    bool clearMessages = false,
  }) {
    return BackupState(
      isCreatingBackup: isCreatingBackup ?? this.isCreatingBackup,
      isRestoringBackup: isRestoringBackup ?? this.isRestoringBackup,
      progress: progress ?? this.progress,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      availableBackups: availableBackups ?? this.availableBackups,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }
}

// Notifier class for backup operations
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService = BackupService();

  BackupNotifier() : super(BackupState()) {
    // Load last backup date on initialization
    _loadLastBackupDate();
  }

  // Load last backup date from persistent storage
  Future<void> _loadLastBackupDate() async {
    try {
      // In a real implementation, you would load this from shared preferences
      // For now, we'll use a placeholder
      // final prefs = await SharedPreferences.getInstance();
      // final lastBackupTimestamp = prefs.getInt('last_backup_timestamp');
      // if (lastBackupTimestamp != null) {
      //   state = state.copyWith(
      //     lastBackupDate: DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp),
      //   );
      // }
    } catch (e) {
      debugPrint('Error loading last backup date: $e');
    }
  }

  // Save last backup date to persistent storage
  Future<void> _saveLastBackupDate(DateTime date) async {
    try {
      // In a real implementation, you would save this to shared preferences
      // For now, we'll use a placeholder
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setInt('last_backup_timestamp', date.millisecondsSinceEpoch);
      state = state.copyWith(lastBackupDate: date);
    } catch (e) {
      debugPrint('Error saving last backup date: $e');
    }
  }

  // Clear any error or success messages
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  // Create a backup
  Future<void> createBackup({
    required BackupDestination destination,
    required BuildContext context,
  }) async {
    try {
      state = state.copyWith(
        isCreatingBackup: true,
        progress: 0.0,
        clearMessages: true,
      );

      final result = await _backupService.createBackup(
        destination: destination,
        context: context,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      // Save the backup date
      await _saveLastBackupDate(DateTime.now());

      state = state.copyWith(
        isCreatingBackup: false,
        progress: 1.0,
        successMessage: result,
      );

      // Refresh available backups after creating a new one
      loadAvailableBackups(destination);
    } catch (e) {
      state = state.copyWith(
        isCreatingBackup: false,
        errorMessage: 'Error creating backup: ${e.toString()}',
      );
    }
  }

  // Restore from a backup
  Future<void> restoreBackup({
    required BackupDestination source,
    required BuildContext context,
    String? backupId,
  }) async {
    try {
      state = state.copyWith(
        isRestoringBackup: true,
        progress: 0.0,
        clearMessages: true,
      );

      final result = await _backupService.restoreBackup(
        source: source,
        context: context,
        backupId: backupId,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        isRestoringBackup: false,
        progress: 1.0,
        successMessage: result,
      );
    } catch (e) {
      state = state.copyWith(
        isRestoringBackup: false,
        errorMessage: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  // Load available backups
  Future<void> loadAvailableBackups(
      BackupDestination source) async {
    try {
      state = state.copyWith(clearMessages: true);

      final backups = await _backupService.getAvailableBackups(source: source);

      state = state.copyWith(availableBackups: backups);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error loading backups: ${e.toString()}',
      );
    }
  }

  // Check if a platform is supported
  bool isPlatformSupported(BackupDestination destination) {
    switch (destination) {
      case BackupDestination.googleDrive:
        return Platform.isAndroid || Platform.isIOS;
      case BackupDestination.iCloud:
        return Platform.isIOS;
      case BackupDestination.local:
        return true;
    }
  }
}

// Provider for backup service
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

// Provider for backup state
final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  return BackupNotifier();
});
