import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/main.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentPagePreview extends StatelessWidget {
  final File page;

  const DocumentPagePreview({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    // Get file extension to determine how to render it
    final fileExtension = path.extension(page.path).toLowerCase();

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8.0),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Center(
          child: _buildPreviewByFileType(fileExtension),
        ),
      ),
    );
  }

  Widget _buildPreviewByFileType(String fileExtension) {
    // Check if the file is a PDF
    if (fileExtension == '.pdf') {
      return _buildPdfPreview();
    }
    // For image files (jpg, jpeg, png, etc.)
    else {
      return _buildImagePreview();
    }
  }

  Widget _buildImagePreview() {
    return Image.file(
      page,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        logger.error('Error loading image: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              AutoSizeText(
                'document_preview.unable_to_display_image'
                    .tr(), // Localized string
                style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700, color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfPreview() {
    return SfPdfViewer.file(
      page,
      enableDoubleTapZooming: true,
      canShowScrollHead: false,
      pageSpacing: 0,
      enableTextSelection: false,
      interactionMode: PdfInteractionMode.pan,
      onPageChanged: (PdfPageChangedDetails details) {
        // You can add logic here if needed when PDF page changes
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        logger.error('Error loading PDF: ${details.error}');
      },
    );
  }
}
