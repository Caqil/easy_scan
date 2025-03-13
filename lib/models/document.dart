import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'document.g.dart';

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
// Add this method to your Document class in lib/models/document.dart

// Inside the Document class:
  Document copyWith({
    String? id,
    String? name,
    String? pdfPath,
    List<String>? pagesPaths,
    int? pageCount,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    String? folderId,
    bool? isFavorite,
    bool? isPasswordProtected,
    String? password,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      pdfPath: pdfPath ?? this.pdfPath,
      pagesPaths: pagesPaths ?? this.pagesPaths,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      folderId: folderId, // Allow null to remove folder assignment
      isFavorite: isFavorite ?? this.isFavorite,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
      password: password ?? this.password,
    );
  }

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
