import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/routes.dart';
import '../../../models/document.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/scan_provider.dart';
import '../../../services/image_service.dart';
import '../../../services/pdf_service.dart';
import '../../../utils/constants.dart';
import '../../common/app_bar.dart';
import '../../common/dialogs.dart';
import 'component/document_name_input.dart';
import 'component/document_preview.dart';
import 'component/save_button.dart';

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
        title: _buildAppBarTitle(colorScheme),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Document name input
          DocumentNameInput(
            controller: _documentNameController,
            colorScheme: colorScheme,
          ),

          // Document preview area
          Expanded(
            child: DocumentPreview(
              pages: pages,
              currentPageIndex: _currentPageIndex,
              pageController: _pageController,
              isProcessing: _isProcessing,
              colorScheme: colorScheme,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              onDeletePage: _deletePageAtIndex,
            ),
          ),

          // Save button
          SaveButton(
            onSave: _saveDocument,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(ColorScheme colorScheme) {
    return Text(
      'Edit Document',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
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
