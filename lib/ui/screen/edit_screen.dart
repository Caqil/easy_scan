import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/routes.dart';
import '../../models/document.dart';
import '../../models/scan_settings.dart';
import '../../providers/document_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/image_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../common/app_bar.dart';
import '../common/dialogs.dart';
import '../widget/edit_tools.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  int _currentPageIndex = 0;
  bool _isProcessing = false;

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

    if (pages.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Edit Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _addMorePages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview with page indicator
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
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
                      child: Center(
                        child: Image.file(
                          pages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                // Page counter
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentPageIndex + 1} / ${pages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Loading indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),

          // Editing tools
          EditTools(
            currentColorMode: scanState.settings.colorMode,
            onColorModeChanged: _changeColorMode,
            onRotateLeft: () => _rotateCurrentPage(true),
            onRotateRight: () => _rotateCurrentPage(false),
            onCrop: _cropCurrentPage,
            onFilter: _showFilterOptions,
          ),

          // Divider
          const Divider(height: 1),

          // Controls for page management
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Thumbnails
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentPageIndex = index;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentPageIndex == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              width: _currentPageIndex == index ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                pages[index],
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _deletePageAtIndex(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Document name input
                TextField(
                  controller: _documentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Document Name',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Save button
                ElevatedButton.icon(
                  onPressed: _saveDocument,
                  icon: const Icon(Icons.save),
                  label: const Text('Save as PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMorePages() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pick from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'camera') {
      // Go back to camera screen
      // We keep the already scanned pages in the provider
      Navigator.pop(context);
      AppRoutes.navigateToCamera(context);
    } else if (result == 'gallery') {
      final scanState = ref.read(scanProvider);

      try {
        final List<XFile> images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _isProcessing = true;
          });

          for (var image in images) {
            final File imageFile = File(image.path);
            final File processedFile = await _imageService.enhanceImage(
              imageFile,
              scanState.settings.colorMode,
              quality: scanState.settings.quality,
            );
            ref.read(scanProvider.notifier).addPage(processedFile);
          }
        }
      } catch (e) {
        // Show error
        // ignore: use_build_context_synchronously
        AppDialogs.showSnackBar(
          context,
          message: 'Error importing images: ${e.toString()}',
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _changeColorMode(ColorMode colorMode) async {
    final scanState = ref.read(scanProvider);
    if (scanState.settings.colorMode == colorMode) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Update settings
      ref.read(scanProvider.notifier).updateSettings(
            scanState.settings.copyWith(colorMode: colorMode),
          );

      // Get current page
      final File currentPage = scanState.scannedPages[_currentPageIndex];

      // Apply new color mode
      final File processedFile = await _imageService.enhanceImage(
        currentPage,
        colorMode,
        quality: scanState.settings.quality,
      );

      // Update the page
      ref
          .read(scanProvider.notifier)
          .updatePageAt(_currentPageIndex, processedFile);
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error applying color mode: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rotateCurrentPage(bool counterclockwise) async {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final File currentPage = scanState.scannedPages[_currentPageIndex];
      final File rotatedFile = await _imageService.rotateImage(
        currentPage,
        counterclockwise,
      );

      // Update the page
      ref
          .read(scanProvider.notifier)
          .updatePageAt(_currentPageIndex, rotatedFile);
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error rotating image: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _cropCurrentPage() {
    // In a real app, this would open a cropping interface
    // For now, just show a message
    AppDialogs.showSnackBar(
      context,
      message: 'Cropping functionality would be implemented here',
    );
  }

  void _showFilterOptions() {
    // In a real app, this would show various filter options
    // For now, just show a message
    AppDialogs.showSnackBar(
      context,
      message: 'Filter options would be shown here',
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
