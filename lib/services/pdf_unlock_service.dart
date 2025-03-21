import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:scanpro/main.dart';
import 'package:scanpro/config/api_config.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/utils/file_utils.dart';

/// Service for unlocking password protected PDFs
class PdfUnlockService {
  static const String _unlockEndpoint = '/pdf/unlock';

  /// Unlock a password-protected PDF file
  Future<String> unlockPdf({
    required File file,
    required String password,
    Function(double)? onProgress,
  }) async {
    try {
      // Report initial progress
      onProgress?.call(0.1);

      // Create multipart request for unlocking
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}$_unlockEndpoint');
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
      );

      request.files.add(multipartFile);
      request.fields['password'] = password;

      logger.info('Uploading PDF to unlock to: $uri');

      // Send the unlock request
      onProgress?.call(0.3);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Report progress after upload
      onProgress?.call(0.6);

      // Handle the response
      if (streamedResponse.statusCode != 200) {
        logger
            .error('Unlock failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'API unlock failed: HTTP ${streamedResponse.statusCode} - ${response.body}');
      }

      // Create a valid file name for the unlocked PDF
      final originalFileName = path.basenameWithoutExtension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${originalFileName}_unlocked_$timestamp.pdf';

      // Get a unique path in the documents directory
      final String finalPath = await FileUtils.getUniqueFilePath(
        documentName: originalFileName,
        extension: 'pdf',
      );

      logger.info('Saving unlocked PDF to: $finalPath');

      // Create the file from the response
      final unlockFile = File(finalPath);
      await unlockFile.writeAsBytes(response.bodyBytes);

      onProgress?.call(0.9);

      // Verify the file was created and has content
      if (!await unlockFile.exists()) {
        throw Exception('Failed to create unlocked PDF file');
      }

      final fileSize = await unlockFile.length();
      if (fileSize == 0) {
        throw Exception('Unlocked PDF file is empty');
      }

      // Report completion
      onProgress?.call(1.0);
      logger.info(
          'PDF unlocked successfully: ${unlockFile.path}, size: $fileSize bytes');
      return unlockFile.path;
    } catch (e) {
      logger.error('Error unlocking PDF: $e');
      rethrow;
    }
  }

  /// Unlock a document and update it in the document provider
  Future<Document> unlockDocument({
    required Document document,
    required String password,
    required WidgetRef ref,
    Function(double)? onProgress,
  }) async {
    try {
      if (!document.isPasswordProtected) {
        throw Exception('Document is not password protected');
      }

      final file = File(document.pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file does not exist: ${document.pdfPath}');
      }

      // Unlock the PDF - this saves directly to the documents directory
      final unlockedPath = await unlockPdf(
        file: file,
        password: password,
        onProgress: onProgress,
      );

      // Verify the unlocked file exists and has content
      final unlockedFile = File(unlockedPath);
      if (!await unlockedFile.exists()) {
        throw Exception('Unlocked file does not exist after saving');
      }

      final unlockedFileSize = await unlockedFile.length();
      logger.info('Unlocked file size: $unlockedFileSize bytes');

      if (unlockedFileSize == 0) {
        throw Exception('Unlocked file is empty');
      }

      // Create updated document
      final updatedDoc = Document(
        id: document.id,
        name: document.name,
        pdfPath: unlockedPath,
        pagesPaths: [unlockedPath], // Update paths
        pageCount: document.pageCount,
        thumbnailPath: document.thumbnailPath,
        createdAt: document.createdAt,
        modifiedAt: DateTime.now(),
        tags: document.tags,
        folderId: document.folderId,
        isFavorite: document.isFavorite,
        isPasswordProtected: false, // PDF is now unlocked
        password: null, // Remove password
      );

      logger.info('Updating document with unlocked PDF path: $unlockedPath');

      // Update in provider
      await ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      return updatedDoc;
    } catch (e) {
      logger.error('Error in unlockDocument: $e');
      rethrow;
    }
  }
}

/// Provider for PDF unlock service
final pdfUnlockServiceProvider = Provider<PdfUnlockService>((ref) {
  return PdfUnlockService();
});
