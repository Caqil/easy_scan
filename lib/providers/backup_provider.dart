import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/cloud_service.dart';
import 'package:scanpro/services/storage_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';

/// State class for backup operations
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

/// Notifier class for backup operations
class BackupNotifier extends StateNotifier<BackupState> {
  final CloudBackupService _backupService;
  final StorageService _storageService;
  final Ref _ref;

  BackupNotifier({
    required CloudBackupService backupService,
    required StorageService storageService,
    required Ref ref,
  })  : _backupService = backupService,
        _storageService = storageService,
        _ref = ref,
        super(BackupState()) {
    // Load last backup date on initialization
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    try {
      final settings = await _storageService.getBackupSettings();
      if (settings.lastBackupDate != null) {
        state = state.copyWith(lastBackupDate: settings.lastBackupDate);
      }
    } catch (e) {
      logger.error('Error loading last backup date: $e');
    }
  }

  // Save last backup date to settings
  Future<void> _saveLastBackupDate(DateTime date) async {
    try {
      // Update settings
      final settings = await _storageService.getBackupSettings();
      final updatedSettings = settings.updateAfterBackup();
      await _storageService.saveBackupSettings(updatedSettings);

      // Also save to shared preferences for easier access
      await _storageService.saveLastBackupDate(date);

      // Update state
      state = state.copyWith(lastBackupDate: date);
    } catch (e) {
      logger.error('Error saving last backup date: $e');
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
    Function(double)? onProgress,
  }) async {
    try {
      state = state.copyWith(
        isCreatingBackup: true,
        progress: 0.0,
        clearMessages: true,
      );

      final result = await _backupService.createBackup(
        destination: destination,
        ref: _ref,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
          onProgress?.call(progress);
        },
        context: context,
      );

      // Process the result
      switch (result) {
        case BackupResult.success:
          // Save the backup date
          await _saveLastBackupDate(DateTime.now());

          state = state.copyWith(
            isCreatingBackup: false,
            progress: 1.0,
            successMessage: 'backup.success_message',
          );
          break;

        case BackupResult.failure:
          state = state.copyWith(
            isCreatingBackup: false,
            errorMessage: 'backup.error_message',
          );
          break;

        case BackupResult.cancelled:
          state = state.copyWith(
            isCreatingBackup: false,
            successMessage: 'backup.cancelled_message',
          );
          break;

        case BackupResult.notSupported:
          state = state.copyWith(
            isCreatingBackup: false,
            errorMessage: 'backup.not_supported_message',
          );
          break;
      }

      // Refresh available backups after creating a new one
      if (result == BackupResult.success) {
        await loadAvailableBackups(destination);
      }
    } catch (e) {
      logger.error('Error in createBackup: $e');
      state = state.copyWith(
        isCreatingBackup: false,
        errorMessage: 'Error creating backup: ${e.toString()}',
      );
    }
  }

  // Helper method to show restart recommendation dialog
  void _showRestartDialog(BuildContext context) {
    AppDialogs.showConfirmDialog(
      context,
      title: 'backup.restart_recommended_title',
      message: 'backup.restart_recommended_message',
      confirmText: 'common.ok',
      cancelText: '',
    );
  }

  // Load available backups
  Future<void> loadAvailableBackups(BackupDestination source) async {
    try {
      state = state.copyWith(clearMessages: true);

      final backups = await _backupService.getAvailableBackups(source);

      state = state.copyWith(availableBackups: backups);
    } catch (e) {
      logger.error('Error loading backups: $e');
      state = state.copyWith(
        errorMessage: 'Error loading backups: ${e.toString()}',
      );
    }
  }

  // Check if a platform is supported
  bool isPlatformSupported(BackupDestination destination) {
    return _backupService.isBackupServiceAvailable(destination) as bool;
  }

  // Restore from backup
  Future<void> restoreBackup({
    required BackupDestination source,
    required BuildContext context,
    String? backupId,
    Function(double)? onProgress,
  }) async {
    state = state.copyWith(
      isRestoringBackup: true,
      progress: 0.0,
      clearMessages: true,
    );

    // Add specific logging
    logger.info('Starting backup restoration from $source with ID: $backupId');

    final result = await _backupService.restoreBackup(
      source: source,
      backupId: backupId,
      onProgress: (progress) {
        state = state.copyWith(progress: progress);
        onProgress?.call(progress);
      },
      context: context,
    );

    // Process the result
    switch (result) {
      case BackupResult.success:
        logger.info('Backup restoration completed successfully');

        // Show success message
        state = state.copyWith(
          isRestoringBackup: false,
          progress: 1.0,
          successMessage: 'backup.restore_success_message',
        );

        // Show restart recommendation dialog if context is available
        if (context.mounted) {
          _showRestartDialog(context);
        }
        break;

      case BackupResult.failure:
        state = state.copyWith(
          isRestoringBackup: false,
          errorMessage: 'backup.restore_error_message',
        );
        break;

      case BackupResult.cancelled:
        state = state.copyWith(
          isRestoringBackup: false,
          successMessage: 'backup.restore_cancelled_message',
        );
        break;

      case BackupResult.notSupported:
        state = state.copyWith(
          isRestoringBackup: false,
          errorMessage: 'backup.restore_not_supported_message',
        );
        break;
    }
  }
}
