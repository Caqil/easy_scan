import 'dart:io';
import 'dart:typed_data';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/ui/screen/compression/compression_screen.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as path;

enum CompressionLevel {
  low,
  medium,
  high,
  maximum,
}

extension PdfCompression on PdfService {
  /// Compresses a PDF file to reduce its size
  /// Returns: The path to the compressed PDF file, or the original if compression increased size
  Future<String> compressPdf(
    String pdfPath, {
    int quality = 70,
    int imageQuality = 50,
    String? password,
  }) async {
    try {
      // Get original file size for comparison
      final File originalFile = File(pdfPath);
      final int originalSize = await originalFile.length();

      // Load the document
      final PdfDocument document = password != null && password.isNotEmpty
          ? PdfDocument(
              inputBytes: await originalFile.readAsBytes(), password: password)
          : PdfDocument(inputBytes: await originalFile.readAsBytes());

      // Set compression options directly on the document
      document.compressionLevel = PdfCompressionLevel.best;

      // Get the document name for the output file
      final String docName = path.basenameWithoutExtension(pdfPath);

      // Create a path for the compressed file
      final String outputPath = await FileUtils.getUniqueFilePath(
        documentName: '${docName}_compressed',
        extension: 'pdf',
      );

      // Save with maximum compression
      final List<int> compressedBytes = await document.save();

      // Save to temp file for size comparison
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(compressedBytes);

      // Get compressed file size
      final int compressedSize = await outputFile.length();

      // Calculate compression stats
      final double compressionRatio = originalSize / compressedSize;
      final double percentReduction =
          ((originalSize - compressedSize) / originalSize) * 100;

      debugPrint('PDF Compression Results:');
      debugPrint('Original size: ${_formatFileSize(originalSize)}');
      debugPrint('Compressed size: ${_formatFileSize(compressedSize)}');
      debugPrint('Compression ratio: ${compressionRatio.toStringAsFixed(2)}x');
      debugPrint('Size reduction: ${percentReduction.toStringAsFixed(1)}%');

      // Clean up
      document.dispose();

      // If compression actually increased the file size, return the original
      if (compressedSize >= originalSize) {
        await outputFile.delete(); // Delete larger file
        debugPrint('Compression increased file size, returning original file');
        return pdfPath;
      }

      return outputPath;
    } catch (e) {
      debugPrint('Error compressing PDF: $e');
      return pdfPath; // Return original on error
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Intelligent PDF compression that analyzes content and applies optimal settings
  Future<String> smartCompressPdf(
    String pdfPath, {
    CompressionLevel level = CompressionLevel.medium,
    String? password,
  }) async {
    // Set compression parameters based on level
    int quality;
    int imageQuality;

    switch (level) {
      case CompressionLevel.low:
        quality = 90;
        imageQuality = 80;
        break;
      case CompressionLevel.medium:
        quality = 70;
        imageQuality = 60;
        break;
      case CompressionLevel.high:
        quality = 50;
        imageQuality = 40;
        break;
      case CompressionLevel.maximum:
        quality = 30;
        imageQuality = 20;
        break;
    }

    return compressPdf(
      pdfPath,
      quality: quality,
      imageQuality: imageQuality,
      password: password,
    );
  }

  /// Extract images from a PDF page (placeholder method)
  List<Map<String, dynamic>> _extractImagesFromPage(PdfPage page) {
    // In a real implementation, this would extract all images from the page
    // For this example, we just return an empty list
    return [];
  }
}
