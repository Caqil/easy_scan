// Updated document_preview.dart with conditional PDF rendering
import 'dart:io';
import 'package:flutter/material.dart';

import 'document_page_preview.dart';
import 'loading_overlay.dart';
import 'page_controls.dart';
import 'page_navigation_buttons.dart';
import 'pdf_edit_preview.dart'; // Import the new PDF preview widget

class DocumentPreview extends StatelessWidget {
  final List<File> pages;
  final int currentPageIndex;
  final PageController pageController;
  final bool isProcessing;
  final ColorScheme colorScheme;
  final Function(int) onPageChanged;
  final Function(int) onDeletePage;
  final bool isPdfPreviewMode; // Flag for PDF preview mode
  final bool isImageOnlyDocument; // New flag for image-only documents
  final String? password; // Password for PDF viewing

  const DocumentPreview({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.pageController,
    required this.isProcessing,
    required this.colorScheme,
    required this.onPageChanged,
    required this.onDeletePage,
    this.isPdfPreviewMode = false,
    this.isImageOnlyDocument = false, // Add this parameter
    this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Check if we should show PDF preview or image preview
          if (isPdfPreviewMode && pages.isNotEmpty)
            // PDF Preview Mode
            PdfEditPreview(
              pdfFile: pages[0], // We only have the PDF file in pages[0]
              isProcessing: isProcessing,
              colorScheme: colorScheme,
              password: password,
            )
          else
            // Image Preview Mode - Document page view
            PageView.builder(
              controller: pageController,
              itemCount: pages.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return DocumentPagePreview(page: pages[index]);
              },
            ),

          // Only show navigation buttons for multi-page image previews
          if ((!isPdfPreviewMode || isImageOnlyDocument) && pages.length > 1)
            PageNavigationButtons(
              currentPageIndex: currentPageIndex,
              pageCount: pages.length,
              pageController: pageController,
            ),

          // Page counter and delete controls (for image previews or image-only documents)
          if (!isPdfPreviewMode || isImageOnlyDocument)
            PageControls(
              currentPageIndex: currentPageIndex,
              pageCount: pages.length,
              onDeletePage: onDeletePage,
            ),

          // Processing overlay is handled within PdfEditPreview for PDF mode
          if (!isPdfPreviewMode)
            LoadingOverlay(
              isVisible: isProcessing,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }
}
