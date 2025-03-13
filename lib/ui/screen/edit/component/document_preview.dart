import 'dart:io';
import 'package:flutter/material.dart';

import 'document_page_preview.dart';
import 'loading_overlay.dart';
import 'page_controls.dart';
import 'page_navigation_buttons.dart';

/// Container widget for document preview with all controls
class DocumentPreview extends StatelessWidget {
  final List<File> pages;
  final int currentPageIndex;
  final PageController pageController;
  final bool isProcessing;
  final ColorScheme colorScheme;
  final Function(int) onPageChanged;
  final Function(int) onDeletePage;

  const DocumentPreview({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.pageController,
    required this.isProcessing,
    required this.colorScheme,
    required this.onPageChanged,
    required this.onDeletePage,
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
          // Document page view
          PageView.builder(
            controller: pageController,
            itemCount: pages.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return DocumentPagePreview(page: pages[index]);
            },
          ),

          // Page navigation buttons
          if (pages.length > 1)
            PageNavigationButtons(
              currentPageIndex: currentPageIndex,
              pageCount: pages.length,
              pageController: pageController,
            ),

          // Page counter and delete controls
          PageControls(
            currentPageIndex: currentPageIndex,
            pageCount: pages.length,
            onDeletePage: onDeletePage,
          ),

          // Loading overlay
          LoadingOverlay(
            isVisible: isProcessing,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}
