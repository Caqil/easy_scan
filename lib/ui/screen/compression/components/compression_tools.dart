import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/compression/components/compression_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfCompressionUtils {
  /// Show compression options from anywhere in the app
  static void showCompressionOptions(
    BuildContext context,
    WidgetRef ref, {
    Document? initialDocument,
  }) {
    CompressionOptions.showCompressionOptions(
      context,
      ref,
      initialDocument: initialDocument,
    );
  }

  static void showQuickCompressionDialog(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) {
    if (document.pdfPath.toLowerCase().endsWith('.pdf')) {
      // Show options in dialog
      CompressionOptions.showCompressionOptions(
        context,
        ref,
        initialDocument: document,
      );
    } else {
      // Not a PDF file
      AppDialogs.showSnackBar(
        context,
        message: 'compression.only_pdf_files'.tr(),
        type: SnackBarType.warning,
      );
    }
  }
}
