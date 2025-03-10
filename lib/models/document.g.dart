// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 0;

  @override
  Document read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Document(
      id: fields[0] as String?,
      name: fields[1] as String,
      pdfPath: fields[2] as String,
      pagesPaths: (fields[10] as List).cast<String>(),
      pageCount: fields[11] as int,
      thumbnailPath: fields[12] as String?,
      createdAt: fields[3] as DateTime?,
      modifiedAt: fields[4] as DateTime?,
      tags: (fields[5] as List?)?.cast<String>(),
      folderId: fields[6] as String?,
      isFavorite: fields[7] as bool,
      isPasswordProtected: fields[8] as bool,
      password: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.pdfPath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.folderId)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.isPasswordProtected)
      ..writeByte(9)
      ..write(obj.password)
      ..writeByte(10)
      ..write(obj.pagesPaths)
      ..writeByte(11)
      ..write(obj.pageCount)
      ..writeByte(12)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
