import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/file_utils.dart';

class ImageService {
  /// Compress image to reduce file size
  Future<File> compressImage(File imageFile, {int quality = 80}) async {
    final String targetPath = await FileUtils.getUniqueFilePath(
      documentName: 'compressed_${DateTime.now().millisecondsSinceEpoch}',
      extension: 'jpg',
      inTempDirectory: true,
    );

    // Compress the image
    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: quality,
      minHeight: 1080,
      minWidth: 1080,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

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

  /// Create thumbnail from image
  Future<File> createThumbnail(File imageFile, {int size = 300}) async {
    // Read the image
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
  }
}
