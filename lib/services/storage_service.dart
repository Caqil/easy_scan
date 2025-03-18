import 'dart:io';
import 'package:easy_scan/models/language.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

class StorageService {
  /// Initialize the storage and required boxes
  Future<void> initialize() async {
    try {
      // Initialize Hive
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = '${appDocDir.path}/db';

      // Create DB directory if it doesn't exist
      final dbDir = Directory(dbPath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      Hive.init(dbPath);

      // Register type adapters
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(FolderAdapter());
      Hive.registerAdapter(AppSettingsAdapter());
      // Open boxes
      await Hive.openBox<Document>(AppConstants.documentsBoxName);
      await Hive.openBox<Folder>(AppConstants.foldersBoxName);
      await Hive.openBox(AppConstants.settingsBoxName);

      // Create documents directory if it doesn't exist
      final Directory documentsDir = Directory('${appDocDir.path}/documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      print(
          'Storage initialized successfully. Documents directory: ${documentsDir.path}');
    } catch (e) {
      print('Error initializing storage: $e');
      rethrow;
    }
  }

  /// Clear all temporary files
  Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = await tempDir.list().toList();

      for (var entity in tempFiles) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (e) {
      // Ignore errors when clearing temp files
    }
  }

  /// Get documents directory path
  Future<String> getDocumentsPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/documents';
  }

  /// Get available storage space in MB
  Future<double> getAvailableStorage() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      Directory(appDocDir.path).statSync();

      // This is an approximation as Flutter doesn't have direct API for disk space
      // On real devices, use a platform channel to get actual free space
      return 1000.0; // Placeholder 1GB
    } catch (e) {
      return 0;
    }
  }

  /// Delete a document and its associated files
  Future<bool> deleteDocument(Document document) async {
    try {
      // Delete the PDF file
      final pdfFile = File(document.pdfPath);
      if (await pdfFile.exists()) {
        await pdfFile.delete();
      }

      // Delete thumbnail if exists
      if (document.thumbnailPath != null) {
        final thumbnailFile = File(document.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // Delete all page files if they still exist
      for (var pagePath in document.pagesPaths) {
        final pageFile = File(pagePath);
        if (await pageFile.exists()) {
          await pageFile.delete();
        }
      }

      // Delete from Hive
      final box = Hive.box<Document>(AppConstants.documentsBoxName);
      await box.delete(document.id);

      return true;
    } catch (e) {
      return false;
    }
  }
}
