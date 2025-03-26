// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupSettingsAdapter extends TypeAdapter<BackupSettings> {
  @override
  final int typeId = 7;

  @override
  BackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupSettings(
      autoBackupEnabled: fields[0] as bool,
      backupFrequency: fields[1] as BackupFrequency,
      backupDestination: fields[2] as BackupDestination,
      lastBackupDate: fields[3] as DateTime?,
      nextBackupDate: fields[4] as DateTime?,
      maxLocalBackups: fields[5] as int,
      includeDocuments: fields[6] as bool,
      includeSettings: fields[7] as bool,
      includeFolders: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BackupSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.autoBackupEnabled)
      ..writeByte(1)
      ..write(obj.backupFrequency)
      ..writeByte(2)
      ..write(obj.backupDestination)
      ..writeByte(3)
      ..write(obj.lastBackupDate)
      ..writeByte(4)
      ..write(obj.nextBackupDate)
      ..writeByte(5)
      ..write(obj.maxLocalBackups)
      ..writeByte(6)
      ..write(obj.includeDocuments)
      ..writeByte(7)
      ..write(obj.includeSettings)
      ..writeByte(8)
      ..write(obj.includeFolders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupFrequencyAdapter extends TypeAdapter<BackupFrequency> {
  @override
  final int typeId = 5;

  @override
  BackupFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BackupFrequency.daily;
      case 1:
        return BackupFrequency.weekly;
      case 2:
        return BackupFrequency.monthly;
      case 3:
        return BackupFrequency.manual;
      default:
        return BackupFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, BackupFrequency obj) {
    switch (obj) {
      case BackupFrequency.daily:
        writer.writeByte(0);
        break;
      case BackupFrequency.weekly:
        writer.writeByte(1);
        break;
      case BackupFrequency.monthly:
        writer.writeByte(2);
        break;
      case BackupFrequency.manual:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupDestinationAdapter extends TypeAdapter<BackupDestination> {
  @override
  final int typeId = 6;

  @override
  BackupDestination read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BackupDestination.local;
      case 1:
        return BackupDestination.iCloud;
      case 2:
        return BackupDestination.googleDrive;
      default:
        return BackupDestination.local;
    }
  }

  @override
  void write(BinaryWriter writer, BackupDestination obj) {
    switch (obj) {
      case BackupDestination.local:
        writer.writeByte(0);
        break;
      case BackupDestination.iCloud:
        writer.writeByte(1);
        break;
      case BackupDestination.googleDrive:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupDestinationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
