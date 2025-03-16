import 'package:hive/hive.dart';

part 'file_folder.g.dart';

@HiveType(typeId: 2)
class FileSize extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int sizeInBytes;

  FileSize({required this.name, required this.sizeInBytes});
}

@HiveType(typeId: 3)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? parentId;

  @HiveField(3)
  final int color;

  @HiveField(4)
  final String? iconName;

  @HiveField(5)
  final List<FileSize> files;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.color = 0xFF2196F3,
    this.iconName,
    this.files = const [],
  });
}
