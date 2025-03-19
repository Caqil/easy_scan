import 'dart:io';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/services/pdf_service.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// Service for merging multiple PDF files
class PdfMergerService {
  final PdfService pdfService = PdfService();
  final ImageService imageService = ImageService();

  /// Allows selecting multiple PDF files and returns their paths
  Future<List<String>> selectPdfs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      // Filter out any null paths and verify files exist
      List<String> validPaths = [];
      for (final file in result.files) {
        if (file.path != null) {
          final pdfFile = File(file.path!);
          if (await pdfFile.exists()) {
            validPaths.add(file.path!);
          }
        }
      }

      return validPaths;
    } catch (e) {
      logger.error('Error selecting PDFs: $e');
      throw Exception('Failed to select PDF files: $e');
    }
  }

  /// Merges multiple PDF files into a single document
  Future<Document> mergePdfs(List<String> pdfPaths, String outputName) async {
    try {
      if (pdfPaths.isEmpty) {
        throw Exception('No PDF files provided for merging');
      }

      // Calculate total page count
      int totalPageCount = 0;
      for (final pdfPath in pdfPaths) {
        totalPageCount += await pdfService.getPdfPageCount(pdfPath);
      }

      // Merge the PDFs
      final mergedPdfPath = await pdfService.mergePdfs(pdfPaths, outputName);

      // Generate thumbnail from the first PDF
      final thumbnailFile = await imageService.createThumbnail(
        File(pdfPaths.first),
        size: AppConstants.thumbnailSize,
      );

      // Create the document model
      return Document(
        name: outputName,
        pdfPath: mergedPdfPath,
        pagesPaths: [mergedPdfPath], // The merged PDF is a single file
        pageCount: totalPageCount,
        thumbnailPath: thumbnailFile.path,
      );
    } catch (e) {
      logger.error('Error merging PDFs: $e');
      throw Exception('Failed to merge PDF files: $e');
    }
  }

  /// Lists documents that are PDFs from the provided list
  List<Document> filterPdfDocuments(List<Document> documents) {
    return documents.where((doc) {
      final extension = path.extension(doc.pdfPath).toLowerCase();
      return extension == '.pdf';
    }).toList();
  }

  /// Merges documents from the app's document library
  Future<Document> mergeDocuments(
      List<Document> documents, String outputName) async {
    try {
      if (documents.isEmpty) {
        throw Exception('No documents provided for merging');
      }

      // Extract the PDF paths
      final List<String> pdfPaths =
          documents.map((doc) => doc.pdfPath).toList();

      // Use the existing merge function
      return await mergePdfs(pdfPaths, outputName);
    } catch (e) {
      logger.error('Error merging documents: $e');
      throw Exception('Failed to merge documents: $e');
    }
  }
}

/// Provider for the PDF merger service
final pdfMergerServiceProvider = Provider<PdfMergerService>((ref) {
  return PdfMergerService();
});
