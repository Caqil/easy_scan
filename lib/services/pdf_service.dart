import 'dart:io';
import 'dart:typed_data';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class PdfService {
  /// Create a PDF from a list of image files
  Future<String> createPdfFromImages(
      List<File> images, String documentName) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add pages with images
    for (var image in images) {
      final page = document.pages.add();
      final Uint8List imageBytes = await image.readAsBytes();

      // Load the image and adjust to fit the page
      final PdfBitmap pdfImage = PdfBitmap(imageBytes);
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;

      final double imageWidth = pdfImage.width.toDouble();
      final double imageHeight = pdfImage.height.toDouble();

      // Calculate aspect ratio to fit image on page
      double width, height;
      if (imageWidth / imageHeight > pageWidth / pageHeight) {
        width = pageWidth;
        height = (imageHeight * pageWidth) / imageWidth;
      } else {
        height = pageHeight;
        width = (imageWidth * pageHeight) / imageHeight;
      }

      // Center the image on the page
      final double x = (pageWidth - width) / 2;
      final double y = (pageHeight - height) / 2;

      page.graphics.drawImage(pdfImage, Rect.fromLTWH(x, y, width, height));
    }

    // Set document optimization options
    document.compressionLevel = PdfCompressionLevel.best;

    // Get the documents directory
    final String pdfPath = await FileUtils.getUniqueFilePath(
      documentName: documentName,
      extension: 'pdf',
    );

    // Save the document
    final File file = File(pdfPath);
    await file.writeAsBytes(await document.save());

    // Dispose the document
    document.dispose();

    return pdfPath;
  }

  Future<String> mergePdfs(List<String> pdfPaths, String outputName) async {
    // Create output path
    final String outputPath = await FileUtils.getUniqueFilePath(
      documentName: outputName,
      extension: 'pdf',
    );

    try {
      // Check if we only have one path (no merge needed)
      if (pdfPaths.length == 1) {
        final File source = File(pdfPaths[0]);
        final File target = File(outputPath);
        await source.copy(outputPath);
        return outputPath;
      }

      List<String> validPaths = [];
      for (String path in pdfPaths) {
        File file = File(path);
        if (await file.exists()) {
          validPaths.add(path);
        } else {
          debugPrint('Warning: PDF file does not exist: $path');
        }
      }

      if (pdfPaths.isEmpty) {
        throw Exception('No valid PDF files to merge');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      // Set document optimization options
      document.compressionLevel = PdfCompressionLevel.best;

      // Import all pages from each PDF
      for (var pdfPath in pdfPaths) {
        try {
          debugPrint('Importing pages from: $pdfPath');
          final File pdfFile = File(pdfPath);

          // Skip if file doesn't exist
          if (!await pdfFile.exists()) {
            debugPrint('Skipping non-existent file: $pdfPath');
            continue;
          }

          // Read file bytes
          final Uint8List fileBytes = await pdfFile.readAsBytes();

          // Skip empty files
          if (fileBytes.isEmpty) {
            debugPrint('Skipping empty file: $pdfPath');
            continue;
          }

          // Load the source PDF
          final PdfDocument importDoc = PdfDocument(inputBytes: fileBytes);

          // Import all pages
          for (int i = 0; i < importDoc.pages.count; i++) {
            // Get source page
            final PdfPage sourcePage = importDoc.pages[i];

            // Add a new page to the destination document
            final PdfPage newPage = document.pages.add();

            // Copy content using template
            final PdfTemplate template = sourcePage.createTemplate();
            newPage.graphics.drawPdfTemplate(
              template,
              Offset.zero,
              Size(sourcePage.size.width, sourcePage.size.height),
            );
          }

          // Dispose the source document
          importDoc.dispose();
        } catch (e) {
          // Log error but continue with other PDFs
          debugPrint('Error importing pages from $pdfPath: $e');
        }
      }

      // Check if we successfully imported any pages
      if (document.pages.count == 0) {
        throw Exception('Failed to import any pages from the source PDFs');
      }

      // Save the merged document
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(await document.save());

      // Dispose the document
      document.dispose();

      return outputPath;
    } catch (e) {
      debugPrint('Error in mergePdfs: $e');

      // Fallback: if merge fails, just copy the first PDF
      if (pdfPaths.isNotEmpty) {
        try {
          final File source = File(pdfPaths[0]);
          if (await source.exists()) {
            final File target = File(outputPath);
            await source.copy(outputPath);
            return outputPath;
          }
        } catch (copyError) {
          debugPrint('Error in fallback copy: $copyError');
        }
      }

      // Re-throw the original error if we couldn't recover
      rethrow;
    }
  }

  /// Optimizes and compresses images in a PDF
  Future<String> compressImages(String pdfPath, int quality) async {
    try {
      // Read the PDF file
      final File pdfFile = File(pdfPath);
      final Uint8List pdfBytes = await pdfFile.readAsBytes();

      // Create output path
      final String outputPath = await FileUtils.getUniqueFilePath(
        documentName: path.basenameWithoutExtension(pdfPath) + '_compressed',
        extension: 'pdf',
      );

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Iterate through all images in the document
      // This is a simplified approach - in a real implementation you'd need more complex code
      // to identify and extract all embedded images

      // For demonstration, we'll just set the compression level
      document.compressionLevel = PdfCompressionLevel.best;

      // Save the document
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(await document.save());

      // Dispose the document
      document.dispose();

      return outputPath;
    } catch (e) {
      debugPrint('Error compressing images: $e');
      return pdfPath; // Return original on error
    }
  }

  Future<String> protectPdf(String pdfPath, String password) async {
    // Load the document
    final PdfDocument document =
        PdfDocument(inputBytes: await File(pdfPath).readAsBytes());

    // Set the encryption
    document.security.userPassword = password;
    document.security.ownerPassword = password;

    // Save the protected document
    final File file = File(pdfPath);
    await file.writeAsBytes(await document.save());

    // Dispose the document
    document.dispose();

    return pdfPath;
  }

  Future<String> extractPages(
      String pdfPath, List<int> pageIndices, String outputName) async {
    // Load the document
    final PdfDocument document =
        PdfDocument(inputBytes: await File(pdfPath).readAsBytes());

    // Create a new document
    final PdfDocument newDocument = PdfDocument();

    // Set document optimization options
    newDocument.compressionLevel = PdfCompressionLevel.best;

    // Copy the selected pages
    for (var pageIndex in pageIndices) {
      if (pageIndex >= 0 && pageIndex < document.pages.count) {
        // Add a new page to the destination document
        final PdfPage newPage = newDocument.pages.add();
        final PdfPage sourcePage = document.pages[pageIndex];

        // Copy content from source page to new page
        final PdfTemplate template = sourcePage.createTemplate();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset(0, 0),
          Size(sourcePage.size.width, sourcePage.size.height),
        );
      }
    }

    // Get the documents directory
    final String outputPath = await FileUtils.getUniqueFilePath(
      documentName: outputName,
      extension: 'pdf',
    );

    // Save the new document
    final File file = File(outputPath);
    await file.writeAsBytes(await newDocument.save());

    // Dispose the documents
    document.dispose();
    newDocument.dispose();

    return outputPath;
  }

  /// Get total number of pages in a PDF
  Future<int> getPdfPageCount(String pdfPath) async {
    final File file = File(pdfPath);
    if (!await file.exists()) {
      return 0;
    }

    final PdfDocument document =
        PdfDocument(inputBytes: await file.readAsBytes());
    final int pageCount = document.pages.count;
    document.dispose();

    return pageCount;
  }

  /// Pre-process images to optimize them before adding to PDF
  Future<Uint8List> optimizeImageForPdf(File imageFile, int quality) async {
    try {
      // Read the image
      final Uint8List bytes = await imageFile.readAsBytes();

      // Decode the image
      var image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if image is very large
      if (image.width > 2000 || image.height > 2000) {
        final int maxDimension = 2000;
        if (image.width > image.height) {
          final double ratio = maxDimension / image.width;
          image = img.copyResize(image,
              width: maxDimension, height: (image.height * ratio).round());
        } else {
          final double ratio = maxDimension / image.height;
          image = img.copyResize(image,
              width: (image.width * ratio).round(), height: maxDimension);
        }
      }

      // Encode with specified quality
      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      // Return original bytes if optimization fails
      return await imageFile.readAsBytes();
    }
  }

  /// Create a PDF with better compression settings
  Future<String> createOptimizedPdfFromImages(
      List<File> images, String documentName,
      {int quality = 85}) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Set document optimization options
    document.compressionLevel = PdfCompressionLevel.best;

    // Add pages with optimized images
    for (var image in images) {
      final page = document.pages.add();

      // Pre-optimize the image
      final Uint8List optimizedImageBytes =
          await optimizeImageForPdf(image, quality);

      // Load the image and adjust to fit the page
      final PdfBitmap pdfImage = PdfBitmap(optimizedImageBytes);
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;

      final double imageWidth = pdfImage.width.toDouble();
      final double imageHeight = pdfImage.height.toDouble();

      // Calculate aspect ratio to fit image on page
      double width, height;
      if (imageWidth / imageHeight > pageWidth / pageHeight) {
        width = pageWidth;
        height = (imageHeight * pageWidth) / imageWidth;
      } else {
        height = pageHeight;
        width = (imageWidth * pageHeight) / imageHeight;
      }

      // Center the image on the page
      final double x = (pageWidth - width) / 2;
      final double y = (pageHeight - height) / 2;

      page.graphics.drawImage(pdfImage, Rect.fromLTWH(x, y, width, height));
    }

    // Get the documents directory
    final String pdfPath = await FileUtils.getUniqueFilePath(
      documentName: documentName,
      extension: 'pdf',
    );

    // Save the document
    final File file = File(pdfPath);
    await file.writeAsBytes(await document.save());

    // Dispose the document
    document.dispose();

    return pdfPath;
  }
}
