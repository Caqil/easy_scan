import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  /// Merge multiple PDFs into one
  Future<String> mergePdfs(List<String> pdfPaths, String outputName) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Import all pages from each PDF
    for (var pdfPath in pdfPaths) {
      final PdfDocument importDoc =
          PdfDocument(inputBytes: await File(pdfPath).readAsBytes());

      for (int i = 0; i < importDoc.pages.count; i++) {
        // Copy each page - use copyPage or addPage instead of importPage
        final PdfPage newPage = document.pages.add();
        final PdfPage sourcePage = importDoc.pages[i];

        // Copy content from source page to new page
        final PdfTemplate template = sourcePage.createTemplate();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset(0, 0),
          Size(sourcePage.size.width, sourcePage.size.height),
        );
      }

      importDoc.dispose();
    }

    // Get the documents directory
    final String outputPath = await FileUtils.getUniqueFilePath(
      documentName: outputName,
      extension: 'pdf',
    );

    // Save the merged document
    final File file = File(outputPath);
    await file.writeAsBytes(await document.save());

    // Dispose the document
    document.dispose();

    return outputPath;
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
}
