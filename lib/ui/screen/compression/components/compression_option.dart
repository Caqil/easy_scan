import 'dart:io';
import 'package:easy_scan/config/helper.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/services/pdf_compression_api_service.dart';
import 'package:easy_scan/services/image_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/compression/compression_screen.dart';
import 'package:easy_scan/ui/screen/compression/components/compression_bottomsheet.dart';
import 'package:easy_scan/utils/constants.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;

class CompressionOptions {
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
      ),
    );
  }

  static void showCompressionBottomSheet(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompressionBottomSheet(document: document),
    );
  }

  static Future<void> quickCompressPdf(
    BuildContext context,
    WidgetRef ref,
    Document document,
    CompressionLevel compressionLevel,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Compressing PDF...'),
                Text('Using cloud compression API'),
              ],
            ),
          ),
        ),
      );

      final originalFile = File(document.pdfPath);
      final originalSize = await originalFile.length();

      final apiService = PdfCompressionApiService();
      String compressedPdfPath = await apiService.compressPdf(
        file: originalFile,
        compressionLevel: compressionLevel,
        onProgress: null,
      );

      String levelSuffix;
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
      final compressedFile = File(compressedPdfPath);
      final compressedSize = await compressedFile.length();

      if (compressedSize >= originalSize) {
        try {
          await compressedFile.delete();
        } catch (e) {}
        if (context.mounted) {
          Navigator.pop(context);
          AppDialogs.showSnackBar(
            context,
            message: 'The PDF could not be compressed further.',
            type: SnackBarType.warning,
          );
        }
        return;
      }

      final compressionPercentage =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      final imageService = ImageService();
      final File thumbnailFile = await imageService.createThumbnail(
        compressedFile,
        size: AppConstants.thumbnailSize,
      );

      final pdfService = PdfService();
      final int pageCount = await pdfService.getPdfPageCount(compressedPdfPath);

      final compressedDocument = Document(
        name: newName,
        pdfPath: compressedPdfPath,
        pagesPaths: [compressedPdfPath],
        pageCount: pageCount,
        thumbnailPath: thumbnailFile.path,
        isPasswordProtected: document.isPasswordProtected,
        password: document.password,
      );

      await ref
          .read(documentsProvider.notifier)
          .addDocument(compressedDocument);

      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message:
              'PDF compressed successfully ($compressionPercentage% reduction)',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
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

  static Future<void> importAndCompressPdf(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
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

      final String originalName = path.basenameWithoutExtension(pdfFile.path);

      final String targetPath = await FileUtils.getUniqueFilePath(
        documentName: originalName,
        extension: 'pdf',
      );

      await pdfFile.copy(targetPath);

      final imageService = ImageService();
      final File thumbnailFile = await imageService.createThumbnail(
        File(targetPath),
        size: AppConstants.thumbnailSize,
      );

      final pdfService = PdfService();
      final int pageCount = await pdfService.getPdfPageCount(targetPath);

      final tempDocument = Document(
        name: originalName,
        pdfPath: targetPath,
        pagesPaths: [targetPath],
        pageCount: pageCount,
        thumbnailPath: thumbnailFile.path,
      );

      // MOVE THE Navigator.pop(context) HERE!
      if (context.mounted) {
        Navigator.pop(context); // Close the dialog AFTER all processing
        showCompressionBottomSheet(context, tempDocument, ref);
      }
    } catch (e) {
      if (context.mounted) {
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

  static Future<void> processBatchCompression(
    BuildContext context,
    WidgetRef ref,
    List<Document> documents,
    CompressionLevel compressionLevel,
  ) async {
    if (documents.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text('Batch Compression'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing ${documents.length} documents...'),
              Text('Using cloud compression API'),
              Text('This may take a while.'),
            ],
          ),
        ),
      ),
    );

    int successCount = 0;
    int failCount = 0;
    double totalSavings = 0;
    int totalOriginalSize = 0;
    int totalCompressedSize = 0;

    final apiService = PdfCompressionApiService();

    for (final document in documents) {
      try {
        final originalFile = File(document.pdfPath);
        final originalSize = await originalFile.length();
        totalOriginalSize += originalSize;

        String compressedPdfPath = await apiService.compressPdf(
          file: originalFile,
          compressionLevel: compressionLevel,
          onProgress: null,
        );

        final compressedFile = File(compressedPdfPath);
        final compressedSize = await compressedFile.length();

        if (compressedSize >= originalSize) {
          try {
            await compressedFile.delete();
          } catch (e) {}
          failCount++;
          continue;
        }

        totalCompressedSize += compressedSize;

        String levelSuffix;
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

        final imageService = ImageService();
        final File thumbnailFile = await imageService.createThumbnail(
          compressedFile,
          size: AppConstants.thumbnailSize,
        );

        final int pageCount =
            await PdfService().getPdfPageCount(compressedPdfPath);

        final compressedDocument = Document(
          name: newName,
          pdfPath: compressedPdfPath,
          pagesPaths: [compressedPdfPath],
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
          isPasswordProtected: document.isPasswordProtected,
          password: document.password,
        );

        await ref
            .read(documentsProvider.notifier)
            .addDocument(compressedDocument);

        double savings = (originalSize - compressedSize) / originalSize * 100;
        totalSavings += savings;

        successCount++;
      } catch (e) {
        debugPrint('Error compressing document ${document.name}: $e');
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context);

      double averageSavings =
          successCount > 0 ? totalSavings / successCount : 0;
      int totalBytesSaved = totalOriginalSize - totalCompressedSize;

      String savingsMessage = '';
      if (successCount > 0) {
        savingsMessage =
            ' Avg. reduction: ${averageSavings.toStringAsFixed(1)}%, ';
        savingsMessage += 'Saved: ${FileUtils.formatFileSize(totalBytesSaved)}';
      }

      AppDialogs.showSnackBar(
        context,
        message:
            'Compression complete: $successCount successful, $failCount failed.$savingsMessage',
        type: successCount > 0 ? SnackBarType.success : SnackBarType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }
}

class _CompressionOptionsSheet extends ConsumerWidget {
  final Document? initialDocument;

  const _CompressionOptionsSheet({
    required this.initialDocument,
  });

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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 2.h,
            width: 30.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
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
                  'PDF Cloud Compressor',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (initialDocument != null)
            _buildOptionTile(
              context: context,
              icon: Icons.compress,
              title: 'Compress This PDF',
              description:
                  'Open compression tools for "${initialDocument!.name}"',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CompressionScreen(document: initialDocument!),
                  ),
                );
              },
            ),
          _buildOptionTile(
            context: context,
            icon: Icons.upload_file,
            title: 'Import and Compress PDF',
            description: 'Select a PDF file from your device to compress',
            onTap: () {
              // Navigator.pop(context);
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
              _showLibraryPdfSelector(context, ref);
            },
          ),
          _buildOptionTile(
            context: context,
            icon: Icons.tune,
            title: 'Batch Compression',
            description: 'Compress multiple PDFs at once',
            onTap: () {
              Navigator.pop(context);
              _showBatchCompressionDialog(context, ref);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Using cloud-based compression API for optimal results. Internet connection required.',
                      style: GoogleFonts.notoSerif(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  void _showLibraryPdfSelector(BuildContext context, WidgetRef ref) {
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
                  style: GoogleFonts.notoSerif(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompressionScreen(document: doc),
                    ),
                  );
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

  void _showBatchCompressionDialog(BuildContext context, WidgetRef ref) {
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
                Text(
                  'Select compression level:',
                  style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                Text(
                  'Select PDFs to compress:',
                  style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Using cloud compression API',
                          style: GoogleFonts.notoSerif(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
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
                      CompressionOptions.processBatchCompression(
                          context, ref, selectedDocs, selectedLevel);
                    },
              child: const Text('Compress'),
            ),
          ],
        ),
      ),
    );
  }
}
