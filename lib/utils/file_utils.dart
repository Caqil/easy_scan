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

 

  Future<String> calculateFolderSize(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return '0 B';

    int totalSizeInBytes = 0;

    try {
      // List all files and directories in the current directory
      final entities = directory.listSync(recursive: false, followLinks: false);
      for (var entity in entities) {
        if (entity is File) {
          // Get size of individual file
          final fileSize = await FileUtils.getFileSize(entity.path);
          // Parse the size string to extract the numeric value and unit
          final sizeParts = fileSize.split(' ');
          if (sizeParts.length == 2) {
            final sizeValue = double.parse(sizeParts[0]);
            final unit = sizeParts[1];
            totalSizeInBytes += _convertToBytes(sizeValue, unit);
          }
        } else if (entity is Directory) {
          // Recursively calculate size of subdirectories
          final subDirSize = await calculateFolderSize(entity.path);
          final sizeParts = subDirSize.split(' ');
          if (sizeParts.length == 2) {
            final sizeValue = double.parse(sizeParts[0]);
            final unit = sizeParts[1];
            totalSizeInBytes += _convertToBytes(sizeValue, unit);
          }
        }
      }
    } catch (e) {
      print('Error calculating folder size: $e');
      return 'N/A';
    }

    // Format the total size
    return _formatSize(totalSizeInBytes);
  }

// Helper method to convert size with unit to bytes
  int _convertToBytes(double value, String unit) {
    switch (unit) {
      case 'B':
        return value.toInt();
      case 'KB':
        return (value * 1024).toInt();
      case 'MB':
        return (value * 1024 * 1024).toInt();
      case 'GB':
        return (value * 1024 * 1024 * 1024).toInt();
      case 'TB':
        return (value * 1024 * 1024 * 1024 * 1024).toInt();
      default:
        return 0;
    }
  }

// Use the existing formatSize method from FileUtils or keep the custom one
  String _formatSize(int sizeInBytes) {
    if (sizeInBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(sizeInBytes) / log(1024)).floor();
    return '${(sizeInBytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
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
