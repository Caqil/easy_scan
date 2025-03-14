import 'dart:io';
import 'dart:typed_data';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/utils/permission_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../config/routes.dart';
import '../../../providers/scan_provider.dart';
import '../../../services/pdf_service.dart';
import '../../common/app_bar.dart';
import '../../common/dialogs.dart';
import 'component/scan_initial_view.dart';
import 'component/scanned_documents_view.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final Document? document;
  const CameraScreen({
    super.key,
    this.document,
  });

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Scan Document'),
        actions: [
          if (_scanSuccessful)
            TextButton(
              onPressed: () => AppRoutes.navigateToEdit(context,
                  document: widget.document!.id),
              child: const Text('Save as PDF'),
            ),
        ],
      ),
      body: Stack(
        children: [
          _scanSuccessful ? _buildSuccessUI() : _buildScanUI(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessUI() {
    return ScannedDocumentsView(
      pages: ref.watch(scanProvider).scannedPages,
      currentIndex: _currentPageIndex,
      isProcessing: _isProcessing,
      onPageTap: (index) {
        setState(() {
          _currentPageIndex = index;
        });
        _openImageEditor();
      },
      onPageRemove: (index) {
        ref.read(scanProvider.notifier).removePage(index);
        if (ref.read(scanProvider).scannedPages.isEmpty) {
          _resetScan();
        }
      },
      onPagesReorder: (oldIndex, newIndex) {
        ref.read(scanProvider.notifier).reorderPages(oldIndex, newIndex);
      },
      onAddMore: _scanDocuments,
    );
  }

  Widget _buildScanUI() {
    return ScanInitialView(
      onScanPressed: _scanDocuments,
      onImportPressed: _pickImages,
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
      for (File imageFile in validImageFiles) {
        try {
          ref.read(scanProvider.notifier).addPage(imageFile);
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
}
