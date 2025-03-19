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
      frequency: fields[1] as String,
      lastBackupDate: fields[2] as DateTime?,
      backupDestination: fields[3] as BackupDestination,
      maxLocalBackups: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BackupSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.autoBackupEnabled)
      ..writeByte(1)
      ..write(obj.frequency)
      ..writeByte(2)
      ..write(obj.lastBackupDate)
      ..writeByte(3)
      ..write(obj.backupDestination)
      ..writeByte(4)
      ..write(obj.maxLocalBackups);
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
