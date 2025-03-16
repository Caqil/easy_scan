import 'dart:io';
import 'package:easy_scan/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../models/document.dart';
import '../utils/file_utils.dart';
import 'pdf_service.dart';
import 'image_service.dart';

class PdfImportService {
  final PdfService _pdfService = PdfService();

  Future<Document?> importPdfFromLocal() async {
    try {
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final PlatformFile file = result.files.first;

      if (file.path == null) {
        return null;
      }

      // Verify source file exists before proceeding
      final sourceFile = File(file.path!);
      if (!await sourceFile.exists()) {
        throw Exception('Selected PDF file does not exist at ${file.path}');
      }

      return await _processPdfFile(sourceFile, file.name);
    } catch (e) {
      debugPrint('Failed to import PDF: $e');
      throw Exception('Failed to import PDF: $e');
    }
  }

  Future<Document?> importPdfFromICloud() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowCompression: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final PlatformFile file = result.files.first;

      if (file.path == null) {
        return null;
      }

      // Verify source file exists before proceeding
      final sourceFile = File(file.path!);
      if (!await sourceFile.exists()) {
        throw Exception('Selected PDF file does not exist at ${file.path}');
      }

      return await _processPdfFile(sourceFile, file.name);
    } catch (e) {
      debugPrint('Failed to import PDF from iCloud: $e');
      throw Exception('Failed to import PDF from iCloud: $e');
    }
  }

  Future<Document> _processPdfFile(File sourceFile, String originalName) async {
    // Create a name for the document based on original filename
    final String docName = path.basenameWithoutExtension(originalName);

    try {
      // Get a unique target path
      final String targetPath = await FileUtils.getUniqueFilePath(
        documentName: docName,
        extension: 'pdf',
      );

      debugPrint('Copying PDF to: $targetPath');

      // Ensure target directory exists
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Copy the file to the target path
      final targetFile = await sourceFile.copy(targetPath);

      // Verify the file was copied correctly
      if (!await targetFile.exists()) {
        throw Exception('Failed to copy PDF file to $targetPath');
      }

      debugPrint('PDF copied successfully to: $targetPath');

      // Read file size to verify it's not empty
      final fileSize = await targetFile.length();
      if (fileSize == 0) {
        throw Exception('Copied PDF file is empty');
      }

      // Get page count
      int pageCount = 1;
      try {
        pageCount = await _pdfService.getPdfPageCount(targetPath);
        debugPrint('PDF page count: $pageCount');
      } catch (e) {
        debugPrint('Error getting PDF page count: $e');
        // Continue with default page count 1
      }

      // Initialize thumbnailPath as null
      String? thumbnailPath;
      final imageService = ImageService();
      // Generate thumbnail
      try {
        final thumbnailFile = await imageService.createThumbnail(
            File(targetPath),
            size: AppConstants.thumbnailSize);

        thumbnailPath = thumbnailFile.path;
        debugPrint('Thumbnail created at: $thumbnailPath');

        // Verify thumbnail exists
        if (!await File(thumbnailPath).exists()) {
          debugPrint('Warning: Thumbnail file does not exist after creation');
          thumbnailPath = null;
        }
      } catch (e) {
        debugPrint('Failed to generate thumbnail: $e');
        // Continue without thumbnail - it's not critical
      }

      // Create and return document model
      return Document(
        name: docName,
        pdfPath: targetPath,
        pagesPaths: [targetPath],
        pageCount: pageCount,
        thumbnailPath: thumbnailPath,
      );
    } catch (e) {
      debugPrint('Error in _processPdfFile: $e');
      throw Exception('Error processing PDF file: $e');
    }
  }
}

final pdfImportServiceProvider = Provider<PdfImportService>((ref) {
  return PdfImportService();
});
