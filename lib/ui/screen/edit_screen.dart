import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/routes.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/image_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../common/app_bar.dart';
import '../common/dialogs.dart';

class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({super.key});

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  final TextEditingController _documentNameController = TextEditingController(
      text: 'Scan ${DateTime.now().toString().substring(0, 10)}');
  final PdfService _pdfService = PdfService();
  final ImageService _imageService = ImageService();
  int _currentPageIndex = 0;
  bool _isProcessing = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfEmpty();
    });
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _checkIfEmpty() {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty) {
      // No pages to edit, go back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final pages = scanState.scannedPages;
    final colorScheme = Theme.of(context).colorScheme;

    if (pages.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: CustomAppBar(
        title: Text(
          'Edit Document',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Document name input (moved to top for better UX)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _documentNameController,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Document Name',
                labelStyle: TextStyle(color: colorScheme.primary),
                prefixIcon: Icon(Icons.description_outlined,
                    color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
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
                  // Document preview
                  PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Future enhancement: Zoom in on image
                        },
                        child: Container(
                          color: Colors.grey[900],
                          padding: const EdgeInsets.all(8.0),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: Center(
                              child: Image.file(
                                pages[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Page navigation buttons
                  if (pages.length > 1)
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous page button
                          if (_currentPageIndex > 0)
                            GestureDetector(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 40,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),

                          // Next page button
                          if (_currentPageIndex < pages.length - 1)
                            GestureDetector(
                              onTap: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Page counter and controls
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Delete button
                        GestureDetector(
                          onTap: () => _deletePageAtIndex(_currentPageIndex),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Page counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.copy,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_currentPageIndex + 1} / ${pages.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Loading indicator
                  if (_isProcessing)
                    Container(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _saveDocument,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save as PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _deletePageAtIndex(int index) {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.length <= 1) {
      // Can't delete the only page
      AppDialogs.showSnackBar(
        context,
        message: 'Cannot delete the only page. Add more pages or cancel.',
      );
      return;
    }

    AppDialogs.showConfirmDialog(
      context,
      title: 'Delete Page',
      message: 'Are you sure you want to delete this page?',
      confirmText: 'Delete',
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed) {
        ref.read(scanProvider.notifier).removePage(index);

        // Adjust current page index if needed
        if (_currentPageIndex >= ref.read(scanProvider).scannedPages.length) {
          setState(() {
            _currentPageIndex = ref.read(scanProvider).scannedPages.length - 1;
          });
        }
      }
    });
  }

  Future<void> _saveDocument() async {
    if (_documentNameController.text.trim().isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'Please enter a document name',
      );
      return;
    }

    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'No pages to save',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create a clean document name
      final String documentName = _documentNameController.text.trim();

      // Generate thumbnails for the first page
      final File thumbnailFile = await _imageService.createThumbnail(
        scanState.scannedPages[0],
        size: AppConstants.thumbnailSize,
      );

      // Create PDF from scanned images
      final String pdfPath = await _pdfService.createPdfFromImages(
        scanState.scannedPages,
        documentName,
      );

      // Get number of pages
      final int pageCount = await _pdfService.getPdfPageCount(pdfPath);

      // Create document model
      final document = Document(
        name: documentName,
        pdfPath: pdfPath,
        pagesPaths: scanState.scannedPages.map((file) => file.path).toList(),
        pageCount: pageCount,
        thumbnailPath: thumbnailFile.path,
      );

      // Save document to storage
      await ref.read(documentsProvider.notifier).addDocument(document);

      // Show success message
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Document saved successfully',
      );

      // Clear scan state
      ref.read(scanProvider.notifier).clearPages();

      // Navigate back to home
      // ignore: use_build_context_synchronously
      AppRoutes.navigateToHome(context);
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error saving document: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
