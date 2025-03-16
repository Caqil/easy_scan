// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversion_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversionStateAdapter extends TypeAdapter<ConversionState> {
  @override
  final int typeId = 0;

  @override
  ConversionState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversionState(
      inputFormat: fields[0] as FormatOption?,
      outputFormat: fields[1] as FormatOption?,
      selectedFilePath: fields[2] as String?,
      isConverting: fields[3] as bool,
      progress: fields[4] as double,
      error: fields[5] as String?,
      convertedFilePath: fields[6] as String?,
      ocrEnabled: fields[7] as bool,
      quality: fields[8] as int,
      password: fields[9] as String?,
      thumbnailPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversionState obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.inputFormat)
      ..writeByte(1)
      ..write(obj.outputFormat)
      ..writeByte(2)
      ..write(obj.selectedFilePath)
      ..writeByte(3)
      ..write(obj.isConverting)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.error)
      ..writeByte(6)
      ..write(obj.convertedFilePath)
      ..writeByte(7)
      ..write(obj.ocrEnabled)
      ..writeByte(8)
      ..write(obj.quality)
      ..writeByte(9)
      ..write(obj.password)
      ..writeByte(10)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
