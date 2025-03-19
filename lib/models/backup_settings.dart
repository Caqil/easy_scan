import 'package:hive/hive.dart';
import '../services/backup_service.dart';

part 'backup_settings.g.dart';

@HiveType(typeId: 4) // Make sure to use a unique type ID
class BackupSettings {
  @HiveField(0)
  final bool autoBackupEnabled;

  @HiveField(1)
  final String autoBackupFrequency; // 'daily', 'weekly', 'monthly'

  @HiveField(2)
  final String autoBackupDestination; // 'local', 'googleDrive', 'iCloud'

  @HiveField(3)
  final DateTime? lastBackupDate;

  @HiveField(4)
  final DateTime? nextScheduledBackup;

  @HiveField(5)
  final int maxLocalBackups;

  @HiveField(6)
  final int maxCloudBackups;

  BackupSettings({
    this.autoBackupEnabled = false,
    this.autoBackupFrequency = 'weekly',
    this.autoBackupDestination = 'local',
    this.lastBackupDate,
    this.nextScheduledBackup,
    this.maxLocalBackups = 5,
    this.maxCloudBackups = 10,
  });

  // Get the backup destination enum from string
  BackupDestination get backupDestination {
    switch (autoBackupDestination) {
      case 'googleDrive':
        return BackupDestination.googleDrive;
      case 'iCloud':
        return BackupDestination.iCloud;
      case 'local':
      default:
        return BackupDestination.local;
    }
  }

  // Create a copy of this backup settings with some fields updated
  BackupSettings copyWith({
    bool? autoBackupEnabled,
    String? autoBackupFrequency,
    String? autoBackupDestination,
    DateTime? lastBackupDate,
    DateTime? nextScheduledBackup,
    int? maxLocalBackups,
    int? maxCloudBackups,
  }) {
    return BackupSettings(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      autoBackupDestination:
          autoBackupDestination ?? this.autoBackupDestination,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      nextScheduledBackup: nextScheduledBackup ?? this.nextScheduledBackup,
      maxLocalBackups: maxLocalBackups ?? this.maxLocalBackups,
      maxCloudBackups: maxCloudBackups ?? this.maxCloudBackups,
    );
  }

  // Calculate the next backup date based on frequency
  DateTime calculateNextBackup() {
    final now = DateTime.now();

    switch (autoBackupFrequency) {
      case 'daily':
        return DateTime(now.year, now.month, now.day + 1, now.hour, now.minute);
      case 'weekly':
        return DateTime(now.year, now.month, now.day + 7, now.hour, now.minute);
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day, now.hour, now.minute);
      default:
        return DateTime(now.year, now.month, now.day + 7, now.hour, now.minute);
    }
  }

  // Check if a backup is due
  bool isBackupDue() {
    if (!autoBackupEnabled || nextScheduledBackup == null) {
      return false;
    }

    final now = DateTime.now();
    return now.isAfter(nextScheduledBackup!);
  }

  // Update the last backup date and calculate the next scheduled backup
  BackupSettings updateAfterBackup() {
    final now = DateTime.now();

    return copyWith(
      lastBackupDate: now,
      nextScheduledBackup: calculateNextBackup(),
    );
  }
}
