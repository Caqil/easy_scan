import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_service.dart';
import 'package:scanpro/services/pdf_compression_api_service.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/compression/compression_screen.dart';
import 'package:scanpro/ui/screen/compression/components/compression_bottomsheet.dart';
import 'package:scanpro/ui/widget/option_tile.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
                Text('compression.compressing_pdf'.tr()),
                Text('compression.using_cloud_compression'.tr()),
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
          levelSuffix = 'compression.lightly_compressed_suffix'.tr();
          break;
        case CompressionLevel.medium:
          levelSuffix = 'compression.compressed_suffix'.tr();
          break;
        case CompressionLevel.high:
          levelSuffix = 'compression.highly_compressed_suffix'.tr();
          break;
        case CompressionLevel.maximum:
          levelSuffix = 'compression.max_compressed_suffix'.tr();
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
            message: 'compression.could_not_compress_further'.tr(),
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
          message: 'compression.pdf_compressed_success'
              .tr(namedArgs: {'percentage': compressionPercentage}),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'compression.error_compressing_pdf'
              .tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }

  static Future<void> importAndCompressPdf(
    BuildContext context,
    WidgetRef ref,
  ) async {
    logger.info('1. Starting importAndCompressPdf');

    // Store navigator state globally before popping
    final navigatorState = Navigator.of(context);

    // First close the options sheet
    logger.info('2. Attempting to close options sheet');
    navigatorState.pop();

    try {
      logger.info('3. Showing file picker');
      // Show file picker after the sheet is closed
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
        throw Exception('compression.file_does_not_exist'.tr());
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

      navigatorState.push(
        MaterialPageRoute(
          builder: (context) => CompressionScreen(document: tempDocument),
        ),
      );
      logger.info('28. Navigation to CompressionScreen completed');
    } catch (e) {
      logger.error('ERROR: Exception in importAndCompressPdf: $e');
      // We can't use the original context for the snackbar since it's no longer mounted
      // Instead, we could use a global key for scaffold, but for simplicity:
      logger.error('Cannot show error snackbar: $e');
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
          title: Text('compression.batch_compression'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('compression.processing_documents'
                  .tr(namedArgs: {'count': documents.length.toString()})),
              Text('compression.using_cloud_compression'.tr()),
              Text('compression.may_take_a_while'.tr()),
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
            levelSuffix = 'compression.lightly_compressed_suffix'.tr();
            break;
          case CompressionLevel.medium:
            levelSuffix = 'compression.compressed_suffix'.tr();
            break;
          case CompressionLevel.high:
            levelSuffix = 'compression.highly_compressed_suffix'.tr();
            break;
          case CompressionLevel.maximum:
            levelSuffix = 'compression.max_compressed_suffix'.tr();
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
        logger.error('Error compressing document ${document.name}: $e');
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
        savingsMessage = 'compression.avg_reduction'
            .tr(namedArgs: {'percentage': averageSavings.toStringAsFixed(1)});
        savingsMessage += 'compression.saved_size'
            .tr(namedArgs: {'size': FileUtils.formatFileSize(totalBytesSaved)});
      }

      AppDialogs.showSnackBar(
        context,
        message: 'compression.batch_complete'.tr(namedArgs: {
          'success': successCount.toString(),
          'fail': failCount.toString(),
          'savings': savingsMessage
        }),
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
                AutoSizeText(
                  'compression.pdf_cloud_compressor'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (initialDocument != null)
            OptionTile(
              icon: Icons.compress,
              title: 'compression.compress_this_pdf'.tr(),
              description: 'compression.open_tools_for'
                  .tr(namedArgs: {'name': initialDocument!.name}),
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
          OptionTile(
            icon: Icons.upload_file,
            title: 'compression.import_and_compress'.tr(),
            description: 'compression.select_pdf_to_compress'.tr(),
            onTap: () {
              CompressionOptions.importAndCompressPdf(context, ref);
            },
          ),
          OptionTile(
            icon: Icons.subject,
            title: 'compression.select_from_library'.tr(),
            description: 'compression.choose_from_library'.tr(),
            onTap: () {
              Navigator.pop(context);
              _showLibraryPdfSelector(context, ref);
            },
          ),
          OptionTile(
            icon: Icons.tune,
            title: 'compression.batch_compression'.tr(),
            description: 'compression.compress_multiple'.tr(),
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
                    child: AutoSizeText(
                      'compression.cloud_compression_info'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
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

  void _showLibraryPdfSelector(BuildContext context, WidgetRef ref) {
    final allDocuments = ref.read(documentsProvider);
    final pdfDocs = allDocuments.where((doc) {
      final extension = path.extension(doc.pdfPath).toLowerCase();
      return extension == '.pdf';
    }).toList();

    if (pdfDocs.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'compression.no_pdfs_found'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    pdfDocs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('compression.select_pdf_to_compress'.tr()),
        content: SizedBox(
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
                  'compression.page_count'
                      .tr(namedArgs: {'count': doc.pageCount.toString()}),
                  style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700, fontSize: 12),
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
            child: Text('common.cancel'.tr()),
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
        message: 'compression.no_pdfs_found'.tr(),
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
          title: Text('compression.batch_compression'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'compression.select_compression_level'.tr(),
                    style: GoogleFonts.slabo27px(fontWeight: FontWeight.bold),
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
                        child: Text('compression.low_best_quality'.tr()),
                      ),
                      DropdownMenuItem(
                        value: CompressionLevel.medium,
                        child: Text('compression.medium_balanced'.tr()),
                      ),
                      DropdownMenuItem(
                        value: CompressionLevel.high,
                        child: Text('compression.high_smaller_size'.tr()),
                      ),
                      DropdownMenuItem(
                        value: CompressionLevel.maximum,
                        child: Text('compression.maximum_smallest_size'.tr()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'compression.select_pdfs_to_compress'.tr(),
                    style: GoogleFonts.slabo27px(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200.h,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: pdfDocs.length,
                      itemBuilder: (context, index) {
                        final doc = pdfDocs[index];
                        final isSelected = selectedDocs.contains(doc);
                        return CheckboxListTile(
                          title: AutoSizeText(
                            doc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: AutoSizeText('compression.page_count'.tr(
                              namedArgs: {'count': doc.pageCount.toString()})),
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
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
                            'compression.using_cloud_compression'.tr(),
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: selectedDocs.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      CompressionOptions.processBatchCompression(
                          context, ref, selectedDocs, selectedLevel);
                    },
              child: Text('compression.compress'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
