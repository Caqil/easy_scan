// lib/ui/screen/edit/component/pdf_edit_preview.dart
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'loading_overlay.dart';

/// A widget that displays a PDF file in the edit screen
class PdfEditPreview extends StatefulWidget {
  final File pdfFile;
  final bool isProcessing;
  final ColorScheme colorScheme;
  final String? password;

  const PdfEditPreview({
    Key? key,
    required this.pdfFile,
    required this.isProcessing,
    required this.colorScheme,
    this.password,
  }) : super(key: key);

  @override
  State<PdfEditPreview> createState() => _PdfEditPreviewState();
}

class _PdfEditPreviewState extends State<PdfEditPreview> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // PDF Viewer
        Container(
          color: widget.colorScheme.background,
          child: SfPdfViewer.file(
            widget.pdfFile,
            password:
                widget.password?.isNotEmpty == true ? widget.password : null,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
                _errorMessage = null;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
                if (details.error.contains('Password required') ||
                    details.error.contains('invalid password')) {
                  _errorMessage = 'pdf_edit_preview.incorrect_password'.tr();
                } else {
                  _errorMessage = 'pdf_edit_preview.failed_to_load_pdf'
                      .tr(args: [details.error]);
                }
              });
            },
          ),
        ),

        // Error message
        if (_errorMessage != null)
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerif(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        // Initial loading indicator
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(color: widget.colorScheme.primary),
          ),

        // Processing overlay (for operations like saving)
        LoadingOverlay(
          isVisible: widget.isProcessing,
          colorScheme: widget.colorScheme,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
