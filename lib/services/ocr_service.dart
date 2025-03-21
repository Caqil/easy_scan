import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:scanpro/main.dart';
import 'package:scanpro/config/api_config.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/subscription_service.dart';

class OcrResult {
  final String text;
  final bool success;
  final Map<String, dynamic>? metadata;
  final String? error;

  OcrResult({
    required this.text,
    required this.success,
    this.metadata,
    this.error,
  });

  factory OcrResult.success(String text, {Map<String, dynamic>? metadata}) {
    return OcrResult(
      text: text,
      success: true,
      metadata: metadata,
    );
  }

  factory OcrResult.error(String error) {
    return OcrResult(
      text: '',
      success: false,
      error: error,
    );
  }
}

/// Service for extracting text from PDFs or images using OCR
class OcrService {
  static const String _ocrEndpoint = '/ocr/extract';

  /// Extract text from a PDF or image file using OCR
  Future<OcrResult> extractAutoSizeText({
    required File file,
    String language = 'eng',
    String pageRange = 'all',
    bool enhanceScanned = true,
    bool preserveLayout = true,
    Function(double)? onProgress,
  }) async {
    try {
      // Report initial progress
      onProgress?.call(0.1);

      // Create multipart request for OCR
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}$_ocrEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add API key if required
      request.headers['X-API-Key'] = ApiConfig.apiKey;

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
      request.fields['language'] = language;
      request.fields['pageRange'] = pageRange;
      request.fields['enhanceScanned'] = enhanceScanned.toString();
      request.fields['preserveLayout'] = preserveLayout.toString();

      logger.info('Uploading file for OCR to: $uri');

      // Send the OCR request
      onProgress?.call(0.3);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Report progress after upload
      onProgress?.call(0.7);

      // Handle the response
      if (streamedResponse.statusCode != 200) {
        logger.error('OCR failed: ${response.statusCode} - ${response.body}');
        return OcrResult.error(
            'API OCR failed: HTTP ${streamedResponse.statusCode} - ${response.body}');
      }

      // Parse the response
      final responseData = jsonDecode(response.body);

      if (responseData['success'] != true) {
        return OcrResult.error(responseData['error'] ?? 'Unknown OCR error');
      }

      final extractedText = responseData['text'] as String? ?? '';

      // Save the extracted text to a file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFilename = path.basenameWithoutExtension(file.path);
      final textFilePath = path.join(
        directory.path,
        '${originalFilename}_ocr_$timestamp.txt',
      );

      await File(textFilePath).writeAsString(extractedText);

      onProgress?.call(1.0);
      logger.info('OCR completed successfully, text saved to: $textFilePath');

      return OcrResult.success(
        extractedText,
        metadata: {
          'textFilePath': textFilePath,
          'pageCount': responseData['pageCount'],
          'language': responseData['language'],
        },
      );
    } catch (e) {
      logger.error('Error in OCR extraction: $e');
      return OcrResult.error(e.toString());
    }
  }

  /// Check if OCR is available based on subscription status
  Future<bool> isOcrAvailable() async {
    try {
      final subscriptionService = SubscriptionService();
      return await subscriptionService.hasActiveSubscription();
    } catch (e) {
      logger.error('Error checking OCR availability: $e');
      return false;
    }
  }

  /// Extract text from a document
  Future<OcrResult> extractTextFromDocument({
    required Document document,
    String language = 'eng',
    String pageRange = 'all',
    bool enhanceScanned = true,
    bool preserveLayout = true,
    Function(double)? onProgress,
  }) async {
    try {
      // Check if OCR is available (premium feature)
      final isAvailable = await isOcrAvailable();
      if (!isAvailable) {
        return OcrResult.error('OCR is a premium feature');
      }

      final file = File(document.pdfPath);
      if (!await file.exists()) {
        return OcrResult.error(
            'Document file does not exist: ${document.pdfPath}');
      }

      return extractAutoSizeText(
        file: file,
        language: language,
        pageRange: pageRange,
        enhanceScanned: enhanceScanned,
        preserveLayout: preserveLayout,
        onProgress: onProgress,
      );
    } catch (e) {
      logger.error('Error in extractTextFromDocument: $e');
      return OcrResult.error(e.toString());
    }
  }
}

/// Provider for OCR service
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

/// Provider to check if OCR is available based on subscription
final ocrAvailabilityProvider = FutureProvider<bool>((ref) async {
  final ocrService = ref.watch(ocrServiceProvider);
  return await ocrService.isOcrAvailable();
});
