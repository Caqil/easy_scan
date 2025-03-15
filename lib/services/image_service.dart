import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;

class ImageService {
  Future<File> rotateImage(File imageFile, bool counterClockwise) async {
    // Read the image
    final Uint8List bytes = await imageFile.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Rotate image (counterclockwise = -90 degrees, clockwise = 90 degrees)
    image = counterClockwise
        ? img.copyRotate(image, angle: -90)
        : img.copyRotate(image, angle: 90);

    // Get output file path
    final String outputPath = await FileUtils.getUniqueFilePath(
      documentName: 'rotated_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'jpg',
      inTempDirectory: true,
    );

    // Save rotated image
    final File outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(image));

    return outputFile;
  }

  /// Apply perspective correction based on detected corners
  /// This is a simplified implementation, real apps would use OpenCV or ML
  Future<File> perspectiveCorrection(
      File imageFile, List<List<double>> corners) async {
    // This is a placeholder for actual perspective correction
    // In a real app, you would use OpenCV or another computer vision library

    // For now, just return a copy of the original image
    final String outputPath = await FileUtils.getUniqueFilePath(
      documentName: 'perspective_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'jpg',
      inTempDirectory: true,
    );

    // Copy the file
    final File outputFile = File(outputPath);
    await outputFile.writeAsBytes(await imageFile.readAsBytes());

    return outputFile;
  }

  Future<File> createThumbnail(File sourceFile, {int size = 300}) async {
    debugPrint('Creating thumbnail for: ${sourceFile.path}');

    // Check if file exists
    if (!await sourceFile.exists()) {
      debugPrint('Source file does not exist: ${sourceFile.path}');
      return await _createFallbackThumbnail(sourceFile.path, size);
    }

    try {
      // Create output path first
      final String outputPath = await FileUtils.getUniqueFilePath(
        documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'jpg',
        inTempDirectory: false,
      );

      // Ensure directory exists
      final outputDir = path.dirname(outputPath);
      final directory = Directory(outputDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Read the image
      try {
        final Uint8List bytes = await sourceFile.readAsBytes();
        var image = img.decodeImage(bytes);

        if (image == null) {
          debugPrint('Failed to decode image, creating fallback thumbnail');
          return await _createFallbackThumbnail(sourceFile.path, size);
        }

        // Resize to thumbnail size
        image = img.copyResize(image, width: size);

        // Save thumbnail
        final File outputFile = File(outputPath);
        await outputFile.writeAsBytes(img.encodeJpg(image, quality: 85));

        // Verify thumbnail was created
        if (!await outputFile.exists()) {
          debugPrint('Failed to save thumbnail to $outputPath');
          return await _createFallbackThumbnail(sourceFile.path, size);
        }

        debugPrint('Thumbnail created successfully at: $outputPath');
        return outputFile;
      } catch (e) {
        debugPrint('Error processing image: $e');
        return await _createFallbackThumbnail(sourceFile.path, size);
      }
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return await _createFallbackThumbnail(sourceFile.path, size);
    }
  }

  /// Create a generic thumbnail when normal thumbnail generation fails
  Future<File> _createFallbackThumbnail(String sourceFilePath, int size) async {
    debugPrint('Creating fallback thumbnail for: $sourceFilePath');
    try {
      final String extension = path.extension(sourceFilePath).toLowerCase();
      final String fileName = path.basenameWithoutExtension(sourceFilePath);

      // Create a new thumbnail path
      final String outputPath = await FileUtils.getUniqueFilePath(
        documentName:
            'thumbnail_fallback_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'jpg',
        inTempDirectory: false,
      );

      // Ensure directory exists
      final outputDir = path.dirname(outputPath);
      final directory = Directory(outputDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create a custom thumbnail based on file type
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.fill;

      // Draw background
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paint);

      // Draw icon based on file type
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: extension == '.pdf' ? '📄' : '🖼️',
          style: TextStyle(fontSize: size * 0.5),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              (size - textPainter.width) / 2, (size - textPainter.height) / 2));

      // Draw filename
      textPainter = TextPainter(
        text: TextSpan(
          text: fileName.length > 10
              ? '${fileName.substring(0, 10)}...'
              : fileName,
          style: TextStyle(fontSize: size * 0.1, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: size.toDouble());
      textPainter.paint(
          canvas, Offset((size - textPainter.width) / 2, size * 0.75));

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate fallback thumbnail');
      }

      // Save to file
      final File file = File(outputPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('Fallback thumbnail created at: $outputPath');
      return file;
    } catch (e) {
      debugPrint('Failed to create fallback thumbnail: $e');
      throw Exception('Failed to create thumbnail: $e');
    }
  }
}
