// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TextElementDataAdapter extends TypeAdapter<TextElementData> {
  @override
  final int typeId = 4;

  @override
  TextElementData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TextElementData(
      text: fields[0] as String,
      boundingBox: fields[1] as Rect,
    );
  }

  @override
  void write(BinaryWriter writer, TextElementData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.boundingBox);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextElementDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScanResultAdapter extends TypeAdapter<ScanResult> {
  @override
  final int typeId = 5;

  @override
  ScanResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResult(
      scannedPages: (fields[0] as List).cast<String>(),
      recognizedText: (fields[1] as List).cast<String>(),
      documentName: fields[2] as String?,
      isSuccess: fields[3] as bool,
      errorMessage: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.scannedPages)
      ..writeByte(1)
      ..write(obj.recognizedText)
      ..writeByte(2)
      ..write(obj.documentName)
      ..writeByte(3)
      ..write(obj.isSuccess)
      ..writeByte(4)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
