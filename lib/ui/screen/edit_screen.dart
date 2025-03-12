import 'dart:io';
import 'package:flutter/foundation.dart';
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
import '../common/loading.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  int _currentPageIndex = 0;
  bool _isProcessing = false;
  String _processingMessage = '';
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfEmpty();
    });
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _isMounted = false;
    super.dispose();
  }

  void _checkIfEmpty() {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty) {
      // No pages to edit, go back
      Navigator.pop(context);
    }
  }

  void _updateProcessingState(bool isProcessing, [String message = '']) {
    if (_isMounted) {
      setState(() {
        _isProcessing = isProcessing;
        _processingMessage = message;
      });
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
            onPressed: _isProcessing ? null : _addMorePages,
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
                    return InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20.0),
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Center(
                        child: Image.file(
                          pages[index],
                          fit: BoxFit.contain,
                          cacheHeight:
                              MediaQuery.of(context).size.height.toInt(),
                          cacheWidth: MediaQuery.of(context).size.width.toInt(),
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
                    color: Colors.black54,
                    child: Center(
                      child: LoadingIndicator(message: _processingMessage),
                    ),
                  ),
              ],
            ),
          ),

          // Editing tools
          if (!_isProcessing)
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
                          if (!_isProcessing) {
                            setState(() {
                              _currentPageIndex = index;
                            });
                          }
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
                                cacheWidth:
                                    120, // Lower resolution for thumbnails
                                cacheHeight: 160,
                              ),
                              if (!_isProcessing)
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
                  enabled: !_isProcessing,
                ),

                const SizedBox(height: 16),

                // Save button
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _saveDocument,
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
          _updateProcessingState(true, 'Processing ${images.length} images...');

          // Process images in batches to avoid UI freezes
          for (int i = 0; i < images.length; i++) {
            _updateProcessingState(
                true, 'Processing image ${i + 1} of ${images.length}...');
            final File imageFile = File(images[i].path);

            // Use compute for heavy processing to avoid UI freezes
            final File processedFile = await compute(
              _processImageIsolate,
              {
                'imagePath': imageFile.path,
                'colorMode': scanState.settings.colorMode.index,
                'quality': scanState.settings.quality
              },
            );

            ref.read(scanProvider.notifier).addPage(processedFile);
          }
        }
      } catch (e) {
        // Show error
        if (_isMounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'Error importing images: ${e.toString()}',
          );
        }
      } finally {
        _updateProcessingState(false);
      }
    }
  }

  // Static method to process image in isolate
  static Future<File> _processImageIsolate(Map<String, dynamic> params) async {
    final String imagePath = params['imagePath'];
    final ColorMode colorMode = ColorMode.values[params['colorMode']];
    final int quality = params['quality'];

    final ImageService imageService = ImageService();
    return await imageService.enhanceImage(
      File(imagePath),
      colorMode,
      quality: quality,
    );
  }

  void _changeColorMode(ColorMode colorMode) async {
    final scanState = ref.read(scanProvider);
    if (scanState.settings.colorMode == colorMode) return;

    _updateProcessingState(true, 'Applying color mode...');

    try {
      // Update settings
      ref.read(scanProvider.notifier).updateSettings(
            scanState.settings.copyWith(colorMode: colorMode),
          );

      // Get current page
      final File currentPage = scanState.scannedPages[_currentPageIndex];

      // Apply new color mode using compute to avoid UI freezes
      final File processedFile = await compute(
        _processImageIsolate,
        {
          'imagePath': currentPage.path,
          'colorMode': colorMode.index,
          'quality': scanState.settings.quality
        },
      );

      // Update the page
      ref
          .read(scanProvider.notifier)
          .updatePageAt(_currentPageIndex, processedFile);
    } catch (e) {
      // Show error
      if (_isMounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error applying color mode: ${e.toString()}',
        );
      }
    } finally {
      _updateProcessingState(false);
    }
  }

  Future<void> _rotateCurrentPage(bool counterclockwise) async {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty) return;

    _updateProcessingState(true, 'Rotating image...');

    try {
      final File currentPage = scanState.scannedPages[_currentPageIndex];

      // Use compute for rotation to avoid UI freezes
      final File rotatedFile = await compute(
        _rotateImageIsolate,
        {
          'imagePath': currentPage.path,
          'counterclockwise': counterclockwise,
        },
      );

      // Update the page
      ref
          .read(scanProvider.notifier)
          .updatePageAt(_currentPageIndex, rotatedFile);
    } catch (e) {
      // Show error
      if (_isMounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error rotating image: ${e.toString()}',
        );
      }
    } finally {
      _updateProcessingState(false);
    }
  }

  // Static method to rotate image in isolate
  static Future<File> _rotateImageIsolate(Map<String, dynamic> params) async {
    final String imagePath = params['imagePath'];
    final bool counterclockwise = params['counterclockwise'];

    final ImageService imageService = ImageService();
    return await imageService.rotateImage(
      File(imagePath),
      counterclockwise,
    );
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
      if (confirmed && _isMounted) {
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

    _updateProcessingState(true, 'Preparing to save document...');

    try {
      // Create a clean document name
      final String documentName = _documentNameController.text.trim();

      // Run thumbnail generation in compute
      _updateProcessingState(true, 'Generating thumbnail...');
      final thumbnailResult = await compute(
        _createThumbnailIsolate,
        {
          'imagePath': scanState.scannedPages[0].path,
          'size': AppConstants.thumbnailSize,
        },
      );

      // Create PDF from scanned images
      _updateProcessingState(true, 'Creating PDF file...');
      final pdfPath = await compute(
        _createPdfIsolate,
        {
          'imagePaths':
              scanState.scannedPages.map((file) => file.path).toList(),
          'documentName': documentName,
        },
      );

      // Get number of pages
      _updateProcessingState(true, 'Finalizing document...');
      final int pageCount = await _pdfService.getPdfPageCount(pdfPath);

      // Create document model
      final document = Document(
        name: documentName,
        pdfPath: pdfPath,
        pagesPaths: scanState.scannedPages.map((file) => file.path).toList(),
        pageCount: pageCount,
        thumbnailPath: thumbnailResult,
      );

      // Save document to storage
      await ref.read(documentsProvider.notifier).addDocument(document);

      // Show success message
      if (_isMounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Document saved successfully!',
        );

        // Clear scan state
        ref.read(scanProvider.notifier).clearPages();

        // Navigate back to home
        AppRoutes.navigateToHome(context);
      }
    } catch (e) {
      // Show error
      if (_isMounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error saving document: ${e.toString()}',
        );
      }
    } finally {
      _updateProcessingState(false);
    }
  }

  // Static method to create thumbnail in isolate
  static Future<String> _createThumbnailIsolate(
      Map<String, dynamic> params) async {
    final String imagePath = params['imagePath'];
    final int size = params['size'];

    final ImageService imageService = ImageService();
    final File thumbnailFile = await imageService.createThumbnail(
      File(imagePath),
      size: size,
    );

    return thumbnailFile.path;
  }

  // Static method to create PDF in isolate
  static Future<String> _createPdfIsolate(Map<String, dynamic> params) async {
    final List<String> imagePaths = params['imagePaths'];
    final String documentName = params['documentName'];

    final PdfService pdfService = PdfService();
    final List<File> imageFiles = imagePaths.map((path) => File(path)).toList();

    return await pdfService.createPdfFromImages(
      imageFiles,
      documentName,
    );
  }
}
