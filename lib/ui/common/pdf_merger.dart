import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_merger_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/merger/components/merge_option_shhet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfMerger {
  static void showMergeOptions(
    BuildContext context,
    WidgetRef ref, {
    Document? initialDocument,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MergeOptionsSheet(
        initialDocument: initialDocument,
        ref: ref,
      ),
    );
  }

  /// Quick merge multiple PDFs - meant for integration with other components
  static Future<void> quickMergePdfs(
    BuildContext context,
    WidgetRef ref,
    List<Document> documents,
    String outputName,
  ) async {
    if (documents.length < 2) {
      AppDialogs.showSnackBar(
        context,
        message: 'At least 2 PDFs are required for merging',
        type: SnackBarType.warning,
      );
      return;
    }

    try {
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
              Text('Merging PDFs...'),
            ],
          ),
        ),
      );

      // Perform merge
      final pdfMergerService = ref.read(pdfMergerServiceProvider);
      final mergedDocument = await pdfMergerService.mergeDocuments(
        documents,
        outputName,
      );

      // Add the merged document to the library
      await ref.read(documentsProvider.notifier).addDocument(mergedDocument);

      // Close the loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'PDFs merged successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'Error merging PDFs: $e',
          type: SnackBarType.error,
        );
      }
    }
  }
}
