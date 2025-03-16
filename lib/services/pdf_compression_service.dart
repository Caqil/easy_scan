// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:path/path.dart' as path;

// /// Enum defining compression levels
// enum CompressionLevel {
//   low,      // Minimal compression, high quality
//   medium,   // Balanced compression
//   high,     // High compression, reduced quality
//   maximum   // Maximum compression, lowest quality
// }

// /// Service for compressing PDF files
// class PdfCompressionService {
//   /// Compress a PDF file
//   /// Returns the path to the compressed PDF file
//   Future<String> compressPdf(
//     String pdfPath, {
//     CompressionLevel level = CompressionLevel.medium,
//     String? password,
//   }) async {
//     try {
//       // Check if the file exists
//       File inputFile = File(pdfPath);
//       if (!await inputFile.exists()) {
//         throw Exception('Input PDF file does not exist');
//       }

//       // Load the PDF document
//       PdfDocument document;
//       try {
//         // Handle password-protected documents
//         if (password != null && password.isNotEmpty) {
//           document = PdfDocument(
//             inputBytes: await inputFile.readAsBytes(),
//             password: password,
//           );
//         } else {
//           document = PdfDocument(
//             inputBytes: await inputFile.readAsBytes(),
//           );
//         }
//       } catch (e) {
//         throw Exception('Failed to open PDF: $e');
//       }

//       // Apply compression settings based on the requested level
//       try {
//         // Set compression level
//         document.compressionLevel = _getPdfCompressionLevel(level);

//         // Get optimization settings based on level
//         final settings = _getOptimizationSettings(level);

//         // Apply image compression
//         _compressImages(document, settings['imageQuality'] as int);

//         // Apply font optimization
//         if (settings['optimizeFonts'] as bool) {
//           _optimizeFonts(document);
//         }

//         // Remove metadata if specified
//         if (settings['removeMetadata'] as bool) {
//           _removeMetadata(document);
//         }
//       } catch (e) {
//         document.dispose();
//         throw Exception('Error applying compression settings: $e');
//       }

//       // Create output file path
//       final String outputPath = await _createOutputPath(pdfPath);

//       // Save the compressed document
//       try {
//         // Get document bytes with compression applied
//         final List<int> bytes = await document.save();
        
//         // Write to output file
//         await File(outputPath).writeAsBytes(bytes);
        
//         // Dispose the document
//         document.dispose();
        
//         return outputPath;
//       } catch (e) {
//         document.dispose();
//         throw Exception('Error saving compressed PDF: $e');
//       }
//     } catch (e) {
//       debugPrint('PDF compression error: $e');
//       rethrow;
//     }
//   }

//   /// Helper method to get Syncfusion PDF compression level
//   PdfCompressionLevel _getPdfCompressionLevel(CompressionLevel level) {
//     switch (level) {
//       case CompressionLevel.low:
//         return PdfCompressionLevel.normal;
//       case CompressionLevel.medium:
//         return PdfCompressionLevel.best;
//       case CompressionLevel.high:
//         return PdfCompressionLevel.best;
//       case CompressionLevel.maximum:
//         return PdfCompressionLevel.best;
//     }
//   }

//   /// Get optimization settings based on compression level
//   Map<String, dynamic> _getOptimizationSettings(CompressionLevel level) {
//     switch (level) {
//       case CompressionLevel.low:
//         return {
//           'imageQuality': 90,
//           'optimizeFonts': false,
//           'removeMetadata': false,
//         };
//       case CompressionLevel.medium:
//         return {
//           'imageQuality': 75,
//           'optimizeFonts': true,
//           'removeMetadata': false,
//         };
//       case CompressionLevel.high:
//         return {
//           'imageQuality': 50,
//           'optimizeFonts': true,
//           'removeMetadata': true,
//         };
//       case CompressionLevel.maximum:
//         return {
//           'imageQuality': 20,
//           'optimizeFonts': true,
//           'removeMetadata': true,
//         };
//     }
//   }

//   /// Compress images in the PDF
//   void _compressImages(PdfDocument document, int quality) {
//     // This is a simplified implementation
//     // In a real-world scenario, you'd iterate through all images in the PDF
//     // and recompress them with the specified quality
    
//     // For the Syncfusion library, we rely on its built-in compression
//     // when saving the document with the compressionLevel setting
//   }

//   /// Optimize fonts in the PDF
//   void _optimizeFonts(PdfDocument document) {
//     // In a full implementation, this would optimize font embedding
//     // For simplicity, we'll rely on Syncfusion's built-in optimization
//   }

//   /// Remove metadata from the PDF
//   void _removeMetadata(PdfDocument document) {
//     // Clear document metadata
//     document.documentInformation.title = '';
//     document.documentInformation.author = '';
//     document.documentInformation.subject = '';
//     document.documentInformation.keywords = '';
//     document.documentInformation.creator = '';
//     document.documentInformation.producer = '';
//   }

//   /// Create an output path for the compressed PDF
//   Future<String> _createOutputPath(String inputPath) async {
//     final Directory tempDir = await getTemporaryDirectory();
//     final String fileName = path.basenameWithoutExtension(inputPath);
//     final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
//     return '${tempDir.path}/${fileName}_compressed_$timestamp.pdf';
//   }
// }

// /// Provider for PDF compression service
// final pdfCompressionProvider = Provider<PdfCompressionService>((ref) {
//   return PdfCompressionService();
// });