import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_compression_api_service.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/compression/components/compression_advanced_view.dart';
import 'package:scanpro/ui/screen/compression/components/compression_simple_view.dart';
import 'package:scanpro/ui/screen/compression/components/compression_widgets.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'dart:io';
import 'components/compression_progress_view.dart';

class CompressionScreen extends ConsumerStatefulWidget {
  final Document document;

  const CompressionScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends ConsumerState<CompressionScreen> {
  CompressionLevel _compressionLevel = CompressionLevel.medium;
  bool _isAdvancedMode = false;
  bool _isCompressing = false;
  double _qualitySliderValue = 70.0;
  double _imageQualitySliderValue = 60.0;
  int _originalFileSize = 0;
  int _estimatedFileSize = 0;
  double _compressionProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    final File file = File(widget.document.pdfPath);
    if (await file.exists()) {
      final size = await file.length();
      setState(() {
        _originalFileSize = size;
        _updateEstimatedSize();
      });
    }
  }

  void _updateEstimatedSize() {
    double compressionRatio;
    switch (_compressionLevel) {
      case CompressionLevel.low:
        compressionRatio = 0.8;
        break;
      case CompressionLevel.medium:
        compressionRatio = 0.5;
        break;
      case CompressionLevel.high:
        compressionRatio = 0.3;
        break;
      case CompressionLevel.maximum:
        compressionRatio = 0.2;
        break;
    }
    setState(() {
      _estimatedFileSize = (_originalFileSize * compressionRatio).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('compression.compress_pdf'.tr()),
        actions: [
          IconButton(
            icon: Icon(_isAdvancedMode ? Icons.tune : Icons.tune),
            tooltip: _isAdvancedMode ? 'Simple Mode' : 'Advanced Mode',
            onPressed: _isCompressing
                ? null
                : () {
                    setState(() {
                      _isAdvancedMode = !_isAdvancedMode;
                    });
                  },
          ),
        ],
      ),
      body: _isCompressing
          ? CompressionProgressView(
              progress: _compressionProgress,
              statusMessage: _getCompressionStatusMessage(_compressionProgress),
            )
          : _isAdvancedMode
              ? CompressionAdvancedView(
                  document: widget.document,
                  originalSize: _originalFileSize,
                  estimatedSize: _estimatedFileSize,
                  qualityValue: _qualitySliderValue,
                  imageQualityValue: _imageQualitySliderValue,
                  onQualityChanged: (value) {
                    setState(() {
                      _qualitySliderValue = value;
                      final ratio = 1 - (value / 100);
                      _estimatedFileSize =
                          (_originalFileSize * (1 - (ratio * 0.8))).round();
                    });
                  },
                  onImageQualityChanged: (value) {
                    setState(() {
                      _imageQualitySliderValue = value;
                      final ratio = 1 - (value / 100);
                      _estimatedFileSize =
                          (_originalFileSize * (1 - (ratio * 0.6))).round();
                    });
                  },
                )
              : CompressionSimpleView(
                  document: widget.document,
                  originalSize: _originalFileSize,
                  estimatedSize: _estimatedFileSize,
                  compressionLevel: _compressionLevel,
                  onLevelChanged: (level) {
                    setState(() {
                      _compressionLevel = level;
                      _updateEstimatedSize();
                    });
                  },
                ),
      bottomNavigationBar: CompressionBottomBar(
        isCompressing: _isCompressing,
        onCancel: () => Navigator.pop(context),
        onCompress: _compressPdf,
      ),
    );
  }

  String _getCompressionStatusMessage(double progress) {
    if (progress < 0.3) {
      return 'compressing_view.status.uploading'.tr();
    } else if (progress < 0.6) {
      return 'compressing_view.status.compressing'.tr();
    } else if (progress < 0.9) {
      return 'compressing_view.status.downloading'.tr();
    } else {
      return 'compressing_view.status.finalizing'.tr();
    }
  }

  Future<void> _compressPdf() async {
    // [Same compression logic as original]
    if (_isCompressing) return;

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.1;
    });

    try {
      final File originalFile = File(widget.document.pdfPath);
      final int originalSize = await originalFile.length();

      logger.info('Starting compression of PDF: ${widget.document.name}');
      logger.info('Original size: ${FileUtils.formatFileSize(originalSize)}');

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

      logger.info('API compression completed successfully');

      final File compressedFile = File(compressedPdfPath);
      if (!await compressedFile.exists()) {
        throw Exception('Compression failed: output file not found');
      }

      final int compressedSize = await compressedFile.length();

      setState(() {
        _compressionProgress = 1.0;
      });

      if (compressedSize >= originalSize) {
        AppDialogs.showSnackBar(
          context,
          message: 'snackbar.already_optimized'.tr(),
          type: SnackBarType.warning,
        );
        try {
          await compressedFile.delete();
        } catch (e) {}
        setState(() {
          _isCompressing = false;
        });
        return;
      }

      final double compressionPercentage =
          ((originalSize - compressedSize) / originalSize) * 100;

      final imageService = ImageService();
      File? thumbnailFile;
      try {
        thumbnailFile = await imageService.createThumbnail(
          compressedFile,
          size: AppConstants.thumbnailSize,
        );
      } catch (e) {
        logger.error('Failed to generate thumbnail: $e');
      }

      final String newName =
          '${widget.document.name} (Compressed ${compressionPercentage.toStringAsFixed(0)}%)';

      final compressedDocument = Document(
        name: newName,
        pdfPath: compressedPdfPath,
        pagesPaths: [compressedPdfPath],
        pageCount: widget.document.pageCount,
        thumbnailPath: thumbnailFile?.path,
        isPasswordProtected: widget.document.isPasswordProtected,
        password: widget.document.password,
        modifiedAt: DateTime.now(),
      );

      await ref
          .read(documentsProvider.notifier)
          .addDocument(compressedDocument);

      if (mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(context,
            type: SnackBarType.success,
            message: 'snackbar.success'.tr(
              namedArgs: {
                'percentage': '${compressionPercentage.toStringAsFixed(1)}'
              },
            ));
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.error,
          message: 'snackbar.error'.tr(namedArgs: {'error': e.toString()}),
        );
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }
}
