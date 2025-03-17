import 'dart:io';
import 'package:easy_scan/config/api_config.dart';
import 'package:easy_scan/config/helper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class PdfCompressionApiService {
  // API endpoint for compression
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _compressEndpoint = '/compress';

  /// Compress a PDF file using the remote API
  ///
  /// [file] - The PDF file to compress
  /// [compressionLevel] - The level of compression to apply
  /// [onProgress] - Optional callback for progress updates
  ///
  /// Returns the path to the compressed file
  Future<String> compressPdf({
    required File file,
    required CompressionLevel compressionLevel,
    Function(double)? onProgress,
  }) async {
    try {
      // Map compression level to API format
      final String qualityParam =
          _mapCompressionLevelToApiParam(compressionLevel);

      // Create multipart request
      final Uri uri = Uri.parse('$_baseUrl$_compressEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add API key if required by the service
      request.headers['X-API-Key'] = ApiConfig.apiKey;

      // Add the PDF file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(file.path),
        contentType: MediaType('application', 'pdf'),
      );

      request.files.add(multipartFile);

      // Add compression quality parameter
      request.fields['quality'] = qualityParam;

      // Report initial progress
      onProgress?.call(0.1);

      // Send the request
      final streamedResponse = await request.send();

      // Report progress after upload
      onProgress?.call(0.5);

      // Handle the response
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);

        // Check if compression was successful
        if (responseData['success'] == true) {
          // Get the URL of the compressed file
          final String fileUrl = responseData['fileUrl'];

          // Download the compressed file
          final compressedFile =
              await _downloadCompressedFile(fileUrl, file, (progress) {
            // Scale progress from 50% to 90%
            onProgress?.call(0.5 + (progress * 0.4));
          });

          // Report progress for completion
          onProgress?.call(1.0);

          return compressedFile.path;
        } else {
          throw Exception(
              'API compression failed: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        final response = await http.Response.fromStream(streamedResponse);
        try {
          final responseData = json.decode(response.body);
          throw Exception(
              'API compression failed: ${responseData['error'] ?? 'Status code ${streamedResponse.statusCode}'}');
        } catch (e) {
          throw Exception(
              'API compression failed: Status code ${streamedResponse.statusCode}');
        }
      }
    } catch (e) {
      // If the API fails, we can fall back to local compression
      rethrow;
    }
  }

  /// Download the compressed file from the API
  Future<File> _downloadCompressedFile(
    String fileUrl,
    File originalFile,
    Function(double)? onProgress,
  ) async {
    // Create the target file path
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalFilename = path.basenameWithoutExtension(originalFile.path);
    final targetPath = path.join(
      directory.path,
      '${originalFilename}_compressed_$timestamp.pdf',
    );

    // Download the file
    final client = http.Client();
    final request = http.Request('GET', Uri.parse('$_baseUrl$fileUrl'));

    // Add API key if required
    request.headers['X-API-Key'] = ApiConfig.apiKey;

    final streamedResponse = await client.send(request);

    // Check if download is successful
    if (streamedResponse.statusCode == 200) {
      final fileStream = streamedResponse.stream;
      final totalBytes = streamedResponse.contentLength ?? 0;

      // Create file and write downloaded data
      final file = File(targetPath);
      final sink = file.openWrite();

      int downloadedBytes = 0;

      await for (final chunk in fileStream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        // Report download progress
        if (totalBytes > 0 && onProgress != null) {
          onProgress(downloadedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      return file;
    } else {
      client.close();
      throw Exception(
          'Download failed: Status code ${streamedResponse.statusCode}');
    }
  }

  /// Map compression level to API parameter
  String _mapCompressionLevelToApiParam(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 'high'; // API's "high" value preserves more quality
      case CompressionLevel.medium:
        return 'medium';
      case CompressionLevel.high:
        return 'low'; // API's "low" value compresses more aggressively
      case CompressionLevel.maximum:
        return 'low'; // Default to medium
    }
  }
}
