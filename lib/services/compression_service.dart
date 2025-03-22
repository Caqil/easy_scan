import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/utils/compress_limit_utils.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/services/pdf_compression_api_service.dart';

/// A service to handle document compression with level-based restrictions
class CompressionService {
  final ImageService _imageService = ImageService();

  /// Compress a PDF document with level-based restrictions
  Future<Document?> compressPdf({
    required BuildContext context,
    required WidgetRef ref,
    required Document document,
    required CompressionLevel level,
    Function(double)? onProgress,
  }) async {
    // Check if the compression level is available for this user
    final canUseLevel = await CompressionLimitUtils.canUseCompressionLevel(
        context, ref, level,
        showDialog: true);

    if (!canUseLevel) {
      return null;
    }

    try {
      // Show progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('compression.compressing'.tr()),
              ],
            ),
          ),
        );
      }

      // Use the API service instead of local compression
      final compressionApiService = ref.read(pdfCompressionApiServiceProvider);
      final compressedPdfPath = await compressionApiService.compressPdf(
        file: File(document.pdfPath),
        compressionLevel: level,
        onProgress: onProgress,
      );

      // Generate a thumbnail for the compressed document
      File? thumbnailFile;
      try {
        thumbnailFile = await _imageService.createThumbnail(
          File(compressedPdfPath),
          size: AppConstants.thumbnailSize,
        );
      } catch (e) {
        logger.error('Error creating thumbnail for compressed PDF: $e');
        // Continue without thumbnail - it's not critical
      }

      // Create a new document model for the compressed PDF
      final compressedDocument = Document(
        name: '${document.name}_compressed',
        pdfPath: compressedPdfPath,
        pagesPaths: [compressedPdfPath],
        pageCount: document.pageCount,
        thumbnailPath: thumbnailFile?.path ?? document.thumbnailPath,
        isFavorite: document.isFavorite,
        folderId: document.folderId,
      );

      // Save the compressed document to the library
      await ref
          .read(documentsProvider.notifier)
          .addDocument(compressedDocument);

      // Close progress dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      return compressedDocument;
    } catch (e) {
      logger.error('Error compressing PDF: $e');

      // Close progress dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'compression.error'.tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }

      return null;
    }
  }

  /// Get file size reduction estimate based on compression level
  String getFileSizeReductionEstimate(CompressionLevel level) {
    return CompressionLevelMapper.getReductionEstimate(level);
  }
}

/// Provider for the compression service
final compressionServiceProvider = Provider<CompressionService>((ref) {
  return CompressionService();
});
