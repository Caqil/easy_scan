// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      darkMode: fields[0] as bool,
      biometricAuthEnabled: fields[1] as bool,
      defaultSaveLocation: fields[2] as String,
      autoEnhanceImages: fields[3] as bool,
      cloudBackupEnabled: fields[4] as bool,
      defaultPdfQuality: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.darkMode)
      ..writeByte(1)
      ..write(obj.biometricAuthEnabled)
      ..writeByte(2)
      ..write(obj.defaultSaveLocation)
      ..writeByte(3)
      ..write(obj.autoEnhanceImages)
      ..writeByte(4)
      ..write(obj.cloudBackupEnabled)
      ..writeByte(5)
      ..write(obj.defaultPdfQuality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
