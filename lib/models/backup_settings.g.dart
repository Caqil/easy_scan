// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupSettingsAdapter extends TypeAdapter<BackupSettings> {
  @override
  final int typeId = 4;

  @override
  BackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupSettings(
      autoBackupEnabled: fields[0] as bool,
      autoBackupFrequency: fields[1] as String,
      autoBackupDestination: fields[2] as String,
      lastBackupDate: fields[3] as DateTime?,
      nextScheduledBackup: fields[4] as DateTime?,
      maxLocalBackups: fields[5] as int,
      maxCloudBackups: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BackupSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.autoBackupEnabled)
      ..writeByte(1)
      ..write(obj.autoBackupFrequency)
      ..writeByte(2)
      ..write(obj.autoBackupDestination)
      ..writeByte(3)
      ..write(obj.lastBackupDate)
      ..writeByte(4)
      ..write(obj.nextScheduledBackup)
      ..writeByte(5)
      ..write(obj.maxLocalBackups)
      ..writeByte(6)
      ..write(obj.maxCloudBackups);
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
