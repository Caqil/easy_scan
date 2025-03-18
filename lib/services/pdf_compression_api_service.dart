import 'dart:io';
import 'package:easy_scan/config/api_config.dart';
import 'package:easy_scan/config/helper.dart';
import 'package:easy_scan/main.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class PdfCompressionApiService {
  static const String _compressEndpoint = '/compress';

  /// Compress a PDF file using the remote API
  Future<String> compressPdf({
    required File file,
    required CompressionLevel compressionLevel,
    Function(double)? onProgress,
  }) async {
    try {
      // Map compression level to API format
      final String qualityParam =
          _mapCompressionLevelToApiParam(compressionLevel);

      // Create multipart request for compression
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}$_compressEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add API key if required
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
      request.fields['quality'] = qualityParam;

      // Report initial progress
      onProgress?.call(0.1);
      logger.info('Uploading to: $uri with quality: $qualityParam');

      // Send the compression request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Report progress after upload
      onProgress?.call(0.5);

      // Handle the response
      if (streamedResponse.statusCode != 200) {
        logger.error(
            'Compression failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'API compression failed: HTTP ${streamedResponse.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      logger.info('Compression API Response: $responseData');

      if (responseData['success'] != true) {
        throw Exception(
            'API compression failed: ${responseData['error'] ?? 'Unknown error'}');
      }

      // Get the filename from the response
      final String? filename = responseData['filename'] as String?;
      if (filename == null || filename.isEmpty) {
        throw Exception('No filename returned in response');
      }
      String downloadUrl =
          "${ApiConfig.baseUrl}/file?folder=compressions&filename=$filename";
      final compressedFile =
          await _downloadCompressedFile(downloadUrl, file, (progress) {
        onProgress?.call(0.5 + (progress * 0.4));
      });

      onProgress?.call(1.0);
      logger.info('Compressed file downloaded to: ${compressedFile.path}');
      return compressedFile.path;
    } catch (e) {
      logger.error('Compression error: $e');
      rethrow;
    }
  }

  Future<File> downloadCompressedFile(
    String baseUrl,
    Map<String, dynamic> compressionResponse,
    File originalFile,
  ) async {
    // Construct the full download URL using the fileUrl from the response
    final fileName = compressionResponse[
        'filename']; // e.g., "/compressions/269761f6-c160-4a2b-8a99-2ec37a441f58-compressed.pdf"
    String downloadUrl =
        "${ApiConfig.baseUrl}/file?folder=compressions&filename=$fileName";

    return _downloadCompressedFile(
      downloadUrl,
      originalFile,
      (progress) {
        logger.info('Download progress: ${progress * 100}%');
      },
    );
  }

  Future<File> _downloadCompressedFile(
    String downloadUrl,
    File originalFile,
    Function(double)? onProgress,
  ) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalFilename = path.basenameWithoutExtension(originalFile.path);
    final targetPath = path.join(
      directory.path,
      '${originalFilename}_compressed_$timestamp.pdf',
    );

    logger.info('Downloading from: $downloadUrl');

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['X-API-Key'] =
          ApiConfig.apiKey; // If your API requires an API key
      // Force the response to be treated as a binary download
      request.headers['Accept'] = 'application/pdf';

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorResponse = await http.Response.fromStream(streamedResponse);
        logger.error(
            'Download failed: ${streamedResponse.statusCode} - ${errorResponse.body}');
        throw Exception(
            'Failed to download file: HTTP ${streamedResponse.statusCode}');
      }

      final totalBytes = streamedResponse.contentLength ?? 0;
      final file = File(targetPath);
      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes > 0 && onProgress != null) {
          onProgress(downloadedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      if (await file.length() == 0) {
        throw Exception('Downloaded file is empty');
      }

      logger.info('File downloaded to: $targetPath');
      return file;
    } catch (e) {
      logger.error('Download error: $e');
      throw Exception('Failed to download compressed file: $e');
    }
  }

  /// Map compression level to API parameter
  String _mapCompressionLevelToApiParam(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 'high';
      case CompressionLevel.medium:
        return 'medium';
      case CompressionLevel.high:
      case CompressionLevel.maximum:
        return 'low';
    }
  }
}
