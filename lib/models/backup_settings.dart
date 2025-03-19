// import 'package:hive/hive.dart';
// import 'package:scanpro/services/backup_service.dart';

// part 'backup_settings.g.dart';

// @HiveType(typeId: 4)
// class BackupSettings {
//   @HiveField(0)
//   final bool autoBackupEnabled;

//   @HiveField(1)
//   final String frequency; // 'daily', 'weekly', 'monthly'

//   @HiveField(2)
//   final DateTime? lastBackupDate;

//   @HiveField(3)
//   final BackupDestination backupDestination;

//   @HiveField(4)
//   final int maxLocalBackups;

//   BackupSettings({
//     this.autoBackupEnabled = false,
//     this.frequency = 'weekly',
//     this.lastBackupDate,
//     this.backupDestination = BackupDestination.local,
//     this.maxLocalBackups = 5,
//   });

//   // Create a copy of the settings with updated values
//   BackupSettings copyWith({
//     bool? autoBackupEnabled,
//     String? frequency,
//     DateTime? lastBackupDate,
//     BackupDestination? backupDestination,
//     int? maxLocalBackups,
//   }) {
//     return BackupSettings(
//       autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
//       frequency: frequency ?? this.frequency,
//       lastBackupDate: lastBackupDate ?? this.lastBackupDate,
//       backupDestination: backupDestination ?? this.backupDestination,
//       maxLocalBackups: maxLocalBackups ?? this.maxLocalBackups,
//     );
//   }

//   // Update the lastBackupDate to now
//   BackupSettings updateAfterBackup() {
//     return copyWith(
//       lastBackupDate: DateTime.now(),
//     );
//   }

//   // Check if it's time for a backup based on frequency
//   bool isBackupDue() {
//     if (lastBackupDate == null) {
//       return true; // If never backed up, it's due
//     }

//     final now = DateTime.now();
//     final difference = now.difference(lastBackupDate!);

//     switch (frequency) {
//       case 'daily':
//         return difference.inHours >= 24;
//       case 'weekly':
//         return difference.inDays >= 7;
//       case 'monthly':
//         return difference.inDays >= 30;
//       default:
//         return false;
//     }
//   }
// }
