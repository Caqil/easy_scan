import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import '../utils/file_utils.dart';

class ImageService {
  // Image editing functions
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

  // Thumbnail generation

  /// Main thumbnail generation function
  /// This is the main entry point for creating thumbnails from any file type
  Future<File> createThumbnail(File sourceFile, {int size = 300}) async {
    debugPrint('Creating thumbnail for: ${sourceFile.path}');

    // Check if file exists
    if (!await sourceFile.exists()) {
      debugPrint('Source file does not exist: ${sourceFile.path}');
      return await _createFallbackThumbnail(sourceFile.path, size);
    }

    try {
      final String extension = path.extension(sourceFile.path).toLowerCase();

      // Handle different file types
      if (extension == '.pdf') {
        return await _generatePdfThumbnail(sourceFile.path, size);
      } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp']
          .contains(extension)) {
        return await _generateImageThumbnail(sourceFile.path, size);
      } else if (['.doc', '.docx', '.rtf'].contains(extension)) {
        return await _generateDocumentThumbnail(
            extension.replaceAll('.', ''), size);
      } else if (['.xls', '.xlsx', '.csv'].contains(extension)) {
        return await _generateSpreadsheetThumbnail(
            extension.replaceAll('.', ''), size);
      } else if (['.ppt', '.pptx'].contains(extension)) {
        return await _generatePresentationThumbnail(
            extension.replaceAll('.', ''), size);
      } else if (['.txt', '.html', '.md'].contains(extension)) {
        return await _generateTextThumbnail(
            extension.replaceAll('.', ''), size);
      } else {
        return await _generateGenericThumbnail(
            extension.replaceAll('.', ''), size);
      }
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return await _createFallbackThumbnail(sourceFile.path, size);
    }
  }

  /// Create a thumbnail from a PDF file (first page)
  Future<File> _generatePdfThumbnail(String pdfPath, int size) async {
    debugPrint('Creating PDF thumbnail for: $pdfPath');

    try {
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        debugPrint('PDF file not found at path: $pdfPath');
        return _createPlaceholderThumbnail(
          icon: Icons.picture_as_pdf,
          label: 'PDF',
          color: Colors.red,
          size: size,
        );
      }

      // Get the output thumbnail path
      final String thumbnailPath = await FileUtils.getUniqueFilePath(
        documentName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'png',
        inTempDirectory: false,
      );

      try {
        // Open the PDF document
        final document = await pdf_render.PdfDocument.openFile(pdfPath);

        // Get the first page
        final page = await document.getPage(1);

        // Define the rendering size (increase for better quality)
        final renderSize = size * 2;

        // Render the page to an image
        final pageImage = await page.render(
          width: renderSize,
          height: (renderSize * page.height / page.width).toInt(),
        );

        // Get the image object first, then convert to byte data
        final ui.Image image = await pageImage.createImageDetached();
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        // Check if we got data
        if (byteData == null) {
          throw Exception('Failed to get image data from rendered PDF page');
        }

        // Write the PNG to the file
        final File file = File(thumbnailPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Close the PDF document
        document.dispose();

        return file;
      } catch (e) {
        debugPrint('Error rendering PDF page: $e');
        // Fall back to placeholder instead of failing
        return _createPlaceholderThumbnail(
          icon: Icons.picture_as_pdf,
          label: 'PDF',
          color: Colors.red,
          size: size,
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF thumbnail: $e');
      return _createFallbackThumbnail(pdfPath, size);
    }
  }

  /// Create a thumbnail from an image file
  Future<File> _generateImageThumbnail(String imagePath, int size) async {
    try {
      // Read the image
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return _createPlaceholderThumbnail(
          icon: Icons.image,
          label: 'IMAGE',
          color: Colors.blue,
          size: size,
        );
      }

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
      debugPrint('Error generating image thumbnail: $e');
      return _createPlaceholderThumbnail(
        icon: Icons.image,
        label: 'IMAGE',
        color: Colors.blue,
        size: size,
      );
    }
  }

  /// Create a thumbnail for document formats (DOCX, DOC, RTF)
  Future<File> _generateDocumentThumbnail(String extension, int size) async {
    // For document formats, create a styled placeholder thumbnail
    return _createPlaceholderThumbnail(
      icon: Icons.description_outlined,
      label: extension.toUpperCase(),
      color: Colors.blue,
      size: size,
    );
  }

  /// Create a thumbnail for spreadsheet formats (XLSX, XLS, CSV)
  Future<File> _generateSpreadsheetThumbnail(String extension, int size) async {
    // For spreadsheet formats, create a styled placeholder thumbnail
    return _createPlaceholderThumbnail(
      icon: Icons.table_chart_outlined,
      label: extension.toUpperCase(),
      color: Colors.green,
      size: size,
    );
  }

  /// Create a thumbnail for presentation formats (PPTX, PPT)
  Future<File> _generatePresentationThumbnail(
      String extension, int size) async {
    // For presentation formats, create a styled placeholder thumbnail
    return _createPlaceholderThumbnail(
      icon: Icons.slideshow_outlined,
      label: extension.toUpperCase(),
      color: Colors.orange,
      size: size,
    );
  }

  /// Create a thumbnail for text formats (TXT, HTML, MD)
  Future<File> _generateTextThumbnail(String extension, int size) async {
    // For text formats, create a styled placeholder thumbnail
    return _createPlaceholderThumbnail(
      icon: Icons.text_snippet_outlined,
      label: extension.toUpperCase(),
      color: Colors.grey,
      size: size,
    );
  }

  /// Create a thumbnail for other/generic formats
  Future<File> _generateGenericThumbnail(String extension, int size) async {
    // For unknown formats, create a generic placeholder thumbnail
    return _createPlaceholderThumbnail(
      icon: Icons.insert_drive_file_outlined,
      label: extension.toUpperCase(),
      color: Colors.purple,
      size: size,
    );
  }

  /// Create a placeholder thumbnail with icon, label and color
  Future<File> _createPlaceholderThumbnail({
    required IconData icon,
    required String label,
    required Color color,
    required int size,
  }) async {
    try {
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

      // Draw icon
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            color: color,
            fontSize: thumbnailSize * 0.4,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
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

      // Draw label
      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
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
      debugPrint('Error creating placeholder thumbnail: $e');
      return _createFallbackThumbnail('', size);
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
        extension: 'png', // Changed from jpg to png for better compatibility
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

      // Create an absolute last-resort thumbnail
      try {
        // Create a very simple thumbnail with just a color
        final String outputPath = await FileUtils.getUniqueFilePath(
          documentName:
              'emergency_thumbnail_${DateTime.now().millisecondsSinceEpoch}',
          extension: 'png',
          inTempDirectory: false,
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()..color = Colors.grey;

        canvas.drawRect(
            Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paint);

        final picture = recorder.endRecording();
        final image = await picture.toImage(size, size);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          throw Exception('Failed to create emergency thumbnail');
        }

        final File file = File(outputPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        return file;
      } catch (lastError) {
        throw Exception(
            'All thumbnail generation methods failed: $e, $lastError');
      }
    }
  }
}
