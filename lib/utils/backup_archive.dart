import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:scanpro/main.dart';

/// Helper class for backup ZIP file operations
class BackupArchiver {
  /// Create a ZIP file from a directory
  static Future<String> createZipFromDirectory(
      String sourceDir, String zipName) async {
    try {
      // Get application documents directory for storing the zip file
      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${appDir.path}/backups');

      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final zipPath = path.join(backupsDir.path, zipName);

      logger.info('Creating ZIP from directory: $sourceDir');
      logger.info('ZIP will be saved to: $zipPath');

      // Remove any existing file with the same name
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      // Create an Archive object
      final archive = Archive();

      // Add files to the archive
      final sourceDirectory = Directory(sourceDir);
      final entities = await sourceDirectory.list(recursive: true).toList();

      for (var entity in entities) {
        // Get the relative path from source directory
        final relativePath = path.relative(entity.path, from: sourceDir);

        if (entity is File) {
          logger.info('Adding file to archive: $relativePath');

          // Read file content
          List<int> content = await entity.readAsBytes();

          // Create archive file entry
          final archiveFile =
              ArchiveFile(relativePath, content.length, content);
          archive.addFile(archiveFile);
        } else if (entity is Directory && relativePath.isNotEmpty) {
          logger.info('Adding directory to archive: $relativePath');
          // Add an empty entry for directories
          final archiveFile = ArchiveFile(relativePath + '/', 0, []);
          archive.addFile(archiveFile);
        }
      }

      // Encode the archive as a zip and write to file
      final encodedZip = ZipEncoder().encode(archive);

      await zipFile.writeAsBytes(encodedZip);

      // Verify the zip file was created
      if (await zipFile.exists()) {
        final size = await zipFile.length();
        logger
            .info('ZIP file created successfully: $zipPath, size: $size bytes');
        return zipPath;
      } else {
        throw Exception('ZIP file was not created: $zipPath');
      }
    } catch (e) {
      logger.error('Error creating ZIP file: $e');
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

      logger.info('Extracting ZIP file: $zipPath');
      logger.info('Extracting to directory: ${extractDir.path}');

      // Read the Zip file from disk
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('Zip file does not exist: $zipPath');
      }

      final bytes = await zipFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Zip file is empty: $zipPath');
      }

      // Decode the Zip file
      final archive = ZipDecoder().decodeBytes(bytes);
      logger.info('ZIP contains ${archive.length} files/directories');

      // Extract the contents of the Zip archive to the extraction directory
      for (final file in archive) {
        final filename = file.name;
        logger.info('Extracting: $filename');

        if (file.isFile) {
          final data = file.content as List<int>;
          final filePath = path.join(extractDir.path, filename);

          // Create parent directories if they don't exist
          final parentDir = Directory(path.dirname(filePath));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          // Write file
          logger.info('Writing file: $filePath');
          final outputFile = File(filePath);
          await outputFile.writeAsBytes(data);

          // Verify file was written
          if (await outputFile.exists()) {
            final size = await outputFile.length();
            logger.info(
                'File written successfully: $filePath, size: $size bytes');
          } else {
            logger.warning('Failed to write file: $filePath');
          }
        } else {
          // Create directory
          final dirPath = path.join(extractDir.path, filename);
          logger.info('Creating directory: $dirPath');
          await Directory(dirPath).create(recursive: true);
        }
      }

      logger.info('ZIP file extracted successfully to: ${extractDir.path}');
      return extractDir.path;
    } catch (e) {
      logger.error('Error extracting ZIP file: $e');
      rethrow;
    }
  }
}
