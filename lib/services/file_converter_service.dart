// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;

// /// A service for converting various file types to PDF without relying on external plugins
// class PdfConverter {
//   /// Converts a file to PDF format
//   /// Returns the path to the generated PDF file
//   Future<String> convertToPdf(String filePath) async {
//     final extension =
//         path.extension(filePath).toLowerCase().replaceAll('.', '');

//     switch (extension) {
//       case 'jpg':
//       case 'jpeg':
//       case 'png':
//         return await _convertImageToPdf(filePath);
//       case 'txt':
//         return await _convertTextToPdf(filePath);
//       case 'html':
//         return await _convertHtmlToPdf(filePath);
//       case 'doc':
//       case 'docx':
//         return await _convertDocToPdf(filePath);
//       case 'xls':
//       case 'xlsx':
//         return await _convertExcelToPdf(filePath);
//       default:
//         throw UnsupportedError('File type not supported: $extension');
//     }
//   }

//   /// Converts multiple files to a single PDF
//   /// Returns the path to the generated PDF file
//   Future<String> convertMultipleToPdf(
//       List<String> filePaths, String outputName) async {
//     final List<Uint8List> pdfPages = [];

//     for (final filePath in filePaths) {
//       final singlePdfPath = await convertToPdf(filePath);
//       final pdfBytes = await File(singlePdfPath).readAsBytes();
//       pdfPages.add(pdfBytes);
//     }

//     return await _mergePdfPages(pdfPages, outputName);
//   }

//   /// Converts an image file to PDF
//   Future<String> _convertImageToPdf(String imagePath) async {
//     final file = File(imagePath);
//     final bytes = await file.readAsBytes();
//     final fileName = path.basenameWithoutExtension(imagePath);

//     // Create PDF content
//     final pdfBytes = await _createPdfFromImage(bytes);

//     // Save PDF
//     final outputPath = await _getUniqueFilePath('$fileName.pdf');
//     final outputFile = File(outputPath);
//     await outputFile.writeAsBytes(pdfBytes);

//     return outputPath;
//   }

//   /// Converts a text file to PDF
//   Future<String> _convertTextToPdf(String textFilePath) async {
//     final file = File(textFilePath);
//     final text = await file.readAsString();
//     final fileName = path.basenameWithoutExtension(textFilePath);

//     // Create PDF content
//     final pdfBytes = await _createPdfFromText(text);

//     // Save PDF
//     final outputPath = await _getUniqueFilePath('$fileName.pdf');
//     final outputFile = File(outputPath);
//     await outputFile.writeAsBytes(pdfBytes);

//     return outputPath;
//   }

//   /// Converts an HTML file to PDF
//   Future<String> _convertHtmlToPdf(String htmlFilePath) async {
//     final file = File(htmlFilePath);
//     final html = await file.readAsString();
//     final fileName = path.basenameWithoutExtension(htmlFilePath);

//     // Create PDF content
//     final pdfBytes = await _createPdfFromHtml(html);

//     // Save PDF
//     final outputPath = await _getUniqueFilePath('$fileName.pdf');
//     final outputFile = File(outputPath);
//     await outputFile.writeAsBytes(pdfBytes);

//     return outputPath;
//   }

//   /// Converts a Word document to PDF
//   Future<String> _convertDocToPdf(String docFilePath) async {
//     final file = File(docFilePath);
//     final bytes = await file.readAsBytes();
//     final fileName = path.basenameWithoutExtension(docFilePath);

//     // Create PDF content
//     final pdfBytes = await _createPdfFromDoc(bytes);

//     // Save PDF
//     final outputPath = await _getUniqueFilePath('$fileName.pdf');
//     final outputFile = File(outputPath);
//     await outputFile.writeAsBytes(pdfBytes);

//     return outputPath;
//   }

//   /// Converts an Excel file to PDF
//   Future<String> _convertExcelToPdf(String excelFilePath) async {
//     final file = File(excelFilePath);
//     final bytes = await file.readAsBytes();
//     final fileName = path.basenameWithoutExtension(excelFilePath);

//     // Create PDF content
//     final pdfBytes = await _createPdfFromExcel(bytes);

//     // Save PDF
//     final outputPath = await _getUniqueFilePath('$fileName.pdf');
//     final outputFile = File(outputPath);
//     await outputFile.writeAsBytes(pdfBytes);

//     return outputPath;
//   }

//   /// Creates a PDF from an image
//   Future<Uint8List> _createPdfFromImage(Uint8List imageBytes) async {
//     // Load the image
//     final codec = await ui.instantiateImageCodec(imageBytes);
//     final frameInfo = await codec.getNextFrame();
//     final image = frameInfo.image;

//     // Create PDF document
//     final pdf = PdfDocument();
//     final page = pdf.addPage(PdfPage(
//       width: image.width.toDouble(),
//       height: image.height.toDouble(),
//     ));

//     // Draw the image on the page
//     page.graphics.drawImage(image, 0, 0);

//     // Return the PDF bytes
//     return pdf.save();
//   }

//   /// Creates a PDF from text
//   Future<Uint8List> _createPdfFromText(String text) async {
//     // Create PDF document
//     final pdf = PdfDocument();
//     final page = pdf.addPage(PdfPage(
//       width: PdfPageFormat.a4.width,
//       height: PdfPageFormat.a4.height,
//     ));

//     // Add text to the page
//     final font = await PdfFont.helvetica(pdf);
//     page.graphics.drawString(
//       text,
//       font,
//       brush: PdfSolidBrush(PdfColor(0, 0, 0)),
//       bounds: Rect.fromLTWH(
//         50,
//         50,
//         PdfPageFormat.a4.width - 100,
//         PdfPageFormat.a4.height - 100,
//       ),
//     );

//     // Return the PDF bytes
//     return pdf.save();
//   }

//   /// Creates a PDF from HTML
//   Future<Uint8List> _createPdfFromHtml(String html) async {
//     // Create PDF document with HTML
//     final pdf = PdfDocument();
//     final page = pdf.addPage(PdfPage(
//       width: PdfPageFormat.a4.width,
//       height: PdfPageFormat.a4.height,
//     ));

//     // Render HTML to PDF
//     await page.graphics.drawHtml(
//         html,
//         Rect.fromLTWH(
//           0,
//           0,
//           PdfPageFormat.a4.width,
//           PdfPageFormat.a4.height,
//         ));

//     // Return the PDF bytes
//     return pdf.save();
//   }

//   /// Creates a PDF from a Word document
//   Future<Uint8List> _createPdfFromDoc(Uint8List docBytes) async {
//     // Extract text from Word document
//     final text = await _extractTextFromDoc(docBytes);

//     // Create PDF from text
//     return await _createPdfFromText(text);
//   }

//   /// Creates a PDF from an Excel file
//   Future<Uint8List> _createPdfFromExcel(Uint8List excelBytes) async {
//     // Extract data from Excel
//     final tables = await _extractTablesFromExcel(excelBytes);

//     // Create PDF document
//     final pdf = PdfDocument();

//     // Add each table to a new page
//     for (final table in tables) {
//       final page = pdf.addPage(PdfPage(
//         width: PdfPageFormat.a4.width,
//         height: PdfPageFormat.a4.height,
//       ));

//       // Draw table on page
//       await _drawTableOnPage(page, table);
//     }

//     // Return the PDF bytes
//     return pdf.save();
//   }

//   /// Extracts text from a Word document
//   Future<String> _extractTextFromDoc(Uint8List docBytes) async {
//     // In a real implementation, you would use a parser to extract text
//     // This is a simplified placeholder that extracts readable text
//     String text = '';

//     // Look for text within the document bytes
//     final String rawContent = String.fromCharCodes(docBytes);

//     // Extract visible text (simplified approach)
//     final RegExp textPattern = RegExp(r'[\w\s.,;:!?()-]+');
//     final Iterable<RegExpMatch> matches = textPattern.allMatches(rawContent);

//     for (final match in matches) {
//       final extractedText = match.group(0)?.trim();
//       if (extractedText != null && extractedText.length > 5) {
//         text += '$extractedText\n';
//       }
//     }

//     return text;
//   }

//   /// Extracts tables from an Excel file
//   Future<List<List<List<String>>>> _extractTablesFromExcel(
//       Uint8List excelBytes) async {
//     // In a real implementation, you would use a parser to extract tables
//     // This is a simplified placeholder

//     // Simulate extracted tables
//     return [
//       [
//         ['Header 1', 'Header 2', 'Header 3'],
//         ['Row 1 Cell 1', 'Row 1 Cell 2', 'Row 1 Cell 3'],
//         ['Row 2 Cell 1', 'Row 2 Cell 2', 'Row 2 Cell 3'],
//       ],
//     ];
//   }

//   /// Draws a table on a PDF page
//   Future<void> _drawTableOnPage(PdfPage page, List<List<String>> table) async {
//     final cellWidth = PdfPageFormat.a4.width / table[0].length;
//     final cellHeight = 40.0;
//     final startX = 50.0;
//     final startY = 50.0;

//     final font = await PdfFont.helvetica(page.document);

//     for (int rowIndex = 0; rowIndex < table.length; rowIndex++) {
//       for (int colIndex = 0; colIndex < table[rowIndex].length; colIndex++) {
//         final x = startX + (colIndex * cellWidth);
//         final y = startY + (rowIndex * cellHeight);

//         // Draw cell border
//         page.graphics.drawRect(
//           Rect.fromLTWH(x, y, cellWidth, cellHeight),
//           stroke: PdfPen(PdfColor(0, 0, 0)),
//         );

//         // Draw cell text
//         page.graphics.drawString(
//           table[rowIndex][colIndex],
//           font,
//           brush: PdfSolidBrush(PdfColor(0, 0, 0)),
//           bounds: Rect.fromLTWH(x + 5, y + 5, cellWidth - 10, cellHeight - 10),
//         );
//       }
//     }
//   }

//   /// Merges multiple PDF pages into one document
//   Future<String> _mergePdfPages(
//       List<Uint8List> pdfPages, String outputName) async {
//     // Create a new PDF document
//     final pdf = PdfDocument();

//     // Import all pages from each PDF
//     for (final pdfBytes in pdfPages) {
//       final importDoc = PdfDocument.fromBytes(pdfBytes);

//       for (int i = 0; i < importDoc.pages.length; i++) {
//         final sourcePage = importDoc.pages[i];
//         final newPage = pdf.addPage();

//         // Copy content from source page to new page
//         final template = sourcePage.createTemplate();
//         newPage.graphics.drawTemplate(
//           template,
//           Offset.zero,
//           Size(sourcePage.width, sourcePage.height),
//         );
//       }
//     }

//     // Save the merged document
//     final outputPath = await _getUniqueFilePath('$outputName.pdf');
//     final outputFile = File(outputPath);
//     await outputFile.writeAsBytes(pdf.save());

//     return outputPath;
//   }

//   /// Gets a unique file path for saving the PDF
//   Future<String> _getUniqueFilePath(String fileName) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
//     final filePath =
//         '${directory.path}/pdf_converter/${fileName.replaceAll(' ', '_')}_$timestamp.pdf';

//     // Create directory if it doesn't exist
//     final folder = Directory(path.dirname(filePath));
//     if (!await folder.exists()) {
//       await folder.create(recursive: true);
//     }

//     return filePath;
//   }
// }

// /// Basic PDF document implementation
// class PdfDocument {
//   final List<PdfPage> _pages = [];

//   List<PdfPage> get pages => _pages;

//   PdfPage addPage([PdfPage? page]) {
//     final newPage = page ??
//         PdfPage(
//           width: PdfPageFormat.a4.width,
//           height: PdfPageFormat.a4.height,
//           document: this,
//         );
//     newPage.document = this;
//     _pages.add(newPage);
//     return newPage;
//   }

//   /// Factory method to create PDF from bytes
//   factory PdfDocument.fromBytes(Uint8List bytes) {
//     // In a real implementation, this would parse the PDF bytes
//     // This is a simplified version that creates a new document
//     return PdfDocument();
//   }

//   /// Saves the document as bytes
//   Future<Uint8List> save() async {
//     // In a real implementation, this would serialize the PDF structure
//     // For our purposes, we'll create a simple representation

//     final buffer = BytesBuilder();

//     // PDF header
//     buffer.add(utf8.encode('%PDF-1.7\n'));

//     // Add some basic content
//     for (final page in _pages) {
//       buffer.add(utf8.encode('% Page\n'));
//       if (page.graphics.commands.isNotEmpty) {
//         buffer.add(utf8.encode('% Graphics commands\n'));
//         buffer.add(utf8.encode(page.graphics.commands.join('\n')));
//       }
//     }

//     // PDF footer
//     buffer.add(utf8.encode('\n%%EOF'));

//     return buffer.toBytes();
//   }
// }

// /// Represents a page in a PDF document
// class PdfPage {
//   PdfDocument? document;
//   final double width;
//   final double height;
//   final PdfGraphics graphics = PdfGraphics();

//   PdfPage({
//     this.document,
//     required this.width,
//     required this.height,
//   });

//   /// Creates a template from this page
//   PdfTemplate createTemplate() {
//     // In a real implementation, this would create a reusable template
//     return PdfTemplate(width, height, graphics.commands);
//   }
// }

// /// Graphics context for drawing on a PDF page
// class PdfGraphics {
//   final List<String> commands = [];

//   /// Draws an image on the page
//   void drawImage(ui.Image image, double x, double y) {
//     commands.add(
//         'DrawImage: x=$x, y=$y, width=${image.width}, height=${image.height}');
//   }

//   /// Draws a string on the page
//   void drawString(
//     String text,
//     PdfFont font, {
//     required PdfBrush brush,
//     required Rect bounds,
//   }) {
//     commands.add(
//         'DrawString: "$text" at ${bounds.left},${bounds.top} with font ${font.size}');
//   }

//   /// Draws a rectangle on the page
//   void drawRect(
//     Rect rect, {
//     PdfPen? stroke,
//     PdfBrush? fill,
//   }) {
//     commands
//         .add('DrawRect: ${rect.left},${rect.top},${rect.width},${rect.height}');
//   }

//   /// Draws HTML content on the page
//   Future<void> drawHtml(String html, Rect bounds) async {
//     commands.add(
//         'DrawHtml: at ${bounds.left},${bounds.top} with size ${bounds.width},${bounds.height}');
//   }

//   /// Draws a template on the page
//   void drawTemplate(PdfTemplate template, Offset offset, Size size) {
//     commands.add(
//         'DrawTemplate: at ${offset.dx},${offset.dy} with size ${size.width},${size.height}');
//     commands.addAll(template.commands);
//   }
// }

// /// Reusable template for PDF content
// class PdfTemplate {
//   final double width;
//   final double height;
//   final List<String> commands;

//   PdfTemplate(this.width, this.height, this.commands);
// }

// /// Standard page sizes for PDF
// class PdfPageFormat {
//   static  a4 = _A4();
// }

// class _A4 {
//   final double width = 595.0;
//   final double height = 842.0;
// }

// /// Font for PDF
// class PdfFont {
//   final double size;
//   final String family;

//   PdfFont(this.family, {this.size = 12.0});

//   static Future<PdfFont> helvetica(PdfDocument? document) async {
//     return PdfFont('Helvetica');
//   }
// }

// /// Brush for filling shapes in PDF
// class PdfBrush {}

// /// Solid color brush
// class PdfSolidBrush extends PdfBrush {
//   final PdfColor color;

//   PdfSolidBrush(this.color);
// }

// /// Pen for stroking shapes in PDF
// class PdfPen {
//   final PdfColor color;

//   PdfPen(this.color);
// }

// /// Color for PDF graphics
// class PdfColor {
//   final int r;
//   final int g;
//   final int b;

//   PdfColor(this.r, this.g, this.b);
// }
