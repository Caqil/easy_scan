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
  final Document document;

  const EditScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  late TextEditingController _documentNameController;
  final PdfService _pdfService = PdfService();
  final ImageService _imageService = ImageService();
  int _currentPageIndex = 0;
  bool _isProcessing = false;
  late PageController _pageController;
  List<File> _pages = [];
  bool _isEditingExistingDocument = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isEditingExistingDocument = widget.document != null;

    if (_isEditingExistingDocument) {
      // Initialize with existing document data
      _documentNameController =
          TextEditingController(text: widget.document!.name);
      _loadExistingDocument();
    } else {
      // Initialize with default name for new document
      _documentNameController = TextEditingController(
          text: 'Scan ${DateTime.now().toString().substring(0, 10)}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfEmpty();
      });
    }
  }

  Future<void> _loadExistingDocument() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Load pages from the document
      final document = widget.document!;
      _pages = [];

      for (String path in document.pagesPaths) {
        final file = File(path);
        if (await file.exists()) {
          _pages.add(file);
        }
      }

      if (_pages.isEmpty) {
        throw Exception('No valid pages found in document');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error loading document: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _checkIfEmpty() {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty && !_isEditingExistingDocument) {
      // No pages to edit, go back
      Navigator.pop(context);
    } else if (!_isEditingExistingDocument) {
      // Load pages from scan provider
      setState(() {
        _pages = scanState.scannedPages;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_pages.isEmpty && _isProcessing) {
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
              pages: _pages,
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
      _isEditingExistingDocument ? 'Edit Document' : 'New Document',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _deletePageAtIndex(int index) {
    if (_pages.length <= 1) {
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
        setState(() {
          _pages.removeAt(index);

          // If not editing existing document, also update scan provider
          if (!_isEditingExistingDocument) {
            ref.read(scanProvider.notifier).removePage(index);
          }

          // Adjust current page index if needed
          if (_currentPageIndex >= _pages.length) {
            _currentPageIndex = _pages.length - 1;
          }
        });
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

    if (_pages.isEmpty) {
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
        _pages[0],
        size: AppConstants.thumbnailSize,
      );

      // Create PDF from images
      final String pdfPath = await _pdfService.createPdfFromImages(
        _pages,
        documentName,
      );

      // Get number of pages
      final int pageCount = await _pdfService.getPdfPageCount(pdfPath);

      if (_isEditingExistingDocument) {
        // Update existing document
        final updatedDocument = widget.document!.copyWith(
          name: documentName,
          pdfPath: pdfPath,
          pagesPaths: _pages.map((file) => file.path).toList(),
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
          modifiedAt: DateTime.now(),
        );

        // Save updated document to storage
        await ref
            .read(documentsProvider.notifier)
            .updateDocument(updatedDocument);

        // Show success message
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'Document updated successfully',
          );
        }
      } else {
        // Create new document model
        final document = Document(
          name: documentName,
          pdfPath: pdfPath,
          pagesPaths: _pages.map((file) => file.path).toList(),
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
        );

        // Save document to storage
        await ref.read(documentsProvider.notifier).addDocument(document);

        // Show success message
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'Document saved successfully',
          );
        }

        // Clear scan state
        ref.read(scanProvider.notifier).clearPages();
      }

      // Navigate back to home
      if (mounted) {
        AppRoutes.navigateToHome(context);
      }
    } catch (e) {
      // Show error
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error saving document: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
