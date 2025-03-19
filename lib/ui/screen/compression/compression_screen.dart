import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_compression_api_service.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
          ? _buildCompressingView()
          : _isAdvancedMode
              ? _buildAdvancedView()
              : _buildSimpleView(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSimpleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentInfoCard(),
          const SizedBox(height: 24),
          Text(
            'simple_view.compression_level'.tr(),
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCompressionLevelSelector(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryContainer,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FileUtils.getCompressionLevelTitle()!,
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  FileUtils.getCompressionLevelDescription()!,
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'simple_view.expected_results'.tr(),
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCompressionStatsCard(),
        ],
      ),
    );
  }

  Widget _buildAdvancedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentInfoCard(),
          const SizedBox(height: 24),
          Text(
            'advanced_view.advanced_settings'.tr(),
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderWithLabel(
            label: 'compression.overall_quality'.tr(),
            value: _qualitySliderValue,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _qualitySliderValue = value;
                final ratio = 1 - (value / 100);
                _estimatedFileSize =
                    (_originalFileSize * (1 - (ratio * 0.8))).round();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildSliderWithLabel(
            label: 'compression.image_quality'.tr(),
            value: _imageQualitySliderValue,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _imageQualitySliderValue = value;
                final ratio = 1 - (value / 100);
                _estimatedFileSize =
                    (_originalFileSize * (1 - (ratio * 0.6))).round();
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'advanced_view.warning'.tr(),
                    style: GoogleFonts.notoSerif(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'simple_view.expected_results'.tr(),
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCompressionStatsCard(),
        ],
      ),
    );
  }

  Widget _buildCompressingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _compressionProgress,
                    backgroundColor: Colors.grey.shade300,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 8,
                  ),
                  Text(
                    '${(_compressionProgress * 100).round()}%',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'compressing_view.compressing_pdf'.tr(),
            style: GoogleFonts.notoSerif(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'compressing_view.using_cloud_api'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compress,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCompressionStatusMessage(_compressionProgress),
                  style: GoogleFonts.notoSerif(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: widget.document.thumbnailPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(widget.document.thumbnailPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.picture_as_pdf,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.document.name,
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'stats.file_size'.tr(namedArgs: {
                    'size': '${FileUtils.formatFileSize(_originalFileSize)}'
                  }),
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'stats.pages'
                      .tr(namedArgs: {'count': '${widget.document.pageCount}'}),
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (widget.document.isPasswordProtected) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'stats.password_protected',
                        style: GoogleFonts.notoSerif(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
                label: 'options.low'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.low,
                onTap: () {
                  setState(() {
                    _compressionLevel = CompressionLevel.low;
                    _updateEstimatedSize();
                  });
                },
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                label: 'options.medium'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.medium,
                onTap: () {
                  setState(() {
                    _compressionLevel = CompressionLevel.medium;
                    _updateEstimatedSize();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompressionOption(
                label: 'options.high'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.high,
                onTap: () {
                  setState(() {
                    _compressionLevel = CompressionLevel.high;
                    _updateEstimatedSize();
                  });
                },
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                label: 'options.maximum'.tr(),
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.maximum,
                onTap: () {
                  setState(() {
                    _compressionLevel = CompressionLevel.maximum;
                    _updateEstimatedSize();
                  });
                },
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.notoSerif(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderWithLabel({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            Text(
              '${value.round()}%',
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()}%',
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'slider.more_compression'.tr(),
              style: GoogleFonts.notoSerif(
                fontSize: 10.sp,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'slider.better_quality'.tr(),
              style: GoogleFonts.notoSerif(
                fontSize: 10.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompressionStatsCard() {
    final sizeDifference = _originalFileSize - _estimatedFileSize;
    final percentageReduction = (_originalFileSize > 0)
        ? (sizeDifference / _originalFileSize * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                label: 'document.original_size'.tr(),
                value: FileUtils.formatFileSize(_originalFileSize),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey.shade400,
              ),
              _buildStatColumn(
                label: 'document.estimated_size'.tr(),
                value: FileUtils.formatFileSize(_estimatedFileSize),
                valueColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                label: 'document.size_reduction'.tr(),
                value: FileUtils.formatFileSize(sizeDifference),
                valueColor: Colors.green.shade700,
              ),
              _buildStatColumn(
                label: 'document.percentage'.tr(),
                value: '$percentageReduction%',
                valueColor: Colors.green.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.notoSerif(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isCompressing ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('common.cancel'.tr()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isCompressing ? null : _compressPdf,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isCompressing
                    ? 'buttons.compressing'.tr()
                    : 'buttons.compress'.tr()),
              ),
            ),
          ],
        ),
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
