import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Helper class for backup ZIP file operations
class BackupArchiver {
  /// Create a ZIP file from a directory
  static Future<String> createZipFromDirectory(
      String sourceDir, String zipName) async {
    try {
      // Get temp directory for storing the zip file
      final tempDir = await getTemporaryDirectory();
      final zipPath = path.join(tempDir.path, zipName);

      // Create a zip encoder
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // Add the directory to the zip
      final sourceDirectory = Directory(sourceDir);
      if (!await sourceDirectory.exists()) {
        throw Exception('Source directory does not exist: $sourceDir');
      }

      debugPrint('Creating ZIP from directory: $sourceDir');
      debugPrint('ZIP will be saved to: $zipPath');

      // Get all entities in the directory
      final entities = await sourceDirectory.list(recursive: true).toList();

      // Add each file to the zip
      for (var entity in entities) {
        if (entity is File) {
          // Get the relative path from the source directory
          final relativePath = path.relative(entity.path, from: sourceDir);
          debugPrint('Adding file to ZIP: $relativePath');

          // Add the file to the zip
          encoder.addFile(File(entity.path), relativePath);
        } else if (entity is Directory) {
          // Create directory in the zip
          final relativePath = path.relative(entity.path, from: sourceDir);
          if (relativePath.isNotEmpty) {
            debugPrint('Adding directory to ZIP: $relativePath');
            encoder.addDirectory(Directory(entity.path), includeDirName: false);
          }
        }
      }

      // Close the encoder
      encoder.close();

      debugPrint('ZIP file created successfully: $zipPath');
      return zipPath;
    } catch (e) {
      debugPrint('Error creating ZIP file: $e');
      rethrow;
    }
  }

  /// Extract a ZIP file to a directory
  static Future<String> extractZipToDirectory(String zipPath) async {
    try {
      // Create a temporary directory for extraction
      final tempDir = await getTemporaryDirectory();
      final extractDirName = 'extract_${DateTime.now().millisecondsSinceEpoch}';
      final extractDir = Directory(path.join(tempDir.path, extractDirName));

      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      debugPrint('Extracting ZIP file: $zipPath');
      debugPrint('Extracting to directory: ${extractDir.path}');

      // Read the Zip file from disk
      final bytes = await File(zipPath).readAsBytes();

      // Decode the Zip file
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract the contents of the Zip archive to the extraction directory
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final filePath = path.join(extractDir.path, filename);

          // Create parent directories if they don't exist
          final parentDir = Directory(path.dirname(filePath));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          // Write file
          debugPrint('Extracting file: $filename');
          await File(filePath).writeAsBytes(data);
        } else {
          // Create directory
          final dirPath = path.join(extractDir.path, filename);
          debugPrint('Creating directory: $dirPath');
          await Directory(dirPath).create(recursive: true);
        }
      }

      debugPrint('ZIP file extracted successfully');
      return extractDir.path;
    } catch (e) {
      debugPrint('Error extracting ZIP file: $e');
      rethrow;
    }
  }
}
