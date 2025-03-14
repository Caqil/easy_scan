import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/document.dart';
import '../utils/file_utils.dart';
import 'pdf_service.dart';
import 'image_service.dart';

class PdfImportService {
  final PdfService _pdfService = PdfService();
  final ImageService _imageService = ImageService();

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

      return await _processPdfFile(File(file.path!), file.name);
    } catch (e) {
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

      return await _processPdfFile(File(file.path!), file.name);
    } catch (e) {
      throw Exception('Failed to import PDF from iCloud: $e');
    }
  }

  Future<Document> _processPdfFile(File sourceFile, String originalName) async {
    final String docName = path.basenameWithoutExtension(originalName);
    final String targetPath = await FileUtils.getUniqueFilePath(
      documentName: docName,
      extension: 'pdf',
    );

    final int pageCount = await _pdfService.getPdfPageCount(targetPath);

    File? thumbnailFile;
    try {
      thumbnailFile = await _imageService.createThumbnail(
        File(targetPath),
        size: 300,
      );
    } catch (e) {
      print('Failed to generate thumbnail: $e');
    }

    return Document(
      name: docName,
      pdfPath: targetPath,
      pagesPaths: [
        targetPath
      ], 
      pageCount: pageCount,
      thumbnailPath: thumbnailFile?.path,
    );
  }
}
