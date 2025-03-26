import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:scanpro/main.dart';
import 'package:scanpro/config/api_config.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/utils/file_utils.dart';

/// Service for compressing PDF files using the universal compression API
class PdfCompressionApiService {
  // Universal compression endpoint
  static const String _compressionEndpoint = '/api/compress/universal';

  /// Compress a PDF file
  Future<String> compressPdf({
    required File file,
    required CompressionLevel compressionLevel,
    Function(double)? onProgress,
  }) async {
    try {
      // Report initial progress
      onProgress?.call(0.1);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      // Convert compression level enum to string for API
      final String qualityLevel = _compressionLevelToString(compressionLevel);

      logger.info('Starting compression with level: $qualityLevel');
      logger.info('File path: ${file.path}');

      // Create multipart request
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}$_compressionEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add API key if required
      if (ApiConfig.apiKey.isNotEmpty) {
        request.headers['X-API-Key'] = ApiConfig.apiKey;
      }

      // Add the file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(file.path),
      );

      request.files.add(multipartFile);

      // Add the quality parameter
      request.fields['quality'] = qualityLevel;

      logger.info('Uploading file to compression API: $uri');

      // Report progress
      onProgress?.call(0.3);

      // Send the request
      final streamedResponse = await request.send();

      // Report progress after upload
      onProgress?.call(0.6);

      // Handle the response
      if (streamedResponse.statusCode != 200) {
        final response = await http.Response.fromStream(streamedResponse);
        logger.error(
            'Compression failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'API compression failed: HTTP ${streamedResponse.statusCode}');
      }

      // Create a meaningful file name for the compressed file
      final originalFileName = path.basenameWithoutExtension(file.path);
      final extension = path.extension(file.path);
      final compressedFileName =
          '${originalFileName}_compressed_$qualityLevel$extension';

      // Get a unique path in the documents directory
      final String finalPath = await FileUtils.getUniqueFilePath(
        documentName: '${originalFileName}_compressed_$qualityLevel',
        extension: extension.replaceAll('.', ''),
      );

      logger.info('Saving compressed file to: $finalPath');

      // Save the compressed file
      final response = await http.Response.fromStream(streamedResponse);
      final outputFile = File(finalPath);
      await outputFile.writeAsBytes(response.bodyBytes);

      onProgress?.call(0.9);

      // Verify the file was created and has content
      if (!await outputFile.exists()) {
        throw Exception('Failed to create compressed file');
      }

      final fileSize = await outputFile.length();
      if (fileSize == 0) {
        throw Exception('Compressed file is empty');
      }

      // Report completion
      onProgress?.call(1.0);
      logger.info(
          'Compression completed successfully: ${outputFile.path}, size: $fileSize bytes');

      return finalPath;
    } catch (e) {
      logger.error('Error compressing file: $e');
      rethrow;
    }
  }

  /// Convert CompressionLevel enum to string for the API
  String _compressionLevelToString(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 'low';
      case CompressionLevel.medium:
        return 'medium';
      case CompressionLevel.high:
        return 'high';
      default:
        return 'medium'; // Default to medium
    }
  }
}

/// Provider for the PDF compression API service
final pdfCompressionApiServiceProvider =
    Provider<PdfCompressionApiService>((ref) {
  return PdfCompressionApiService();
});
