import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'document.g.dart'; // Generated code for Hive

@HiveType(typeId: 0)
class Document extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String pdfPath;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime modifiedAt;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  String? folderId;

  @HiveField(7)
  bool isFavorite;

  @HiveField(8)
  bool isPasswordProtected;

  @HiveField(9)
  String? password;

  @HiveField(10)
  List<String> pagesPaths;

  @HiveField(11)
  int pageCount;

  @HiveField(12)
  String? thumbnailPath;

  Document({
    String? id,
    required this.name,
    required this.pdfPath,
    required this.pagesPaths,
    this.pageCount = 0,
    this.thumbnailPath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    this.folderId,
    this.isFavorite = false,
    this.isPasswordProtected = false,
    this.password,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        tags = tags ?? [];
}
