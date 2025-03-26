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
import 'package:scanpro/utils/screen_util_extensions.dart';
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

      final apiService = ref.read(pdfCompressionApiServiceProvider);
      String compressedPdfPath = await apiService.compressPdf(
        file: originalFile,
        compressionLevel: compressionLevel,
        onProgress: null,
      );

      // Get appropriate level name for the file suffix
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
                    fontSize: 18.adaptiveSp,
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
                        fontSize: 12.adaptiveSp,
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
}
