// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileSizeAdapter extends TypeAdapter<FileSize> {
  @override
  final int typeId = 2;

  @override
  FileSize read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileSize(
      name: fields[0] as String,
      sizeInBytes: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FileSize obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.sizeInBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileSizeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 3;

  @override
  Folder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Folder(
      id: fields[0] as String,
      name: fields[1] as String,
      parentId: fields[2] as String?,
      color: fields[3] as int,
      iconName: fields[4] as String?,
      files: (fields[5] as List).cast<FileSize>(),
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.files);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
