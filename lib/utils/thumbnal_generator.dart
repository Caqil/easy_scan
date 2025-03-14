import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../utils/file_utils.dart';
import 'package:image/image.dart' as img;

class ThumbnailGenerator {
  /// Generate a thumbnail file for a document
  static Future<File?> generateThumbnail(String filePath,
      {int size = 300}) async {
    final String extension =
        path.extension(filePath).toLowerCase().replaceAll('.', '');

    try {
      // For image files, we can create actual thumbnails
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        return await _generateImageThumbnail(filePath, size);
      }

      // For other files, create a styled placeholder
      return await _createPlaceholderThumbnail(
        extension: extension.toUpperCase(),
        size: size,
      );
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Create a thumbnail from an image file
  static Future<File?> _generateImageThumbnail(
      String imagePath, int size) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to thumbnail size
      image = img.copyResize(image, width: size);

      // Get output file path
      final String outputPath = await FileUtils.getUniqueFilePath(
        documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'jpg',
        inTempDirectory: false,
      );

      // Save thumbnail
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 85));

      return outputFile;
    } catch (e) {
      print('Error generating image thumbnail: $e');
      return null;
    }
  }

  /// Create a placeholder thumbnail with extension info
  static Future<File?> _createPlaceholderThumbnail({
    required String extension,
    required int size,
  }) async {
    try {
      // Determine color based on file type
      final Color color = _getColorForExtension(extension);

      // Create a PictureRecorder to record drawing operations
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final double thumbnailSize = size.toDouble();

      // Draw background
      final Paint bgPaint = Paint()..color = color.withOpacity(0.1);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, thumbnailSize, thumbnailSize),
        bgPaint,
      );

      // Draw border
      final Paint borderPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
        Rect.fromLTWH(2, 2, thumbnailSize - 4, thumbnailSize - 4),
        borderPaint,
      );

      // Draw file icon
      final IconData icon = _getIconForExtension(extension);
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            color: color,
            fontSize: thumbnailSize * 0.4,
            fontFamily: icon.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          (thumbnailSize - iconPainter.width) / 2,
          (thumbnailSize - iconPainter.height) / 2 - 10,
        ),
      );

      // Draw extension label
      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: extension,
          style: TextStyle(
            color: color,
            fontSize: thumbnailSize * 0.15,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      labelPainter.layout(maxWidth: thumbnailSize);
      labelPainter.paint(
        canvas,
        Offset(
          (thumbnailSize - labelPainter.width) / 2,
          thumbnailSize * 0.7,
        ),
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(
        size.toInt(),
        size.toInt(),
      );
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert canvas to image');
      }

      // Save to file
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final String filePath = await FileUtils.getUniqueFilePath(
        documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'png',
        inTempDirectory: false,
      );

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      print('Error creating placeholder thumbnail: $e');
      return null;
    }
  }

  /// Get appropriate icon for file extension
  static IconData _getIconForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
      case 'rtf':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'txt':
      case 'md':
        return Icons.text_snippet_outlined;
      case 'html':
      case 'htm':
        return Icons.code;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Get appropriate color for file extension
  static Color _getColorForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
      case 'rtf':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
      case 'md':
        return Colors.grey;
      case 'html':
      case 'htm':
        return Colors.cyan;
      default:
        return Colors.purple;
    }
  }
}
