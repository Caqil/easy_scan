class FileSize {
  final String name;
  final int sizeInBytes; // Size in bytes

  FileSize({required this.name, required this.sizeInBytes});
}

class Folder {
  final String id;
  final String name;
  final String? parentId;
  final int color;
  final String? iconName;
  final List<FileSize> files; // List of files in this folder

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.color = 0xFF2196F3, // Default blue color
    this.iconName,
    this.files = const [], // Default to empty list
  });
}
