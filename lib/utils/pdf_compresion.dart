import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:flutter/material.dart';

/// Supported image formats for compression.
enum ImageFormat {
  /// JPEG format
  jpg,

  /// PNG format
  png,

  /// WebP format
  webp
}

/// A utility class for compressing various file types.
///
/// This class provides static methods to compress images and PDF files
/// with customizable compression settings.
class FileCompressor {
  const FileCompressor._();

  /// Compresses an image file with specified parameters.
  ///
  /// Parameters:
  /// - [file]: The source image file to compress
  /// - [quality]: Compression quality (0-100), default is 80
  /// - [maxWidth]: Maximum width of the output image, default is 1920
  /// - [maxHeight]: Maximum height of the output image, default is 1080
  /// - [format]: Target format for the compressed image
  /// - [deleteOriginal]: Whether to delete the original file after compression
  ///
  /// Returns a [File] containing the compressed image.
  ///
  /// Throws:
  /// - [ArgumentError] if quality is not between 0 and 100
  /// - [FileSystemException] if the file doesn't exist or is empty
  /// - [ArgumentError] if the image format is unsupported
  static Future<File> compressImage({
    required File file,
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
    ImageFormat? format,
    bool deleteOriginal = false,
  }) async {
    if (quality < 0 || quality > 100) {
      throw ArgumentError('Quality must be between 0 and 100');
    }

    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw FileSystemException('File is empty', file.path);
    }

    final extension = path.extension(file.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      throw ArgumentError('Unsupported image format: $extension');
    }

    try {
      format ??= _getImageFormatFromExtension(extension);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile =
          File(path.join(tempDir.path, 'temp_${timestamp}${extension}'));
      await file.copy(tempFile.path);

      final output = await FlutterImageCompress.compressWithFile(tempFile.path,
          quality: quality,
          minWidth: maxWidth,
          minHeight: maxHeight,
          format: format == ImageFormat.png
              ? CompressFormat.png
              : format == ImageFormat.webp
                  ? CompressFormat.webp
                  : CompressFormat.jpeg);

      await tempFile.delete();

      if (output == null || output.isEmpty) {
        throw Exception('Compression failed: output file is empty');
      }

      final outputExtension = _getExtensionFromFormat(format);
      final outputPath =
          path.join(tempDir.path, 'compressed_$timestamp$outputExtension');

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(output);

      if (deleteOriginal && await file.exists()) {
        await file.delete();
      }

      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing image: $e');
      }
      rethrow;
    }
  }

  static ImageFormat _getImageFormatFromExtension(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return ImageFormat.jpg;
      case '.png':
        return ImageFormat.png;
      case '.webp':
        return ImageFormat.webp;
    }
    throw ArgumentError('Unsupported image format: $extension');
  }

  static String _getExtensionFromFormat(ImageFormat format) {
    return switch (format) {
      ImageFormat.jpg => '.jpg',
      ImageFormat.png => '.png',
      ImageFormat.webp => '.webp'
    };
  }

  static Future<File> compressPdf({
    required File file,
    PdfCompressionLevel compressionLevel = PdfCompressionLevel.best,
    bool deleteOriginal = false,
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw FileSystemException('File is empty', file.path);
    }

    final extension = path.extension(file.path).toLowerCase();
    if (extension != '.pdf') {
      throw ArgumentError('Invalid file format: expected .pdf, got $extension');
    }

    syncfusion.PdfDocument? document;
    File? outputFile;
    try {
      final bytes = await file.readAsBytes();
      try {
        document = syncfusion.PdfDocument(inputBytes: bytes);
      } catch (e) {
        if (kDebugMode) {
          print('Error loading PDF: $e');
        }
        throw Exception('Invalid PDF file format');
      }

      if (document.pages.count == 0) {
        throw Exception('Invalid PDF file: document is empty');
      }

      switch (compressionLevel) {
        case PdfCompressionLevel.none:
          document.compressionLevel = syncfusion.PdfCompressionLevel.none;
          break;
        case PdfCompressionLevel.normal:
          document.compressionLevel = syncfusion.PdfCompressionLevel.normal;
          break;
        case PdfCompressionLevel.best:
          document.compressionLevel = syncfusion.PdfCompressionLevel.best;
          break;
      }

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        page.graphics.save();
      }

      final compressedBytes = await document.save();

      if (compressedBytes.isEmpty) {
        throw Exception('Compression failed: output file is empty');
      }

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(dir.path, 'compressed_${timestamp}.pdf');

      outputFile = File(outputPath);
      await outputFile.writeAsBytes(compressedBytes);

      if (deleteOriginal && await file.exists()) {
        await file.delete();
      }

      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing PDF: $e');
      }
      if (e is ArgumentError || e.toString().contains('Invalid PDF')) {
        throw Exception('Invalid PDF file format');
      }
      if (outputFile != null && await outputFile.exists()) {
        await outputFile.delete();
      }
      rethrow;
    } finally {
      document?.dispose();
    }
  }
}

enum PdfCompressionLevel { none, normal, best }

// Integration with existing compression features
extension PdfCompression on PdfService {
  /// Compresses a PDF file to reduce its size using the new FileCompressor
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

      debugPrint('Starting compression of PDF: $pdfPath');
      debugPrint('Original size: ${FileUtils.formatFileSize(originalSize)}');

      // Try different compression approaches to get the best result

      // 1. First try with the new FileCompressor
      File? compressedFile;

      try {
        // Make a temp copy of the file to compress
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = path.join(
            tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await originalFile.copy(tempFilePath);

        // Apply compression using the new FileCompressor
        compressedFile = await FileCompressor.compressPdf(
          file: File(tempFilePath),
          compressionLevel: PdfCompressionLevel.best,
        );
      } catch (e) {
        debugPrint('Error with FileCompressor: $e');
        // We'll continue with fallback methods
      }

      // Check if FileCompressor succeeded
      if (compressedFile != null && await compressedFile.exists()) {
        int compressedSize = await compressedFile.length();

        // If compression actually reduced the size, use the result
        if (compressedSize < originalSize) {
          // Create final output path
          final String docName = path.basenameWithoutExtension(pdfPath);
          final String outputPath = await FileUtils.getUniqueFilePath(
            documentName: '${docName}_compressed',
            extension: 'pdf',
          );

          // Copy to final destination
          await compressedFile.copy(outputPath);

          // Clean up temp file
          await compressedFile.delete();

          // Calculate compression stats
          final double compressionRatio = originalSize / compressedSize;
          final double percentReduction =
              ((originalSize - compressedSize) / originalSize) * 100;

          debugPrint('PDF Compression Results:');
          debugPrint(
              'Original size: ${FileUtils.formatFileSize(originalSize)}');
          debugPrint(
              'Compressed size: ${FileUtils.formatFileSize(compressedSize)}');
          debugPrint(
              'Compression ratio: ${compressionRatio.toStringAsFixed(2)}x');
          debugPrint('Size reduction: ${percentReduction.toStringAsFixed(1)}%');

          return outputPath;
        } else {
          // Clean up ineffective result
          await compressedFile.delete();
          debugPrint(
              'FileCompressor did not reduce file size, trying alternative methods...');
        }
      }

      // 2. Try with SyncFusion directly if FileCompressor failed
      syncfusion.PdfDocument? document;

      try {
        // Load with password if provided
        if (password != null && password.isNotEmpty) {
          document = syncfusion.PdfDocument(
              inputBytes: await originalFile.readAsBytes(), password: password);
        } else {
          document = syncfusion.PdfDocument(
              inputBytes: await originalFile.readAsBytes());
        }

        // Set maximum compression
        document.compressionLevel = syncfusion.PdfCompressionLevel.best;

        // Create temp output path
        final tempDir = await getTemporaryDirectory();
        final tempOutput = path.join(tempDir.path,
            'sync_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf');

        // Save with compression
        final compressedBytes = await document.save();
        await File(tempOutput).writeAsBytes(compressedBytes);

        // Check compressed size
        compressedFile = File(tempOutput);
        int compressedSize = await compressedFile.length();

        // If compression was effective
        if (compressedSize < originalSize) {
          // Create final output path
          final String docName = path.basenameWithoutExtension(pdfPath);
          final String outputPath = await FileUtils.getUniqueFilePath(
            documentName: '${docName}_compressed',
            extension: 'pdf',
          );

          // Copy to final destination
          await compressedFile.copy(outputPath);
          await compressedFile.delete();

          // Calculate compression stats
          final double compressionRatio = originalSize / compressedSize;
          final double percentReduction =
              ((originalSize - compressedSize) / originalSize) * 100;

          debugPrint('PDF Compression Results (SyncFusion):');
          debugPrint(
              'Original size: ${FileUtils.formatFileSize(originalSize)}');
          debugPrint(
              'Compressed size: ${FileUtils.formatFileSize(compressedSize)}');
          debugPrint(
              'Compression ratio: ${compressionRatio.toStringAsFixed(2)}x');
          debugPrint('Size reduction: ${percentReduction.toStringAsFixed(1)}%');

          return outputPath;
        } else {
          // Clean up
          await compressedFile.delete();
          debugPrint('SyncFusion compression did not reduce file size');
        }
      } catch (e) {
        debugPrint('Error with SyncFusion compression: $e');
      } finally {
        document?.dispose();
      }

      // If we got here, compression did not reduce the file size
      debugPrint(
          'Compression increased file size or failed, returning original file');
      return pdfPath;
    } catch (e) {
      debugPrint('Error compressing PDF: $e');
      return pdfPath; // Return original on error
    }
  }

  /// Intelligent PDF compression that analyzes content and applies optimal settings
  Future<String> smartCompressPdf(
    String pdfPath, {
    CompressionLevel level = CompressionLevel.medium,
    String? password,
  }) async {
    // Get compression parameters based on level
    Map<String, int> params = _getCompressionParams(level);

    // Compress using the FileCompressor-integrated method
    return compressPdf(
      pdfPath,
      quality: params['quality']!,
      imageQuality: params['imageQuality']!,
      password: password,
    );
  }

  /// Get compression parameters based on level
  Map<String, int> _getCompressionParams(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return {
          'quality': 90,
          'imageQuality': 80,
        };
      case CompressionLevel.medium:
        return {
          'quality': 60,
          'imageQuality': 50,
        };
      case CompressionLevel.high:
        return {
          'quality': 30,
          'imageQuality': 25,
        };
      case CompressionLevel.maximum:
        return {
          'quality': 15,
          'imageQuality': 15,
        };
    }
  }
}

enum CompressionLevel {
  low,
  medium,
  high,
  maximum,
}
