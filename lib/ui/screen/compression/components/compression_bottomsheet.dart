import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_compression_api_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CompressionBottomSheet extends ConsumerStatefulWidget {
  final Document document;

  const CompressionBottomSheet({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<CompressionBottomSheet> createState() =>
      _CompressionBottomSheetState();
}

class _CompressionBottomSheetState
    extends ConsumerState<CompressionBottomSheet> {
  CompressionLevel _compressionLevel = CompressionLevel.medium;
  bool _isCompressing = false;
  double _compressionProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.compress,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              AutoSizeText(
                'compress_pdf'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            'documents'.tr(namedArgs: {'name': widget.document.name}),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 15.h),
          AutoSizeText(
            'compression_level'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
          const SizedBox(height: 16),
          _buildCompressionLevelSelector(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  FileUtils.getCompressionLevelTitle()!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  FileUtils.getCompressionLevelDescription()!,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isCompressing) ...[
            LinearProgressIndicator(
              value: _compressionProgress,
              backgroundColor: Colors.grey.shade200,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Center(
              child: AutoSizeText(
                'compressing'.tr(),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isCompressing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: AutoSizeText('common.cancel'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCompressing ? null : _compressPdf,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCompressing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : AutoSizeText('compress'.tr()),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildCompressionLevelSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompressionOption(
                label: 'compression_levels.low'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.low,
                onTap: () =>
                    setState(() => _compressionLevel = CompressionLevel.low),
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                label: 'compression_levels.medium'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.medium,
                onTap: () =>
                    setState(() => _compressionLevel = CompressionLevel.medium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompressionOption(
                label: 'compression_levels.high'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.high,
                onTap: () =>
                    setState(() => _compressionLevel = CompressionLevel.high),
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                label: 'compression_levels.maximum'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.maximum,
                onTap: () => setState(
                    () => _compressionLevel = CompressionLevel.maximum),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompressionOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isCompressing ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _compressPdf() async {
    if (_isCompressing) return;

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.1;
    });

    try {
      final File originalFile = File(widget.document.pdfPath);
      final int originalSize = await originalFile.length();

      logger.info('Starting compression for ${widget.document.name}');
      logger.info(
          'Original file size: ${FileUtils.formatFileSize(originalSize)}');
      logger.info('Compression level: $_compressionLevel');

      final apiService = PdfCompressionApiService();
      final compressedPdfPath = await apiService.compressPdf(
        file: originalFile,
        compressionLevel: _compressionLevel,
        onProgress: (progress) {
          setState(() {
            _compressionProgress = progress;
          });
        },
      );

      logger.info('API compression completed: $compressedPdfPath');

      if (compressedPdfPath == widget.document.pdfPath) {
        if (mounted) {
          Navigator.pop(context);
          AppDialogs.showSnackBar(
            context,
            message: 'the_pdf_could_not_be_compressed_further'.tr(),
            type: SnackBarType.warning,
          );
        }
        return;
      }

      final File compressedResult = File(compressedPdfPath);
      final int compressedSize = await compressedResult.length();

      final double percentReduction =
          ((originalSize - compressedSize) / originalSize * 100);

      logger.info(
          'Compression complete. New size: ${FileUtils.formatFileSize(compressedSize)}');
      logger.info('Size reduction: ${percentReduction.toStringAsFixed(1)}%');

      final compressedDocument = widget.document.copyWith(
        name: '${widget.document.name} (Compressed)',
        pdfPath: compressedPdfPath,
        pagesPaths: [compressedPdfPath],
        modifiedAt: DateTime.now(),
      );

      await ref
          .read(documentsProvider.notifier)
          .addDocument(compressedDocument);

      if (mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'compression_success'.tr(namedArgs: {
            'percent': percentReduction.toStringAsFixed(1),
          }),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.error,
          message:
              'error_compressing_pdf'.tr(namedArgs: {'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }
}
