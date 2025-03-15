// // import 'dart:io';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pdf_render/pdf_render.dart' as pdf_render;
// import 'package:image/image.dart' as img;
// import 'package:path/path.dart' as path;
// import '../utils/file_utils.dart';

// class ThumbnailService {
//   /// Generate a thumbnail based on file type
//   Future<File?> generateThumbnail(String filePath, {int size = 300}) async {
//     final extension =
//         path.extension(filePath).toLowerCase().replaceAll('.', '');

//     try {
//       switch (extension) {
//         case 'pdf':
//           return await _generatePdfThumbnail(filePath, size);
//         case 'jpg':
//         case 'jpeg':
//         case 'png':
//           return await _generateImageThumbnail(filePath, size);
//         case 'docx':
//         case 'doc':
//         case 'rtf':
//           return await _generateDocumentThumbnail(extension, size);
//         case 'xlsx':
//         case 'xls':
//         case 'csv':
//           return await _generateSpreadsheetThumbnail(extension, size);
//         case 'pptx':
//         case 'ppt':
//           return await _generatePresentationThumbnail(extension, size);
//         case 'txt':
//         case 'html':
//         case 'md':
//           return await _generateTextThumbnail(extension, size);
//         default:
//           return await _generateGenericThumbnail(extension, size);
//       }
//     } catch (e) {
//       debugPrint('Error generating thumbnail: $e');
//       // Fallback to generic thumbnail
//       return await _generateGenericThumbnail(extension, size);
//     }
//   }

//   /// Create a thumbnail from a PDF file (first page)
//   Future<File?> _generatePdfThumbnail(String pdfPath, int size) async {
//     try {
//       final File pdfFile = File(pdfPath);
//       if (!await pdfFile.exists()) {
//         debugPrint('PDF file not found at path: $pdfPath');
//         return _createPlaceholderThumbnail(
//           icon: Icons.picture_as_pdf,
//           label: 'PDF',
//           color: Colors.red,
//           size: size,
//         );
//       }

//       // Get the output thumbnail path first
//       final String thumbnailPath = await FileUtils.getUniqueFilePath(
//         documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
//         extension: 'png',
//         inTempDirectory: false,
//       );

//       try {
//         // Open the PDF document
//         final document = await pdf_render.PdfDocument.openFile(pdfPath);

//         // Get the first page
//         final page = await document.getPage(1);

//         // Define the rendering size (increase for better quality)
//         final renderSize = size * 2;

//         // Render the page to an image
//         final pageImage = await page.render(
//           width: renderSize,
//           height: (renderSize * page.height / page.width).toInt(),
//         );

//         // Get the PNG data from the rendered page
//         final pngBytes = await pageImage.toPng();

//         // Write the PNG to the file
//         final File file = File(thumbnailPath);
//         await file.writeAsBytes(pngBytes);

//         // Close the PDF document
//         document.dispose();

//         return file;
//       } catch (e) {
//         debugPrint('Error rendering PDF page: $e');
//         // Fall back to placeholder instead of failing
//         return _createPlaceholderThumbnail(
//           icon: Icons.picture_as_pdf,
//           label: 'PDF',
//           color: Colors.red,
//           size: size,
//         );
//       }
//     } catch (e) {
//       debugPrint('Error generating PDF thumbnail: $e');
//       return null;
//     }
//   }

//   /// Create a thumbnail from an image file
//   Future<File?> _generateImageThumbnail(String imagePath, int size) async {
//     try {
//       // Read the image
//       final File imageFile = File(imagePath);
//       if (!await imageFile.exists()) {
//         return _createPlaceholderThumbnail(
//           icon: Icons.image,
//           label: 'IMAGE',
//           color: Colors.blue,
//           size: size,
//         );
//       }

//       final Uint8List bytes = await imageFile.readAsBytes();
//       var image = img.decodeImage(bytes);

//       if (image == null) {
//         throw Exception('Failed to decode image');
//       }

//       // Resize to thumbnail size
//       image = img.copyResize(image, width: size);

//       // Get output file path
//       final String outputPath = await FileUtils.getUniqueFilePath(
//         documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
//         extension: 'jpg',
//         inTempDirectory: false,
//       );

//       // Save thumbnail
//       final File outputFile = File(outputPath);
//       await outputFile.writeAsBytes(img.encodeJpg(image, quality: 85));

//       return outputFile;
//     } catch (e) {
//       debugPrint('Error generating image thumbnail: $e');
//       return _createPlaceholderThumbnail(
//         icon: Icons.image,
//         label: 'IMAGE',
//         color: Colors.blue,
//         size: size,
//       );
//     }
//   }

//   /// Create a thumbnail for document formats (DOCX, DOC, RTF)
//   Future<File?> _generateDocumentThumbnail(String extension, int size) async {
//     // For document formats, create a styled placeholder thumbnail
//     return _createPlaceholderThumbnail(
//       icon: Icons.description_outlined,
//       label: extension.toUpperCase(),
//       color: Colors.blue,
//       size: size,
//     );
//   }

//   /// Create a thumbnail for spreadsheet formats (XLSX, XLS, CSV)
//   Future<File?> _generateSpreadsheetThumbnail(
//       String extension, int size) async {
//     // For spreadsheet formats, create a styled placeholder thumbnail
//     return _createPlaceholderThumbnail(
//       icon: Icons.table_chart_outlined,
//       label: extension.toUpperCase(),
//       color: Colors.green,
//       size: size,
//     );
//   }

//   /// Create a thumbnail for presentation formats (PPTX, PPT)
//   Future<File?> _generatePresentationThumbnail(
//       String extension, int size) async {
//     // For presentation formats, create a styled placeholder thumbnail
//     return _createPlaceholderThumbnail(
//       icon: Icons.slideshow_outlined,
//       label: extension.toUpperCase(),
//       color: Colors.orange,
//       size: size,
//     );
//   }

//   /// Create a thumbnail for text formats (TXT, HTML, MD)
//   Future<File?> _generateTextThumbnail(String extension, int size) async {
//     // For text formats, create a styled placeholder thumbnail
//     return _createPlaceholderThumbnail(
//       icon: Icons.text_snippet_outlined,
//       label: extension.toUpperCase(),
//       color: Colors.grey,
//       size: size,
//     );
//   }

//   /// Create a thumbnail for other/generic formats
//   Future<File?> _generateGenericThumbnail(String extension, int size) async {
//     // For unknown formats, create a generic placeholder thumbnail
//     return _createPlaceholderThumbnail(
//       icon: Icons.insert_drive_file_outlined,
//       label: extension.toUpperCase(),
//       color: Colors.purple,
//       size: size,
//     );
//   }

//   /// Create a placeholder thumbnail with icon, label and color
//   Future<File?> _createPlaceholderThumbnail({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required int size,
//   }) async {
//     try {
//       // Create a PictureRecorder to record drawing operations
//       final ui.PictureRecorder recorder = ui.PictureRecorder();
//       final Canvas canvas = Canvas(recorder);
//       final double thumbnailSize = size.toDouble();

//       // Draw background
//       final Paint bgPaint = Paint()..color = color.withOpacity(0.1);
//       canvas.drawRect(
//         Rect.fromLTWH(0, 0, thumbnailSize, thumbnailSize),
//         bgPaint,
//       );

//       // Draw border
//       final Paint borderPaint = Paint()
//         ..color = color.withOpacity(0.6)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2.0;
//       canvas.drawRect(
//         Rect.fromLTWH(2, 2, thumbnailSize - 4, thumbnailSize - 4),
//         borderPaint,
//       );

//       // Draw icon
//       final TextPainter iconPainter = TextPainter(
//         text: TextSpan(
//           text: String.fromCharCode(icon.codePoint),
//           style: TextStyle(
//             color: color,
//             fontSize: thumbnailSize * 0.4,
//             fontFamily: icon.fontFamily,
//             package: icon.fontPackage,
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       iconPainter.layout();
//       iconPainter.paint(
//         canvas,
//         Offset(
//           (thumbnailSize - iconPainter.width) / 2,
//           (thumbnailSize - iconPainter.height) / 2 - 10,
//         ),
//       );

//       // Draw label
//       final TextPainter labelPainter = TextPainter(
//         text: TextSpan(
//           text: label,
//           style: TextStyle(
//             color: color,
//             fontSize: thumbnailSize * 0.15,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//         textAlign: TextAlign.center,
//       );
//       labelPainter.layout(maxWidth: thumbnailSize);
//       labelPainter.paint(
//         canvas,
//         Offset(
//           (thumbnailSize - labelPainter.width) / 2,
//           thumbnailSize * 0.7,
//         ),
//       );

//       // Convert to image
//       final ui.Picture picture = recorder.endRecording();
//       final ui.Image image = await picture.toImage(
//         size.toInt(),
//         size.toInt(),
//       );
//       final ByteData? byteData =
//           await image.toByteData(format: ui.ImageByteFormat.png);

//       if (byteData == null) {
//         throw Exception('Failed to convert canvas to image');
//       }

//       // Save to file
//       final Uint8List pngBytes = byteData.buffer.asUint8List();
//       final String filePath = await FileUtils.getUniqueFilePath(
//         documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
//         extension: 'png',
//         inTempDirectory: false,
//       );

//       final File file = File(filePath);
//       await file.writeAsBytes(pngBytes);

//       return file;
//     } catch (e) {
//       debugPrint('Error creating placeholder thumbnail: $e');
//       return null;
//     }
//   }
// }
