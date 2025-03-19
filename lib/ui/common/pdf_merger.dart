import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_merger_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/merger/components/merge_option_shhet.dart';
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
        message: 'messages.at_least_two_pdfs_required'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('merging_pdfs'.tr()),
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
          message: 'messages.pdfs_merged_successfully'.tr(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(
          context,
          message: 'messages.error_merging_pdfs'
              .tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    }
  }
}
