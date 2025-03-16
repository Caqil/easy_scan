// lib/ui/screen/conversion/compression_screen.dart

import 'dart:io';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/document.dart';
import '../../../providers/document_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../ui/common/app_bar.dart';
import '../../../ui/common/dialogs.dart';
import '../../../utils/pdf_compresion.dart';

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
        // Estimate compressed size based on selected level
        _updateEstimatedSize();
      });
    }
  }

  void _updateEstimatedSize() {
    // Estimate the compressed size based on typical compression ratios
    double compressionRatio;

    switch (_compressionLevel) {
      case CompressionLevel.low:
        compressionRatio = 0.8; // 20% reduction
        break;
      case CompressionLevel.medium:
        compressionRatio = 0.5; // 50% reduction
        break;
      case CompressionLevel.high:
        compressionRatio = 0.3; // 70% reduction
        break;
      case CompressionLevel.maximum:
        compressionRatio = 0.2; // 80% reduction
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
        title: Text('Compress PDF'),
        actions: [
          IconButton(
            icon: Icon(_isAdvancedMode ? Icons.tune : Icons.tune),
            tooltip: _isAdvancedMode ? 'Simple Mode' : 'Advanced Mode',
            onPressed: () {
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
          // Document info card
          _buildDocumentInfoCard(),

          const SizedBox(height: 24),

          // Compression level selector
          Text(
            'Compression Level',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _buildCompressionLevelSelector(),

          const SizedBox(height: 16),

          // Compression level description
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
                  _getCompressionLevelTitle(),
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getCompressionLevelDescription(),
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Expected results
          Text(
            'Expected Results',
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
          // Document info card
          _buildDocumentInfoCard(),

          const SizedBox(height: 24),

          // Advanced settings title
          Text(
            'Advanced Settings',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Overall quality slider
          _buildSliderWithLabel(
            label: 'Overall Quality',
            value: _qualitySliderValue,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _qualitySliderValue = value;
                // Custom logic to update estimated size
                final ratio = 1 - (value / 100);
                _estimatedFileSize =
                    (_originalFileSize * (1 - (ratio * 0.8))).round();
              });
            },
          ),

          const SizedBox(height: 16),

          // Image quality slider
          _buildSliderWithLabel(
            label: 'Image Quality',
            value: _imageQualitySliderValue,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _imageQualitySliderValue = value;
                // Adjust estimated size based on image quality too
                final ratio = 1 - (value / 100);
                _estimatedFileSize =
                    (_originalFileSize * (1 - (ratio * 0.6))).round();
              });
            },
          ),

          const SizedBox(height: 16),

          // Note about advanced settings
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
                    'Lower quality values result in better compression but may affect readability and image quality.',
                    style: GoogleFonts.notoSerif(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Expected results
          Text(
            'Expected Results',
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
          // Compression progress visual
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
            'Compressing PDF',
            style: GoogleFonts.notoSerif(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Please wait while your document is being compressed...',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 32),

          // Compression status message
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
          // Document thumbnail or icon
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

          // Document details
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
                  'File size: ${FileUtils.formatFileSize(_originalFileSize)}',
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pages: ${widget.document.pageCount}',
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
                        'Password Protected',
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
                label: 'Low',
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
                label: 'Medium',
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
                label: 'High',
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
                label: 'Maximum',
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
              'More Compression',
              style: GoogleFonts.notoSerif(
                fontSize: 10.sp,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Better Quality',
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
    // Calculate size difference and percentage
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
                label: 'Original Size',
                value: FileUtils.formatFileSize(_originalFileSize),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey.shade400,
              ),
              _buildStatColumn(
                label: 'Estimated Size',
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
                label: 'Size Reduction',
                value: FileUtils.formatFileSize(sizeDifference),
                valueColor: Colors.green.shade700,
              ),
              _buildStatColumn(
                label: 'Percentage',
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
                child: const Text('Cancel'),
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
                child: Text(_isCompressing ? 'Compressing...' : 'Compress'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCompressionLevelTitle() {
    switch (_compressionLevel) {
      case CompressionLevel.low:
        return 'Low Compression (Best Quality)';
      case CompressionLevel.medium:
        return 'Medium Compression (Good Quality)';
      case CompressionLevel.high:
        return 'High Compression (Reduced Quality)';
      case CompressionLevel.maximum:
        return 'Maximum Compression (Lowest Quality)';
    }
  }

  String _getCompressionLevelDescription() {
    switch (_compressionLevel) {
      case CompressionLevel.low:
        return 'Minimal file size reduction with best visual quality. Ideal for documents with high-quality images or graphics.';
      case CompressionLevel.medium:
        return 'Balanced compression that reduces file size while maintaining good quality. Recommended for most documents.';
      case CompressionLevel.high:
        return 'Significant file size reduction with some quality loss. Good for documents that need to be shared online.';
      case CompressionLevel.maximum:
        return 'Maximum file size reduction with noticeable quality loss. Best for documents where small file size is critical.';
    }
  }

  String _getCompressionStatusMessage(double progress) {
    if (progress < 0.3) {
      return 'Analyzing document structure...';
    } else if (progress < 0.6) {
      return 'Optimizing content...';
    } else if (progress < 0.9) {
      return 'Finalizing compressed PDF...';
    } else {
      return 'Almost done!';
    }
  }

  Future<void> _compressPdf() async {
    if (_isCompressing) return;

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.1; // Start progress
    });

    try {
      // Simulate progress updates
      _startProgressSimulation();

      // Create a PDF service instance
      final pdfService = PdfService();

      // Get the password if document is protected
      final String? password =
          widget.document.isPasswordProtected ? widget.document.password : null;

      // Get original file size before compression
      final File originalFile = File(widget.document.pdfPath);
      final int originalSize = await originalFile.length();

      // Determine which compression method to use based on mode
      final String compressedPdfPath;

      if (_isAdvancedMode) {
        // Extract images from PDF, optimize them, then rebuild the PDF
        // For advanced mode, we'll take a more aggressive approach

        // First create a temporary directory to work with
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Copy the original file to a temp location so we don't modify the original yet
        await originalFile.copy(tempPath);

        // Compress the PDF with more aggressive image optimization
        compressedPdfPath = await pdfService.compressPdf(
          tempPath,
          quality: _qualitySliderValue.round(),
          imageQuality: _imageQualitySliderValue.round(),
          password: password,
        );

        // Clean up the temp file if it's not the result
        if (tempPath != compressedPdfPath) {
          try {
            await File(tempPath).delete();
          } catch (e) {
            // Ignore cleanup errors
            debugPrint('Warning: Could not clean up temp file: $tempPath');
          }
        }
      } else {
        // For simple mode, we'll use preset compression levels
        // First create a temporary copy of the file
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await originalFile.copy(tempPath);

        // Map our UI compression level to the one defined in pdf_compresion.dart
        CompressionLevel compressionLevel;
        switch (_compressionLevel) {
          case CompressionLevel.low:
            compressionLevel = CompressionLevel.low;
            break;
          case CompressionLevel.medium:
            compressionLevel = CompressionLevel.medium;
            break;
          case CompressionLevel.high:
            compressionLevel = CompressionLevel.high;
            break;
          case CompressionLevel.maximum:
            compressionLevel = CompressionLevel.maximum;
            break;
        }

        // Use preset compression level in simple mode
        compressedPdfPath = await pdfService.smartCompressPdf(
          tempPath,
          level: compressionLevel,
          password: password,
        );

        // Clean up the temp file if it's not the result
        if (tempPath != compressedPdfPath) {
          try {
            await File(tempPath).delete();
          } catch (e) {
            // Ignore cleanup errors
            debugPrint('Warning: Could not clean up temp file: $tempPath');
          }
        }
      }

      // Update the progress to indicate completion
      setState(() {
        _compressionProgress = 1.0;
      });

      // Get the actual file size after compression for more accurate display
      final File compressedFile = File(compressedPdfPath);
      final int actualCompressedSize = await compressedFile.length();

      // Calculate actual compression results
      final int sizeDifference = originalSize - actualCompressedSize;
      final double compressionPercentage =
          (_originalFileSize > 0) ? (sizeDifference / originalSize * 100) : 0.0;

      // Check if compression was effective
      if (actualCompressedSize >= originalSize) {
        // Compression didn't reduce the size
        AppDialogs.showSnackBar(
          context,
          message:
              'The PDF is already optimized or cannot be compressed further.',
          type: SnackBarType.warning,
        );

        // Delete the ineffective compressed file
        try {
          await compressedFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }

        setState(() {
          _isCompressing = false;
        });
        return;
      }

      // Create a new document model for the compressed PDF
      final compressedDocument = widget.document.copyWith(
        name: '${widget.document.name} (Compressed)',
        pdfPath: compressedPdfPath,
        pagesPaths: [compressedPdfPath],
        modifiedAt: DateTime.now(),
      );

      // Add the compressed document to the document provider
      await ref
          .read(documentsProvider.notifier)
          .addDocument(compressedDocument);

      // Navigate back and show success message
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message:
              'PDF compressed successfully (${compressionPercentage.toStringAsFixed(1)}% reduction)',
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.error,
          message: 'Error compressing PDF: ${e.toString()}',
        );

        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  void _startProgressSimulation() {
    // Simulate progress updates to provide visual feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isCompressing) {
        setState(() {
          _compressionProgress = 0.3;
        });

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _isCompressing) {
            setState(() {
              _compressionProgress = 0.5;
            });

            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted && _isCompressing) {
                setState(() {
                  _compressionProgress = 0.7;
                });

                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted && _isCompressing) {
                    setState(() {
                      _compressionProgress = 0.9;
                    });
                  }
                });
              }
            });
          }
        });
      }
    });
  }
}
