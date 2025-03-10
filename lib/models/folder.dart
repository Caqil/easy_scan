import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'folder.g.dart'; // Generated code for Hive

@HiveType(typeId: 1)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String? parentId;

  @HiveField(4)
  int color;

  @HiveField(5)
  String? iconName;

  Folder({
    String? id,
    required this.name,
    this.parentId,
    this.color = 0xFF2196F3,
    this.iconName,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
}
