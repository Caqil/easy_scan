import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'document_card.dart';
import 'scanned_documents_header.dart';

/// Widget for displaying and managing scanned documents
class ScannedDocumentsView extends StatelessWidget {
  final List<File> pages;
  final int currentIndex;
  final bool isProcessing;
  final Function(int) onPageTap;
  final Function(int) onPageRemove;
  final Function(int, int) onPagesReorder;
  final VoidCallback onAddMore;

  const ScannedDocumentsView({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.isProcessing,
    required this.onPageTap,
    required this.onPageRemove,
    required this.onPagesReorder,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with instructions
        ScannedDocumentsHeader(
          pageCount: pages.length,
          onAddMore: onAddMore,
        ),

        // Scanned pages grid
        Expanded(
          child: _buildDocumentsGrid(),
        ),
      ],
    );
  }

  Widget _buildDocumentsGrid() {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return GestureDetector(
          key: ValueKey(page.path),
          onTap: () => onPageTap(index),
          child: DocumentCard(
            page: page,
            index: index,
            onTap: () => onPageTap(index),
            onRemove: () => onPageRemove(index),
          ),
        );
      },
      onReorder: onPagesReorder,
    );
  }
}
