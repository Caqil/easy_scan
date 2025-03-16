import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/services/image_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/compression/compression_screen.dart';
import 'package:easy_scan/utils/constants.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:easy_scan/utils/pdf_compresion.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;

class CompressionOptions {
  /// Show compression options bottom sheet
  static void showCompressionOptions(
    BuildContext context,
    WidgetRef ref, {
    Document? initialDocument,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompressionOptionsSheet(
        initialDocument: initialDocument,
        ref: ref,
      ),
    );
  }

  /// Quick compress a single PDF document
  static Future<void> quickCompressPdf(
    BuildContext context,
    WidgetRef ref,
    Document document,
    CompressionLevel compressionLevel,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Compressing PDF...'),
            ],
          ),
        ),
      );

      // Get password if document is protected
      final String? password =
          document.isPasswordProtected ? document.password : null;

      // Perform compression
      final pdfService = PdfService();
      final String compressedPdfPath = await pdfService.smartCompressPdf(
        document.pdfPath,
        level: compressionLevel,
        password: password,
      );

      // Create new document name with compression level indicator
      String levelSuffix = "";
      switch (compressionLevel) {
        case CompressionLevel.low:
          levelSuffix = " (Lightly Compressed)";
          break;
        case CompressionLevel.medium:
          levelSuffix = " (Compressed)";
          break;
        case CompressionLevel.high:
          levelSuffix = " (Highly Compressed)";
          break;
        case CompressionLevel.maximum:
          levelSuffix = " (Max Compressed)";
          break;
      }

      final String newName = "${document.name}$levelSuffix";

      // Generate thumbnail
      final imageService = ImageService();
      final File thumbnailFile = await imageService.createThumbnail(
        File(compressedPdfPath),
        size: AppConstants.thumbnailSize,
      );

      // Get page count
      final int pageCount = await pdfService.getPdfPageCount(compressedPdfPath);

      // Create the document model
      final compressedDocument = Document(
        name: newName,
        pdfPath: compressedPdfPath,
        pagesPaths: [compressedPdfPath],
        pageCount: pageCount,
        thumbnailPath: thumbnailFile.path,
        isPasswordProtected: document.isPasswordProtected,
        password: document.password,
      );

      // Save to document repository
      await ref
          .read(documentsProvider.notifier)
          .addDocument(compressedDocument);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'PDF compressed successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'Error compressing PDF: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Import and compress a PDF from device
  static Future<void> importAndCompressPdf(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Pick a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null) {
        return;
      }

      final File pdfFile = File(result.files.first.path!);
      if (!await pdfFile.exists()) {
        throw Exception('Selected file does not exist');
      }

      // Extract document name
      final String originalName = path.basenameWithoutExtension(pdfFile.path);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing file...'),
            ],
          ),
        ),
      );

      // Create a copy of the PDF in our app's documents directory
      final String targetPath = await FileUtils.getUniqueFilePath(
        documentName: originalName,
        extension: 'pdf',
      );

      await pdfFile.copy(targetPath);

      // Generate a thumbnail
      final imageService = ImageService();
      final File thumbnailFile = await imageService.createThumbnail(
        File(targetPath),
        size: AppConstants.thumbnailSize,
      );

      // Get page count
      final pdfService = PdfService();
      final int pageCount = await pdfService.getPdfPageCount(targetPath);

      // Create temporary document
      final tempDocument = Document(
        name: originalName,
        pdfPath: targetPath,
        pagesPaths: [targetPath],
        pageCount: pageCount,
        thumbnailPath: thumbnailFile.path,
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);

        // Now navigate to compression screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompressionScreen(document: tempDocument),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog if it's open
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }

        AppDialogs.showSnackBar(
          context,
          message: 'Error importing PDF: $e',
          type: SnackBarType.error,
        );
        debugPrint('Error importing PDF: $e');
      }
    }
  }
}

class _CompressionOptionsSheet extends ConsumerWidget {
  final Document? initialDocument;

  const _CompressionOptionsSheet({
    required this.ref,
    this.initialDocument,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 2.h,
            width: 30.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.compress,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'PDF Compressor',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Options
          if (initialDocument != null)
            _buildOptionTile(
              context: context,
              icon: Icons.compress,
              title: 'Compress This PDF',
              description:
                  'Open compression tools for "${initialDocument!.name}"',
              onTap: () {
                Navigator.pop(context);
                _navigateToCompression(context, initialDocument!);
              },
            ),

          _buildOptionTile(
            context: context,
            icon: Icons.upload_file,
            title: 'Import and Compress PDF',
            description: 'Select a PDF file from your device to compress',
            onTap: () {
              Navigator.pop(context);
              CompressionOptions.importAndCompressPdf(context, ref);
            },
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.subject,
            title: 'Select from Library',
            description: 'Choose a PDF document from your library to compress',
            onTap: () {
              Navigator.pop(context);
              _showLibraryPdfSelector(context);
            },
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.tune,
            title: 'Batch Compression',
            description: 'Compress multiple PDFs at once',
            onTap: () {
              Navigator.pop(context);
              _showBatchCompressionDialog(context);
            },
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSerif(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.notoSerif(
          fontSize: 12.sp,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  void _navigateToCompression(BuildContext context, Document document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompressionScreen(document: document),
      ),
    );
  }

  void _showLibraryPdfSelector(BuildContext context) {
    // Get all PDF documents
    final allDocuments = ref.read(documentsProvider);
    final pdfDocs = allDocuments.where((doc) {
      final extension = path.extension(doc.pdfPath).toLowerCase();
      return extension == '.pdf';
    }).toList();

    if (pdfDocs.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'No PDF documents found in your library',
        type: SnackBarType.warning,
      );
      return;
    }

    // Sort by most recent first
    pdfDocs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select PDF to Compress'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pdfDocs.length,
            itemBuilder: (context, index) {
              final doc = pdfDocs[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: doc.thumbnailPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.file(
                            File(doc.thumbnailPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.picture_as_pdf, color: Colors.red.shade300),
                ),
                title: Text(
                  doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${doc.pageCount} pages',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCompression(context, doc);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBatchCompressionDialog(BuildContext context) {
    // Get all PDF documents
    final allDocuments = ref.read(documentsProvider);
    final pdfDocs = allDocuments.where((doc) {
      final extension = path.extension(doc.pdfPath).toLowerCase();
      return extension == '.pdf';
    }).toList();

    if (pdfDocs.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'No PDF documents found in your library',
        type: SnackBarType.warning,
      );
      return;
    }

    // Track selected documents
    final selectedDocs = <Document>[];
    CompressionLevel selectedLevel = CompressionLevel.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Batch Compression'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select compression level:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Compression level selector
                DropdownButton<CompressionLevel>(
                  value: selectedLevel,
                  isExpanded: true,
                  onChanged: (CompressionLevel? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedLevel = newValue;
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: CompressionLevel.low,
                      child: Text('Low - Best Quality'),
                    ),
                    DropdownMenuItem(
                      value: CompressionLevel.medium,
                      child: Text('Medium - Balanced'),
                    ),
                    DropdownMenuItem(
                      value: CompressionLevel.high,
                      child: Text('High - Smaller Size'),
                    ),
                    DropdownMenuItem(
                      value: CompressionLevel.maximum,
                      child: Text('Maximum - Smallest Size'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text(
                  'Select PDFs to compress:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pdfDocs.length,
                    itemBuilder: (context, index) {
                      final doc = pdfDocs[index];
                      final isSelected = selectedDocs.contains(doc);

                      return CheckboxListTile(
                        title: Text(
                          doc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${doc.pageCount} pages'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              selectedDocs.add(doc);
                            } else {
                              selectedDocs.remove(doc);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedDocs.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _processBatchCompression(
                          context, selectedDocs, selectedLevel);
                    },
              child: const Text('Compress'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBatchCompression(
    BuildContext context,
    List<Document> documents,
    CompressionLevel compressionLevel,
  ) async {
    if (documents.isEmpty) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Batch Compression'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Processing ${documents.length} documents...'),
                Text('This may take a while.'),
              ],
            ),
          );
        },
      ),
    );

    int successCount = 0;
    int failCount = 0;

    // Process each document
    for (final document in documents) {
      try {
        final pdfService = PdfService();
        final String? password =
            document.isPasswordProtected ? document.password : null;

        // Compress the PDF
        final String compressedPdfPath = await pdfService.smartCompressPdf(
          document.pdfPath,
          level: compressionLevel,
          password: password,
        );

        // Create new document name with compression level indicator
        String levelSuffix = "";
        switch (compressionLevel) {
          case CompressionLevel.low:
            levelSuffix = " (Lightly Compressed)";
            break;
          case CompressionLevel.medium:
            levelSuffix = " (Compressed)";
            break;
          case CompressionLevel.high:
            levelSuffix = " (Highly Compressed)";
            break;
          case CompressionLevel.maximum:
            levelSuffix = " (Max Compressed)";
            break;
        }

        final String newName = "${document.name}$levelSuffix";

        // Generate thumbnail
        final imageService = ImageService();
        final File thumbnailFile = await imageService.createThumbnail(
          File(compressedPdfPath),
          size: AppConstants.thumbnailSize,
        );

        // Get page count
        final int pageCount =
            await pdfService.getPdfPageCount(compressedPdfPath);

        // Create the document model
        final compressedDocument = Document(
          name: newName,
          pdfPath: compressedPdfPath,
          pagesPaths: [compressedPdfPath],
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
          isPasswordProtected: document.isPasswordProtected,
          password: document.password,
        );

        // Save to document repository
        await ref
            .read(documentsProvider.notifier)
            .addDocument(compressedDocument);

        successCount++;
      } catch (e) {
        debugPrint('Error compressing document ${document.name}: $e');
        failCount++;
      }
    }

    // Close progress dialog
    if (context.mounted) {
      Navigator.pop(context);

      // Show results
      AppDialogs.showSnackBar(
        context,
        message:
            'Compression complete: $successCount successful, $failCount failed',
        type: successCount > 0 ? SnackBarType.success : SnackBarType.error,
      );
    }
  }
}
