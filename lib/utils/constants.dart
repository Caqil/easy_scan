// Update the constants.dart file to add onboarding constants

class AppConstants {
  // Existing constants
  static const String documentsBoxName = 'documents';
  static const String foldersBoxName = 'folders';
  static const String settingsBoxName = 'settings';
  static const String settingsBoxLanguages = 'languages';
  static const String settingsKey = 'app_settings';
  static const int defaultPdfQuality = 80;
  static const int defaultImageQuality = 85;
  static const int thumbnailSize = 300;
  static const String backupFolderName = 'scanpro Backups';
  static const int maxBackupHistory = 10;
  static const String backupFilePrefix = 'scanpro_backup_';
  static const String backupSettingsBoxName = 'backup_settings';
  static const String backupSettingsKey = 'backup_settings';
  static const String iCloudContainerId =
      'iCloud.com.scanpro.documentconverter';

  static const List<int> folderColors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFF009688, // Teal
    0xFFFFEB3B, // Yellow
    0xFFE91E63, // Pink
    0xFF00BCD4, // Cyan
    0xFF8BC34A, // Light Green
    0xFF5722, // Deep Orange
    0xFF673AB7, // Deep Purple
    0xFFCDDC39, // Lime
    0xFF03A9F4, // Light Blue
  ];

  // New constants for onboarding
  static const String hasCompletedOnboardingKey = 'has_completed_onboarding';

  // Subscription constants
  static const String subscriptionStatusKey = 'subscription_status';
  static const String trialStartedKey = 'trial_started';
  static const String trialExpirationKey = 'trial_expiration';

  // Free trial duration in days
  static const int trialDurationDays = 7;
}
