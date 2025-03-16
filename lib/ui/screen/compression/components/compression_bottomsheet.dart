import 'dart:io';

import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
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
    Key? key,
    required this.document,
  }) : super(key: key);

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
}
