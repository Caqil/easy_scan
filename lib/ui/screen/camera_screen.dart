import 'dart:io';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../config/routes.dart';
import '../../providers/scan_provider.dart';
import '../../services/pdf_service.dart';
import '../common/app_bar.dart';
import '../common/dialogs.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final PdfService _pdfService = PdfService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _scanSuccessful = false;
  String? _pdfPath;
  File? _thumbnailImage;
  int _currentPageIndex = 0;
  bool _isProcessing = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _scanDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _scanSuccessful = false;
        _pdfPath = null;
        _thumbnailImage = null;
      });

      // Define the output path for the scanned image
      final directory = await getTemporaryDirectory();
      String outputPath =
          '${directory.path}/scanned_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Use the edge_detection plugin to scan the document
      bool success = await EdgeDetection.detectEdge(
        outputPath,
        canUseGallery: true,
        androidScanTitle: 'Scan Document',
        androidCropTitle: 'Crop Document',
        androidCropBlackWhiteTitle: 'Black & White',
        androidCropReset: 'Reset',
      );

      if (!success || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final File imageFile = File(outputPath);
      if (!await imageFile.exists()) {
        if (mounted) {
          AppDialogs.showSnackBar(context, message: 'No valid image found');
        }
        setState(() => _isLoading = false);
        return;
      }

      // Process the image
      final scanState = ref.read(scanProvider);

      ref.read(scanProvider.notifier).addPage(imageFile);

      // Create PDF
      if (ref.read(scanProvider).scannedPages.isNotEmpty) {
        _thumbnailImage = ref.read(scanProvider).scannedPages.first;
        final documentName =
            'Scan_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}';
        _pdfPath = await _pdfService.createPdfFromImages(
          ref.read(scanProvider).scannedPages,
          documentName,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _scanSuccessful = ref.read(scanProvider).scannedPages.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(context, message: 'Error: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openImageEditor() async {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final File currentPage = scanState.scannedPages[_currentPageIndex];
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

                // Update the provider with the updated file
                ref
                    .read(scanProvider.notifier)
                    .updatePageAt(_currentPageIndex, editedFile);

                // Force UI update
                setState(() {});

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

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isLoading = true;
        _scanSuccessful = false;
        _pdfPath = null;
        _thumbnailImage = null;
      });

      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final scanState = ref.read(scanProvider);
      for (var image in images) {
        final File imageFile = File(image.path);

        ref.read(scanProvider.notifier).addPage(imageFile);
      }

      if (ref.read(scanProvider).scannedPages.isNotEmpty) {
        _thumbnailImage = ref.read(scanProvider).scannedPages.first;
        final documentName =
            'Scan_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}';
        _pdfPath = await _pdfService.createPdfFromImages(
          ref.read(scanProvider).scannedPages,
          documentName,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _scanSuccessful = ref.read(scanProvider).scannedPages.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(context, message: 'Error: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEditScreen() => AppRoutes.navigateToEdit(context);

  void _resetScan() {
    if (mounted) {
      setState(() {
        _scanSuccessful = false;
        _pdfPath = null;
        _thumbnailImage = null;
      });
      ref.read(scanProvider.notifier).clearPages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Scan Document'),
        actions: [
          if (_scanSuccessful)
            TextButton(
              onPressed: () => _navigateToEditScreen(),
              // icon: const Icon(Icons.save),
              child: const Text('Save as PDF'),
            ),
        ],
      ),
      body: Stack(
        children: [
          _scanSuccessful ? _buildSuccessUI() : _buildScanUI(),
          if (_isLoading && _scanSuccessful)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessUI() {
    final themeData = Theme.of(context);
    final pages = ref.watch(scanProvider).scannedPages;

    return Column(
      children: [
        // Header with instructions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      themeData.colorScheme.primaryContainer.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.drag_indicator,
                  color: themeData.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pages.length} page${pages.length != 1 ? 's' : ''} scanned',
                      style: themeData.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Drag and drop to reorder pages',
                      style: themeData.textTheme.bodySmall?.copyWith(
                        color: themeData.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _scanDocuments(),
                icon: const Icon(Icons.add_a_photo, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ReorderableGridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: ref.watch(scanProvider).scannedPages.length,
            itemBuilder: (context, index) {
              final page = ref.watch(scanProvider).scannedPages[index];
              return GestureDetector(
                key: ValueKey(page.path),
                onTap: () {
                  setState(() {
                    _currentPageIndex = index;
                  });
                  _openImageEditor();
                },
                child: _buildPageCard(page, index),
              );
            },
            onReorder: (oldIndex, newIndex) => ref
                .read(scanProvider.notifier)
                .reorderPages(oldIndex, newIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildPageCard(File page, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail with gradient overlay
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Page image
                Hero(
                  tag: 'scan_page_$index',
                  child: Image.file(
                    page,
                    fit: BoxFit.cover,
                    cacheHeight: 500,
                    filterQuality: FilterQuality.medium,
                  ),
                ),

                // Subtle gradient overlay to enhance visibility of UI elements
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.0, 0.2, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // Page number indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Delete button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // Show a confirmation dialog with haptic feedback
                          HapticFeedback.mediumImpact();

                          ref.read(scanProvider.notifier).removePage(index);
                          if (ref.read(scanProvider).scannedPages.isEmpty) {
                            _resetScan();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Edit indicator at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.touch_app,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to edit',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.drag_indicator,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Drag',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Scan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the button below to scan a document',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: _scanDocuments,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Import from Gallery'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
