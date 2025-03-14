import 'dart:io';
import 'dart:typed_data';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:easy_scan/ui/screen/camera/component/scan_initial_view.dart';
import 'package:easy_scan/ui/screen/camera/component/scanned_documents_view.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:easy_scan/utils/permission_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
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
import 'package:path/path.dart' as path;

class EditScreen extends ConsumerStatefulWidget {
  final Document? document; // Optional parameter

  const EditScreen({
    super.key,
    this.document,
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
  bool _isEditView = true; // Controls view mode (preview vs. grid)
  late PageController _pageController;
  List<File> _pages = [];
  bool _isEditingExistingDocument = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isEditingExistingDocument = widget.document != null;

    if (_isEditingExistingDocument) {
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
    print("Scanned Pages: ${scanState.scannedPages}"); // Debugging
    if (scanState.scannedPages.isEmpty && !_isEditingExistingDocument) {
      Navigator.pop(context);
    } else if (!_isEditingExistingDocument) {
      setState(() {
        _pages = scanState.scannedPages;
      });
    }
    print("_pages after check: $_pages"); // Debugging
  }

  void _toggleViewMode() {
    setState(() {
      _isEditView = !_isEditView;
    });
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
        actions: [
          // Toggle view mode button
          IconButton(
            icon: Icon(_isEditView ? Icons.grid_view : Icons.edit),
            tooltip: _isEditView ? 'Grid View' : 'Edit View',
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: _isEditView
          ? _buildEditView(colorScheme)
          : _buildGridView(colorScheme),
    );
  }

  void _showPermissionDialog() {
    AppDialogs.showConfirmDialog(
      context,
      title: 'Permission Required',
      message:
          'Camera permission is needed to scan documents. Would you like to open app settings?',
      confirmText: 'Open Settings',
      cancelText: 'Cancel',
    ).then((confirmed) {
      if (confirmed) {
        PermissionUtils.openAppSettings();
      }
    });
  }

  Future<void> _scanDocuments() async {
    // Check for camera permission first
    final hasPermission = await PermissionUtils.hasCameraPermission();
    if (!hasPermission) {
      final granted = await PermissionUtils.requestCameraPermission();
      if (!granted) {
        _showPermissionDialog();
        return;
      }
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Get the pictures - this will show the scanner UI
      List<String> imagePaths = [];
      try {
        imagePaths = await CunningDocumentScanner.getPictures(
                isGalleryImportAllowed: true) ??
            [];
      } catch (e) {
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'Error scanning: ${e.toString()}',
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // User canceled or no images captured
      if (imagePaths.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Pre-process path validation
      List<File> validImageFiles = [];
      for (String path in imagePaths) {
        final File file = File(path);
        if (await file.exists()) {
          validImageFiles.add(file);
        }
      }

      if (validImageFiles.isEmpty) {
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'No valid images found',
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Processing loading screen
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing scanned images...')
              ],
            ),
          ),
        );
      }

      // Process all images and add to scan provider
      ref.read(scanProvider.notifier).clearPages(); // Clear any existing pages

      for (File imageFile in validImageFiles) {
        try {
          ref.read(scanProvider.notifier).addPage(imageFile);
        } catch (e) {
          // Just skip failed images to improve reliability
          print('Failed to process image: $e');
        }
      }

      // Close the processing dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
      });

      // If we have pages, navigate to edit screen
      if (ref.read(scanProvider).hasPages) {
        if (mounted) {
          _pages.isNotEmpty
              ? Navigator.pop(context)
              : AppRoutes.navigateToEdit(context);
        }
      }
    } catch (e) {
      // Close the processing dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error: ${e.toString()}',
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      // Clear any existing pages
      ref.read(scanProvider.notifier).clearPages();

      for (var image in images) {
        final File imageFile = File(image.path);
        ref.read(scanProvider.notifier).addPage(imageFile);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (ref.read(scanProvider).hasPages) {
          if (mounted) {
            _pages.isNotEmpty
                ? Navigator.pop(context)
                : AppRoutes.navigateToEdit(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(context, message: 'Error: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAppBarTitle(ColorScheme colorScheme) {
    return Text(
      _isEditingExistingDocument ? 'Edit Document' : 'New Document',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEditView(ColorScheme colorScheme) {
    return Column(
      children: [
        DocumentNameInput(
          controller: _documentNameController,
          colorScheme: colorScheme,
        ),
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
    );
  }

  Widget _buildGridView(ColorScheme colorScheme) {
    return Column(
      children: [
        // Document name input at top
        DocumentNameInput(
          controller: _documentNameController,
          colorScheme: colorScheme,
        ),

        // Grid view of scanned pages
        Expanded(
          child: ScannedDocumentsView(
            pages: _pages,
            currentIndex: _currentPageIndex,
            isProcessing: _isProcessing,
            onPageTap: (index) {
              setState(() {
                _currentPageIndex = index;
              });
              _openImageEditor();
            },
            onPageRemove: _deletePageAtIndex,
            onPagesReorder: _reorderPages,
            onAddMore: _addMorePages,
          ),
        ),

        // Save button
        SaveButton(
          onSave: _saveDocument,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  void _reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _pages.length) return;
    if (newIndex < 0 || newIndex > _pages.length) return;

    setState(() {
      final File page = _pages.removeAt(oldIndex);

      // Adjust for the shifting after removal
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      _pages.insert(newIndex, page);

      // Also update in scan provider if not editing existing document
      if (!_isEditingExistingDocument) {
        ref.read(scanProvider.notifier).reorderPages(oldIndex, newIndex);
      }
    });
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

  Future<void> _addMorePages() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ScanInitialView(
            onScanPressed: _scanDocuments,
            onImportPressed: _pickImages,
          ),
        ),
      ),
    );
    if (!mounted) return;

    final scanState = ref.read(scanProvider);
    if (scanState.hasPages) {
      // Get newly scanned pages
      final newPages = List<File>.from(scanState.scannedPages);

      // Add new pages to our current pages list
      setState(() {
        _pages.addAll(newPages);
      });

      // Always clear the scan provider since we've transferred the pages to our local state
      ref.read(scanProvider.notifier).clearPages();

      // Show success message
      AppDialogs.showSnackBar(
        context,
        message: 'Added ${newPages.length} new page(s)',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _openImageEditor() async {
    if (_pages.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final File currentPage = _pages[_currentPageIndex];
      final Uint8List imageBytes = await currentPage.readAsBytes();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.memory(
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                // Write the new bytes to the file
                final File editedFile = File(currentPage.path);
                await editedFile.writeAsBytes(bytes);

                // Clear image cache to force refresh
                imageCache.clear();
                imageCache.clearLiveImages();

                // Update our state with the edited file
                setState(() {
                  _pages[_currentPageIndex] = editedFile;
                });

                // Also update in scan provider if not editing existing document
                if (!_isEditingExistingDocument) {
                  ref
                      .read(scanProvider.notifier)
                      .updatePageAt(_currentPageIndex, editedFile);
                }

                Navigator.pop(context);
              },
            ),
            imageBytes,
          ),
        ),
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Error editing image: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
      String filePath;
      int pageCount = _pages.length;
      String fileExtension;

      // Generate thumbnail for the first page
      final File thumbnailFile = await _imageService.createThumbnail(
        _pages[0],
        size: AppConstants.thumbnailSize,
      );

      // Check file type of the first page to determine processing method
      fileExtension =
          path.extension(_pages[0].path).toLowerCase().replaceAll('.', '');

      // Handle different file types
      if (_pages.length == 1 &&
          (fileExtension == 'txt' ||
              fileExtension == 'html' ||
              fileExtension == 'md' ||
              fileExtension == 'rtf')) {
        // For text files, just copy the file if it's a single page
        filePath = await _copyFile(_pages[0], documentName, fileExtension);
        pageCount = 1;
      } else if (_pages.length == 1 &&
          (fileExtension == 'jpg' ||
              fileExtension == 'jpeg' ||
              fileExtension == 'png' ||
              fileExtension == 'webp' ||
              fileExtension == 'gif')) {
        // For single image files, just copy or optimize if requested
        filePath =
            await _processSingleImage(_pages[0], documentName, fileExtension);
        pageCount = 1;
      } else {
        // For multiple pages or mixed content, convert to PDF
        filePath = await _pdfService.createPdfFromImages(
          _pages,
          documentName,
        );

        // Get number of pages for PDF
        pageCount = await _pdfService.getPdfPageCount(filePath);
        fileExtension = 'pdf';
      }

      if (_isEditingExistingDocument) {
        // Update existing document
        final updatedDocument = widget.document!.copyWith(
          name: documentName,
          pdfPath: filePath,
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
            type: SnackBarType.success,
          );
        }
      } else {
        // Create new document model
        final document = Document(
          name: documentName,
          pdfPath: filePath, // Main file path (PDF or original format)
          pagesPaths: _pages.map((file) => file.path).toList(),
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
        );

        // Save document to storage
        await ref.read(documentsProvider.notifier).addDocument(document);

        // Show success message with appropriate file type
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message:
                'Document saved successfully as ${fileExtension.toUpperCase()}',
            type: SnackBarType.success,
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
          type: SnackBarType.error,
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

// Helper to copy a single file with a new name
  Future<String> _copyFile(
      File sourceFile, String documentName, String extension) async {
    final String targetPath = await FileUtils.getUniqueFilePath(
      documentName: documentName,
      extension: extension,
    );

    // Copy the file
    final File newFile = await sourceFile.copy(targetPath);
    return newFile.path;
  }

// Helper to process a single image (with optional optimization)
  Future<String> _processSingleImage(
      File imageFile, String documentName, String extension) async {
    final String targetPath = await FileUtils.getUniqueFilePath(
      documentName: documentName,
      extension: extension,
    );

    try {
      // For now, just copy the file
      // You could add optimization here if needed in the future
      final File newFile = await imageFile.copy(targetPath);
      return newFile.path;
    } catch (e) {
      // If copying fails, try to read and write the bytes directly
      final bytes = await imageFile.readAsBytes();
      final File newFile = File(targetPath);
      await newFile.writeAsBytes(bytes);
      return newFile.path;
    }
  }
}
