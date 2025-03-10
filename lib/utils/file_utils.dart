import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  /// Get a unique file path with a timestamp
  static Future<String> getUniqueFilePath({
    required String documentName,
    required String extension,
    bool inTempDirectory = false,
  }) async {
    final Directory directory = inTempDirectory
        ? await getTemporaryDirectory()
        : Directory(
            '${(await getApplicationDocumentsDirectory()).path}/documents');

    // Create the directory if it doesn't exist
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Clean the document name (remove invalid characters)
    final String cleanName = documentName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    // Generate a timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Create the file path
    final String filePath =
        '${directory.path}/${cleanName}_$timestamp.$extension';

    return filePath;
  }

  /// Get file size in a human-readable format
  static Future<String> getFileSize(String filePath, {int decimals = 1}) async {
    final file = File(filePath);
    if (!await file.exists()) return '0 B';

    final bytes = await file.length();
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Check if a file exists
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Delete a file if it exists
  static Future<bool> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Get file extension from path
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceAll('.', '');
  }

  /// Get filename without extension
  static String getFileName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Copy file to new location
  static Future<File> copyFile(
      String sourcePath, String destinationPath) async {
    return await File(sourcePath).copy(destinationPath);
  }

  /// Create a directory if it doesn't exist
  static Future<Directory> createDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return await directory.create(recursive: true);
    }
    return directory;
  }
}
