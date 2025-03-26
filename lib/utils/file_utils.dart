import 'dart:io';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  static final CompressionLevel _compressionLevel = CompressionLevel.medium;
  static Future<String> getUniqueFilePath({
    required String documentName,
    required String extension,
    bool inTempDirectory = false,
  }) async {
    try {
      final Directory baseDir = await getApplicationDocumentsDirectory();

      // Define directory path based on whether it's a temp file or not
      final String dirPath;
      if (inTempDirectory) {
        final tempDir = await getTemporaryDirectory();
        dirPath = tempDir.path;
      } else {
        dirPath = path.join(baseDir.path, 'documents');
      }

      logger.info('Creating file in directory: $dirPath');

      // Create directory if it doesn't exist
      final Directory directory = Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        logger.info('Created directory: $dirPath');
      }

      // Clean the document name (remove invalid characters)
      final String cleanName = documentName
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');

      // Generate a timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Create the file path using proper path joining
      final String filePath =
          path.join(dirPath, '${cleanName}_$timestamp.$extension');

      logger.info('Generated file path: $filePath');
      return filePath;
    } catch (e) {
      logger.error('Error in getUniqueFilePath: $e');
      rethrow;
    }
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
      logger.error('Error calculating folder size: $e');
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

  /// Get filename without extension
  static String getFileName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

// Helper method to get appropriate icon for file type
  static IconData getFileTypeIcon(String filePath) {
    final extension =
        path.extension(filePath).toLowerCase().replaceAll('.', '');

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return Icons.description_outlined;
      case 'txt':
        return Icons.text_snippet_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return Icons.slideshow_outlined;
      case 'html':
      case 'htm':
      case 'xml':
        return Icons.code_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

// Helper method to get descriptive label for file type
  static String getFileTypeLabel(String filePath) {
    final extension =
        path.extension(filePath).toLowerCase().replaceAll('.', '');

    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'odt':
        return 'OpenDocument Text';
      case 'rtf':
        return 'Rich Text Format';
      case 'txt':
        return 'Text Document';
      case 'jpg':
      case 'jpeg':
        return 'JPEG Image';
      case 'png':
        return 'PNG Image';
      case 'gif':
        return 'GIF Image';
      case 'webp':
        return 'WebP Image';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'Video File';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'csv':
        return 'CSV Spreadsheet';
      case 'ods':
        return 'OpenDocument Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'odp':
        return 'OpenDocument Presentation';
      case 'html':
      case 'htm':
        return 'HTML Document';
      case 'xml':
        return 'XML Document';
      default:
        return '${extension.toUpperCase()} Document';
    }
  }

  static String? getCompressionLevelTitle([CompressionLevel? level]) {
    final currentLevel = level ?? CompressionLevel.medium;
    switch (currentLevel) {
      case CompressionLevel.low:
        return 'compression_descriptions.low'.tr();
      case CompressionLevel.medium:
        return 'compression_descriptions.medium'.tr();
      case CompressionLevel.high:
        return 'compression_descriptions.high'.tr();
    }
  }

  /// Get user-friendly description for compression level
  static String? getCompressionLevelDescription([CompressionLevel? level]) {
    final currentLevel = level ?? CompressionLevel.medium;
    switch (currentLevel) {
      case CompressionLevel.low:
        return 'compression_details.low'.tr();
      case CompressionLevel.medium:
        return 'compression_details.medium'.tr();
      case CompressionLevel.high:
        return 'compression_details.high'.tr();
    }
  }

  static Future<File> copyFile(
      String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // Ensure destination directory exists
      final destDir = path.dirname(destinationPath);
      final directory = Directory(destDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return await sourceFile.copy(destinationPath);
    } catch (e) {
      logger.error('Error copying file: $e');
      rethrow;
    }
  }

  static Future<Directory> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return await directory.create(recursive: true);
      }
      return directory;
    } catch (e) {
      logger.error('Error creating directory: $e');
      rethrow;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

extension DocumentTypeExtension on Document {
  bool get isPdf {
    final extension = path.extension(pdfPath).toLowerCase();
    return extension == '.pdf';
  }
}
