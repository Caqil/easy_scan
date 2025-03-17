import 'dart:io';

import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/services/pdf_compression_api_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/compression/compression_screen.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:easy_scan/utils/pdf_compresion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  bool _useApiCompression = true; // Toggle for API vs local compression

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
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Icon(
                Icons.compress,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Compress PDF',
                style: GoogleFonts.notoSerif(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Document info
          Text(
            'Document: ${widget.document.name}',
            style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),

          const SizedBox(height: 24),

          // API vs Local compression toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compression Method',
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              Switch(
                value: _useApiCompression,
                onChanged: _isCompressing
                    ? null
                    : (value) {
                        setState(() {
                          _useApiCompression = value;
                        });
                      },
              ),
            ],
          ),

          Text(
            _useApiCompression
                ? 'Using cloud API compression (better results, requires internet)'
                : 'Using local compression (works offline, faster)',
            style: GoogleFonts.notoSerif(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Compression level selector
          Text(
            'Compression Level',
            style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),

          const SizedBox(height: 16),

          _buildCompressionLevelSelector(),

          const SizedBox(height: 16),

          // Compression level description
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
                Text(
                  _getCompressionLevelTitle(),
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCompressionLevelDescription(),
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress indicator (shown during compression)
          if (_isCompressing) ...[
            LinearProgressIndicator(
              value: _compressionProgress,
              backgroundColor: Colors.grey.shade200,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Compressing PDF...',
                style: GoogleFonts.notoSerif(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
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
                  child: Text('Cancel'),
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
                  child: _isCompressing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Compress'),
                ),
              ),
            ],
          ),

          // Bottom padding for safe area
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
                label: 'Low',
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.low,
                onTap: () =>
                    setState(() => _compressionLevel = CompressionLevel.low),
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                label: 'Medium',
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
                label: 'High',
                icon: Icons.compress,
                isSelected: _compressionLevel == CompressionLevel.high,
                onTap: () =>
                    setState(() => _compressionLevel = CompressionLevel.high),
              ),
            ),
            Expanded(
              child: _buildCompressionOption(
                label: 'Maximum',
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
            Text(
              label,
              style: GoogleFonts.notoSerif(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Future<void> _compressPdf() async {
    if (_isCompressing) return;

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.1; // Start progress
    });

    try {
      // Get original file size for later comparison
      final File originalFile = File(widget.document.pdfPath);
      final int originalSize = await originalFile.length();

      // Show a debug message with file info
      debugPrint('Starting compression for ${widget.document.name}');
      debugPrint(
          'Original file size: ${FileUtils.formatFileSize(originalSize)}');
      debugPrint('Compression level: $_compressionLevel');
      debugPrint('Using API compression: $_useApiCompression');

      // Path to the compressed file
      String compressedPdfPath;

      if (_useApiCompression) {
        // Use API compression
        try {
          // Create an instance of the API service
          final apiService = PdfCompressionApiService();

          // Compress the PDF using the API
          compressedPdfPath = await apiService.compressPdf(
            file: originalFile,
            compressionLevel: _compressionLevel,
            onProgress: (progress) {
              setState(() {
                _compressionProgress = progress;
              });
            },
          );

          debugPrint('API compression completed: $compressedPdfPath');
        } catch (e) {
          // If API compression fails, we'll fallback to local compression
          debugPrint('API compression failed: $e');
          debugPrint('Falling back to local compression...');

          // Update progress and inform user about fallback
          setState(() {
            _compressionProgress = 0.3;
          });

          // Fallback to local compression
          compressedPdfPath = await _performLocalCompression(originalFile);
        }
      } else {
        // Use local compression directly
        compressedPdfPath = await _performLocalCompression(originalFile);
      }

      // Check if the compression was successful (path is different)
      if (compressedPdfPath == widget.document.pdfPath) {
        // No compression occurred - original file was returned
        if (mounted) {
          Navigator.pop(context);

          AppDialogs.showSnackBar(
            context,
            message: 'The PDF could not be compressed further.',
            type: SnackBarType.warning,
          );
        }
        return;
      }

      // Get the compressed file size
      final File compressedResult = File(compressedPdfPath);
      final int compressedSize = await compressedResult.length();

      // Calculate compression percentage
      final double percentReduction =
          ((originalSize - compressedSize) / originalSize * 100);

      debugPrint(
          'Compression complete. New size: ${FileUtils.formatFileSize(compressedSize)}');
      debugPrint('Size reduction: ${percentReduction.toStringAsFixed(1)}%');

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

      // Close the sheet
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message:
              'PDF compressed successfully (${percentReduction.toStringAsFixed(1)}% reduction)',
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
      }
    } finally {
      // Reset state
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  // Helper method for local compression fallback
  Future<String> _performLocalCompression(File originalFile) async {
    // Get the password if document is protected
    final String? password =
        widget.document.isPasswordProtected ? widget.document.password : null;

    // Perform local compression using existing methods
    try {
      // First attempt: Try direct compression with FileCompressor
      File? compressedFile;
      try {
        // Create a temporary copy to work with
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = path.join(tempDir.path,
            'temp_pre_compress_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await originalFile.copy(tempFilePath);

        // Update progress
        setState(() {
          _compressionProgress = 0.4;
        });

        // Compress using the FileCompressor
        compressedFile = await FileCompressor.compressPdf(
          file: File(tempFilePath),
          compressionLevel: PdfCompressionLevel.best,
        );

        // Update progress
        setState(() {
          _compressionProgress = 0.7;
        });
      } catch (e) {
        debugPrint('FileCompressor error: $e');
        // We'll fall back to other methods
      }

      // If FileCompressor was successful and reduced file size
      if (compressedFile != null && await compressedFile.exists()) {
        final int compressedSize = await compressedFile.length();
        final int originalSize = await originalFile.length();

        if (compressedSize < originalSize) {
          // Create the document name for the final destination
          final String outputPath = await FileUtils.getUniqueFilePath(
            documentName: '${widget.document.name}_compressed',
            extension: 'pdf',
          );

          // Copy to final path
          await compressedFile.copy(outputPath);

          // Clean up
          try {
            await compressedFile.delete();
          } catch (e) {
            // Ignore cleanup errors
          }

          setState(() {
            _compressionProgress = 1.0;
          });

          return outputPath;
        } else {
          // Clean up the ineffective result
          await compressedFile.delete();
          debugPrint(
              'FileCompressor did not reduce size, trying alternative method...');
        }
      }

      // Fallback to PdfService
      setState(() {
        _compressionProgress = 0.5;
      });

      // Create a PDF service instance and use its smartCompressPdf method
      final pdfService = PdfService();
      final String compressedPdfPath = await pdfService.smartCompressPdf(
        widget.document.pdfPath,
        level: _compressionLevel,
        password: password,
      );

      // Update the progress to indicate completion
      setState(() {
        _compressionProgress = 1.0;
      });

      return compressedPdfPath;
    } catch (e) {
      debugPrint('Local compression error: $e');
      rethrow;
    }
  }

  void _startProgressSimulation() {
    // Simulate progress updates to provide visual feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isCompressing) {
        setState(() {
          _compressionProgress = 0.3;
        });

        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && _isCompressing) {
            setState(() {
              _compressionProgress = 0.5;
            });

            Future.delayed(const Duration(milliseconds: 900), () {
              if (mounted && _isCompressing) {
                setState(() {
                  _compressionProgress = 0.7;
                });

                Future.delayed(const Duration(milliseconds: 800), () {
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
