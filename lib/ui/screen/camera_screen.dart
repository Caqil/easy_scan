import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../config/routes.dart';
import '../../providers/scan_provider.dart';
import '../../services/image_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/permission_utils.dart';
import '../common/app_bar.dart';
import '../common/dialogs.dart';
import '../widget/scan_options.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  final ImageService _imageService = ImageService();
  final PdfService _pdfService = PdfService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _scanSuccessful = false;
  String? _pdfPath;
  File? _thumbnailImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset loading state when app resumes to prevent UI being stuck in loading state
    if (state == AppLifecycleState.resumed && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkCameraPermission() async {
    final hasPermission = await PermissionUtils.hasCameraPermission();
    if (!hasPermission) {
      await PermissionUtils.requestCameraPermission();
    }
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
        _scanSuccessful = false;
        _pdfPath = null;
        _thumbnailImage = null;
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
      final scanState = ref.read(scanProvider);
      for (File imageFile in validImageFiles) {
        try {
          final File processedFile = await _imageService.enhanceImage(
            imageFile,
            scanState.settings.colorMode,
            quality: scanState.settings.quality,
          );
          ref.read(scanProvider.notifier).addPage(processedFile);
        } catch (e) {
          // Just skip failed images to improve reliability
          print('Failed to process image: $e');
        }
      }

      // Create a PDF from the processed images
      if (ref.read(scanProvider).scannedPages.isNotEmpty) {
        // Save first image as thumbnail
        _thumbnailImage = ref.read(scanProvider).scannedPages.first;

        // Generate a default document name
        final documentName =
            'Scan_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}';

        // Create PDF
        _pdfPath = await _pdfService.createPdfFromImages(
          ref.read(scanProvider).scannedPages,
          documentName,
        );
      }

      // Close the processing dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Update UI to show success state
      setState(() {
        _isLoading = false;
        _scanSuccessful = ref.read(scanProvider).scannedPages.isNotEmpty;
      });
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
        _scanSuccessful = false;
        _pdfPath = null;
        _thumbnailImage = null;
      });

      // Let the gallery picker do its job
      final List<XFile> images = await _imagePicker.pickMultiImage();

      // User canceled or no images selected
      if (images.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Show processing dialog
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
                Text('Processing images...')
              ],
            ),
          ),
        );
      }

      // Process images
      final scanState = ref.read(scanProvider);
      for (var image in images) {
        try {
          final File imageFile = File(image.path);
          final File processedFile = await _imageService.enhanceImage(
            imageFile,
            scanState.settings.colorMode,
            quality: scanState.settings.quality,
          );
          ref.read(scanProvider.notifier).addPage(processedFile);
        } catch (e) {
          print('Failed to process image: $e');
          // Continue with other images
        }
      }

      // Create a PDF from the processed images
      if (ref.read(scanProvider).scannedPages.isNotEmpty) {
        // Save first image as thumbnail
        _thumbnailImage = ref.read(scanProvider).scannedPages.first;

        // Generate a default document name
        final documentName =
            'Scan_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}';

        // Create PDF
        _pdfPath = await _pdfService.createPdfFromImages(
          ref.read(scanProvider).scannedPages,
          documentName,
        );
      }

      // Close the processing dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Update UI to show success state
      setState(() {
        _isLoading = false;
        _scanSuccessful = ref.read(scanProvider).scannedPages.isNotEmpty;
      });
    } catch (e) {
      // Close the processing dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error importing images: ${e.toString()}',
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditScreen() {
    AppRoutes.navigateToEdit(context);
  }

  void _showScanOptions() {
    final scanState = ref.read(scanProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ScanOptionsWidget(
          settings: scanState.settings,
          onSettingsChanged: (newSettings) {
            ref.read(scanProvider.notifier).updateSettings(newSettings);
          },
        ),
      ),
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

  Future<void> _saveDocument() async {
    if (ref.read(scanProvider).scannedPages.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'No pages to save',
      );
      return;
    }

    // Display a dialog to input document name
    final TextEditingController nameController = TextEditingController(
      text: 'Scan ${DateTime.now().toString().substring(0, 10)}',
    );

    bool shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Document'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Document Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSave || !mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Show saving dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving document...'),
            ],
          ),
        ),
      );

      // Generate thumbnail for the first page
      final scanState = ref.read(scanProvider);
      if (scanState.scannedPages.isNotEmpty) {
        final File thumbnailFile = await _imageService.createThumbnail(
          scanState.scannedPages[0],
        );

        // Create PDF from scanned images
        final String documentName = nameController.text.trim();
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

        // Save document to provider
        await ref.read(documentsProvider.notifier).addDocument(document);

        // Close saving dialog
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show success and navigate to home
        AppDialogs.showSnackBar(
          context,
          message: 'Document saved successfully',
        );

        // Clear the scan state and return to home
        ref.read(scanProvider.notifier).clearPages();
        AppRoutes.navigateToHome(context);
      }
    } catch (e) {
      // Close saving dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      AppDialogs.showSnackBar(
        context,
        message: 'Error saving document: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    nameController.dispose();
  }

  void _resetScan() {
    setState(() {
      _scanSuccessful = false;
      _pdfPath = null;
      _thumbnailImage = null;
    });
    ref.read(scanProvider.notifier).clearPages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Scan Document'),
        actions: [
          if (_scanSuccessful)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showScanOptions,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scanSuccessful
              ? _buildSuccessUI()
              : _buildScanUI(),
      floatingActionButton: _scanSuccessful
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "addBtn",
                  onPressed: _scanDocuments,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: "saveBtn",
                  onPressed: _saveDocument,
                  icon: const Icon(Icons.save),
                  label: const Text('Save PDF'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      children: [
        // Drag and drop hint
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade800,
          child: Row(
            children: [
              Icon(Icons.drag_indicator, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'Drag and drop to reorder pages',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        // Scanned pages grid with reordering
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
                onTap: _navigateToEditScreen,
                child: _buildPageCard(page, index),
              );
            },
            onReorder: (oldIndex, newIndex) {
              ref.read(scanProvider.notifier).reorderPages(oldIndex, newIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageCard(File page, int index) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  page,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        ref.read(scanProvider.notifier).removePage(index);
                        if (ref.read(scanProvider).scannedPages.isEmpty) {
                          _resetScan();
                        }
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Page label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withOpacity(0.7),
            child: Text(
              'Page ${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the button below to scan a document',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _scanDocuments,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Import from Gallery'),
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: _showScanOptions,
              icon: const Icon(Icons.settings),
              tooltip: 'Scan Settings',
            ),
          ],
        ),
      ),
    );
  }
}
