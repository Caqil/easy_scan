import 'package:hive/hive.dart';

part 'backup_settings.g.dart';

/// Enum to represent backup frequency
@HiveType(typeId: 5)
enum BackupFrequency {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  manual
}

/// Enum to represent backup destination
@HiveType(typeId: 6)
enum BackupDestination {
  @HiveField(0)
  local,

  @HiveField(1)
  iCloud,

  @HiveField(2)
  googleDrive
}

/// Settings for app backups
@HiveType(typeId: 7)
class BackupSettings {
  /// Whether auto-backup is enabled
  @HiveField(0)
  final bool autoBackupEnabled;

  /// Frequency of auto-backups
  @HiveField(1)
  final BackupFrequency backupFrequency;

  /// Destination for backups
  @HiveField(2)
  final BackupDestination backupDestination;

  /// Last backup date
  @HiveField(3)
  final DateTime? lastBackupDate;

  /// Next scheduled backup date
  @HiveField(4)
  final DateTime? nextBackupDate;

  /// Maximum number of local backups to keep
  @HiveField(5)
  final int maxLocalBackups;

  /// Whether to include documents in backup
  @HiveField(6)
  final bool includeDocuments;

  /// Whether to include settings in backup
  @HiveField(7)
  final bool includeSettings;

  /// Whether to include folders structure in backup
  @HiveField(8)
  final bool includeFolders;

  /// Constructor with default values
  BackupSettings({
    this.autoBackupEnabled = false,
    this.backupFrequency = BackupFrequency.weekly,
    this.backupDestination = BackupDestination.local,
    this.lastBackupDate,
    this.nextBackupDate,
    this.maxLocalBackups = 5,
    this.includeDocuments = true,
    this.includeSettings = true,
    this.includeFolders = true,
  });

  /// Create a copy with modified fields
  BackupSettings copyWith({
    bool? autoBackupEnabled,
    BackupFrequency? backupFrequency,
    BackupDestination? backupDestination,
    DateTime? lastBackupDate,
    DateTime? nextBackupDate,
    int? maxLocalBackups,
    bool? includeDocuments,
    bool? includeSettings,
    bool? includeFolders,
  }) {
    return BackupSettings(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupDestination: backupDestination ?? this.backupDestination,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      nextBackupDate: nextBackupDate ?? this.nextBackupDate,
      maxLocalBackups: maxLocalBackups ?? this.maxLocalBackups,
      includeDocuments: includeDocuments ?? this.includeDocuments,
      includeSettings: includeSettings ?? this.includeSettings,
      includeFolders: includeFolders ?? this.includeFolders,
    );
  }

  /// Update settings after backup has completed
  BackupSettings updateAfterBackup() {
    final now = DateTime.now();
    DateTime? nextDate;

    // Calculate next backup date based on frequency
    if (autoBackupEnabled) {
      switch (backupFrequency) {
        case BackupFrequency.daily:
          nextDate = DateTime(now.year, now.month, now.day + 1);
          break;
        case BackupFrequency.weekly:
          nextDate = DateTime(now.year, now.month, now.day + 7);
          break;
        case BackupFrequency.monthly:
          nextDate = DateTime(now.year, now.month + 1, now.day);
          break;
        case BackupFrequency.manual:
          nextDate = null;
          break;
      }
    }

    return copyWith(
      lastBackupDate: now,
      nextBackupDate: nextDate,
    );
  }

  /// Check if a backup is due based on schedule
  bool isBackupDue() {
    // If auto-backup is not enabled, no backup is due
    if (!autoBackupEnabled) return false;

    // If no next backup date is set, no backup is due
    if (nextBackupDate == null) return false;

    // Check if current time is after the next backup date
    return DateTime.now().isAfter(nextBackupDate!);
  }
}
