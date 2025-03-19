import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/providers/scan_provider.dart';
import 'package:scanpro/services/image_service.dart';
import 'package:scanpro/services/pdf_service.dart';
import 'package:scanpro/services/scan_service.dart';
import 'package:scanpro/ui/common/component/scan_initial_view.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;

enum EditMode {
  imageEdit, // Edit as individual images
  pdfEdit // Edit as PDF document
}

class EditScreenController {
  final WidgetRef ref;
  final BuildContext context;
  final Document? document;

  late TextEditingController documentNameController;
  late TextEditingController passwordController;
  final PdfService pdfService = PdfService();
  final ImageService imageService = ImageService();
  int currentPageIndex = 0;
  bool isProcessing = false;
  bool isEditView = true;
  late PageController pageController;
  List<File> pages = [];
  bool isEditingExistingDocument = false;
  final ImagePicker imagePicker = ImagePicker();
  bool isLoading = false;
  bool isPasswordProtected = false;
  VoidCallback? _onStateChanged;
  bool _isImageOnlyDocument = false;
  bool get isImageOnlyDocument => _isImageOnlyDocument;
  // Document type tracking
  bool isPdfInputFile = false;
  EditMode _currentEditMode = EditMode.imageEdit;
  EditMode get currentEditMode => _currentEditMode;
  bool _canSwitchEditMode = false;
  bool get canSwitchEditMode => _canSwitchEditMode;

  EditScreenController({
    required this.ref,
    required this.context,
    this.document,
  });

  void setStateCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void init() {
    pageController = PageController();
    isEditingExistingDocument = document != null;
    passwordController = TextEditingController();

    if (isEditingExistingDocument) {
      documentNameController = TextEditingController(text: document!.name);
      isPasswordProtected = document!.isPasswordProtected;
      if (isPasswordProtected && document!.password != null) {
        passwordController.text = document!.password!;
      }

      // When editing existing documents, check if we have both PDF and original images
      _loadExistingDocument();
    } else {
      documentNameController = TextEditingController(
          text: 'Scan ${DateTime.now().toString().substring(0, 10)}');
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfEmpty());

      // For new scans, we always start in image edit mode and can't switch
      _canSwitchEditMode = false;
      _currentEditMode = EditMode.imageEdit;
    }
  }

  String? _tempPreviewPdfPath;
  List<File>? _originalPages;

// Add this method to check if the current pages contain any PDF files
  bool _containsPdfFiles() {
    for (File page in pages) {
      final extension = path.extension(page.path).toLowerCase();
      if (extension == '.pdf') return true;
    }
    return false;
  }

// Modify the switchEditMode method to update the preview when switching modes
  void switchEditMode(EditMode newMode) {
    if (!_canSwitchEditMode) {
      AppDialogs.showSnackBar(
        context,
        message: 'Please save the document before switching modes',
        type: SnackBarType.warning,
      );
      return;
    }

    // Clean up any temporary preview files when switching modes
    if (_tempPreviewPdfPath != null && _originalPages != null) {
      // Restore original pages
      pages = _originalPages!;

      // Schedule temp file for deletion
      File(_tempPreviewPdfPath!).delete().catchError((e) {
        logger.error('Error deleting temp PDF: $e');
      });

      _tempPreviewPdfPath = null;
      _originalPages = null;
    }

    _currentEditMode = newMode;

    // If switching to PDF mode, prepare a PDF preview
    if (newMode == EditMode.pdfEdit) {
      preparePdfPreview();
    }

    updateUI();

    AppDialogs.showSnackBar(
      context,
      message: 'edit_mode_switched'.tr(namedArgs: {
        'mode': newMode == EditMode.imageEdit ? 'categories.images'.tr() : 'PDF'
      }),
      type: SnackBarType.success,
    );
  }

// Cleanup method - make sure to call this when disposing
  void cleanupTempFiles() {
    if (_tempPreviewPdfPath != null) {
      try {
        File(_tempPreviewPdfPath!).deleteSync();
      } catch (e) {
        logger.error('Error cleaning up temp files: $e');
      }
      _tempPreviewPdfPath = null;
    }
  }

  Future<void> preparePdfPreview() async {
    if (_currentEditMode == EditMode.pdfEdit && !_containsPdfFiles()) {
      // Only create a temp PDF if we're in PDF mode and don't already have a PDF file
      isProcessing = true;
      updateUI();

      try {
        // Create a list of files to include in the PDF
        List<File> imageFiles = [];
        for (File page in pages) {
          String ext = path.extension(page.path).toLowerCase();
          if (ext != '.pdf') {
            imageFiles.add(page);
          }
        }

        if (imageFiles.isNotEmpty) {
          // Create a temporary PDF from the images
          final pdfService = PdfService();
          final String tempPdfPath = await pdfService.createPdfFromImages(
              imageFiles,
              'temp_preview_${DateTime.now().millisecondsSinceEpoch}');

          // Store the original pages
          List<File> originalPages = List.from(pages);

          // Replace pages with just the PDF for preview purposes
          pages = [File(tempPdfPath)];

          // Store the temp PDF path to clean up later
          _tempPreviewPdfPath = tempPdfPath;
          _originalPages = originalPages;
        }
      } catch (e) {
        logger.error('Error creating PDF preview: $e');
        AppDialogs.showSnackBar(
          context,
          message: 'Could not create PDF preview: $e',
          type: SnackBarType.error,
        );
      } finally {
        isProcessing = false;
        updateUI();
      }
    }
  }

  void dispose() {
    documentNameController.dispose();
    passwordController.dispose();
    pageController.dispose();
  }

  void toggleViewMode() {
    // If this is a PDF-only file and we're in PDF edit mode, show a snackbar and don't toggle the view
    if (isPdfInputFile && currentEditMode == EditMode.pdfEdit) {
      AppDialogs.showSnackBar(
        context,
        message: 'grid_view_unavailable'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    // Otherwise proceed with the toggle
    isEditView = !isEditView;
    _notifyStateChanged();
  }

  Future<void> _loadExistingDocument() async {
    isProcessing = true;
    _notifyStateChanged();

    try {
      final doc = document!;
      pages = [];
      bool hasOriginalImages = false;
      bool hasPdfFile = false;
      bool isImageOnlyDocument = false;

      // First check if PDF exists
      if (doc.pdfPath.isNotEmpty) {
        final pdfFile = File(doc.pdfPath);
        if (await pdfFile.exists()) {
          String ext = path.extension(doc.pdfPath).toLowerCase();
          if (ext == '.pdf') {
            pages.add(pdfFile);
            hasPdfFile = true;
            logger.info('Loaded PDF file: ${pdfFile.path}');
          } else {
            // If primary file is an image, not a PDF
            pages.add(pdfFile);
            hasOriginalImages = true;
            isImageOnlyDocument = true;
            logger.info('Primary file is an image: ${pdfFile.path}');
          }
        }
      }

      // Then check for original images (excluding the first path if it's already processed)
      if (doc.pagesPaths.length > 1) {
        // Start from index 0 or 1 depending on whether we already processed the first path
        int startIndex = hasPdfFile || isImageOnlyDocument ? 1 : 0;
        List<String> imagePaths = doc.pagesPaths.sublist(startIndex);
        List<File> imageFiles = [];

        for (String path in imagePaths) {
          final file = File(path);
          if (await file.exists()) {
            String ext = extension(file.path).toLowerCase();
            if (ext != '.pdf') {
              // Make sure it's not a PDF
              imageFiles.add(file);
              hasOriginalImages = true;
              logger.info('Found original image: ${file.path}');
            }
          }
        }

        // If in image mode, use the image files
        if (_currentEditMode == EditMode.imageEdit && imageFiles.isNotEmpty) {
          if (isImageOnlyDocument) {
            // If primary file is already an image, add additional images
            pages.addAll(imageFiles);
          } else {
            // Replace PDF with images
            pages = imageFiles;
          }
        }
      }

      // Handle image-only documents (when primary file is an image)
      if (isImageOnlyDocument || (hasOriginalImages && !hasPdfFile)) {
        isPdfInputFile = false;
        _currentEditMode = EditMode.imageEdit;

        // For image-only documents, set up a special edit mode flag
        _isImageOnlyDocument = true;
        _canSwitchEditMode = false;
        logger.info('Document contains only images - enabling image edit mode');
      }
      // Determine edit mode capabilities for other cases
      else if (hasPdfFile && hasOriginalImages) {
        // We have both PDF and original images, so we can switch modes
        _canSwitchEditMode = true;
        _currentEditMode =
            EditMode.imageEdit; // Start in image edit mode by default
        isPdfInputFile = true; // We do have a PDF file
        logger.info(
            'Document has both PDF and original images - edit mode switching enabled');
      } else if (hasPdfFile) {
        // Only PDF available
        isPdfInputFile = true;
        _currentEditMode = EditMode.pdfEdit;
        _canSwitchEditMode = false;
        logger.info('Document has only PDF - restricting to PDF edit mode');
      }

      if (pages.isEmpty) {
        throw Exception(
            'No valid pages found in document. All file paths are invalid or missing.');
      }
    } catch (e) {
      AppDialogs.showSnackBar(context,
          message: 'Error loading document: $e', type: SnackBarType.error);
    } finally {
      isProcessing = false;
      _notifyStateChanged();
    }
  }

  void _checkIfEmpty() {
    final scanState = ref.read(scanProvider);
    if (scanState.scannedPages.isEmpty && !isEditingExistingDocument) {
      Navigator.pop(context);
    } else if (!isEditingExistingDocument) {
      pages = scanState.scannedPages;
      _notifyStateChanged();
    }
  }

  void _notifyStateChanged() {
    _onStateChanged?.call();
  }

  void updateUI() {
    _onStateChanged?.call();
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= pages.length) return;
    if (newIndex < 0 || newIndex > pages.length) return;

    final File page = pages.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex -= 1;
    pages.insert(newIndex, page);

    if (!isEditingExistingDocument) {
      ref.read(scanProvider.notifier).reorderPages(oldIndex, newIndex);
    }
    _notifyStateChanged();
  }

  void deletePageAtIndex(int index) {
    if (pages.length <= 1) {
      AppDialogs.showSnackBar(
        context,
        message: 'cannot_delete_only_page'.tr(),
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
        pages.removeAt(index);
        if (!isEditingExistingDocument) {
          ref.read(scanProvider.notifier).removePage(index);
        }
        if (currentPageIndex >= pages.length) {
          currentPageIndex = pages.length - 1;
        }
        _notifyStateChanged();
      }
    });
  }

  Future<void> addMorePages() async {
    // Don't allow adding more pages if we're in PDF edit mode with a PDF input
    if (isPdfInputFile && _currentEditMode == EditMode.pdfEdit) {
      AppDialogs.showSnackBar(
        context,
        message:
            'Cannot add pages to an imported PDF. Try switching to image edit mode.',
        type: SnackBarType.warning,
      );
      return;
    }

    final scanService = ref.read(scanServiceProvider);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ScanInitialView(
            onScanPressed: () => scanService.scanDocuments(
              context: context,
              ref: ref,
              setLoading: (isLoading) {
                this.isLoading = isLoading;
                _notifyStateChanged();
              },
              onSuccess: () => Navigator.pop(context),
            ),
            onImportPressed: () => scanService.pickImages(
              context: context,
              ref: ref,
              setLoading: (isLoading) {
                this.isLoading = isLoading;
                _notifyStateChanged();
              },
              onSuccess: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );

    final scanState = ref.read(scanProvider);
    if (scanState.hasPages) {
      final newPages = List<File>.from(scanState.scannedPages);
      pages.addAll(newPages);
      ref.read(scanProvider.notifier).clearPages();
      AppDialogs.showSnackBar(
        context,
        message: 'Added ${newPages.length} new page(s)',
        type: SnackBarType.success,
      );
      _notifyStateChanged();
    }
  }

  Future<void> openImageEditor() async {
    if (pages.isEmpty) return;

    // Check if we're trying to edit a PDF file directly
    if (_currentEditMode == EditMode.pdfEdit) {
      AppDialogs.showSnackBar(
        context,
        message:
            'PDF files cannot be edited directly. Switch to image edit mode for image editing.',
        type: SnackBarType.warning,
      );
      return;
    }

    // Check if the current page is a PDF file
    if (path.extension(pages[currentPageIndex].path).toLowerCase() == '.pdf') {
      AppDialogs.showSnackBar(
        context,
        message: 'PDF pages cannot be edited directly.',
        type: SnackBarType.warning,
      );
      return;
    }

    isProcessing = true;
    _notifyStateChanged();

    try {
      final File currentPage = pages[currentPageIndex];
      final Uint8List imageBytes = await currentPage.readAsBytes();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.memory(
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                final File editedFile = File(currentPage.path);
                await editedFile.writeAsBytes(bytes);
                imageCache.clear();
                imageCache.clearLiveImages();
                pages[currentPageIndex] = editedFile;
                if (!isEditingExistingDocument) {
                  ref
                      .read(scanProvider.notifier)
                      .updatePageAt(currentPageIndex, editedFile);
                }
                Navigator.pop(context);
              },
            ),
            imageBytes,
          ),
        ),
      );
    } catch (e) {
      AppDialogs.showSnackBar(context, message: 'Error editing image: $e');
    } finally {
      isProcessing = false;
      _notifyStateChanged();
    }
  }

  Future<void> saveDocument() async {
    if (documentNameController.text.trim().isEmpty) {
      AppDialogs.showSnackBar(context, message: 'Please enter a document name');
      return;
    }
    if (pages.isEmpty) {
      AppDialogs.showSnackBar(context, message: 'No pages to save');
      return;
    }

    final bool isPasswordProtectionEnabled = passwordController.text.isNotEmpty;
    if (isPasswordProtectionEnabled && passwordController.text.length < 4) {
      AppDialogs.showSnackBar(
        context,
        message: 'Password must be at least 4 characters long',
        type: SnackBarType.warning,
      );
      return;
    }

    isProcessing = true;
    _notifyStateChanged();

    try {
      final String documentName = documentNameController.text.trim();
      String filePath;
      int pageCount;
      String fileExtension = 'pdf'; // We're always saving as PDF
      File? thumbnailFile;

      // Step 1: Categorize all files
      List<File> imageFiles = [];
      List<File> pdfFiles = [];
      List<String> tempPaths = []; // Track temp files to clean up later

      for (File page in pages) {
        String ext = path.extension(page.path).toLowerCase();
        if (ext == '.pdf') {
          pdfFiles.add(page);
        } else if (['.jpg', '.jpeg', '.png', '.bmp', '.webp', '.gif']
            .contains(ext)) {
          imageFiles.add(page);
        } else {
          logger.warning('Warning: Unrecognized file type: $ext');
          // For other file types, try to treat as image
          imageFiles.add(page);
        }
      }

      logger.info(
          'Processing ${imageFiles.length} images and ${pdfFiles.length} PDFs');

      // Step 2: Handle based on edit mode and content
      // Check if we're in PDF edit mode
      if (_currentEditMode == EditMode.pdfEdit) {
        // PDF Edit Mode - For both PDF and image inputs

        // When in PDF Edit Mode, we want to either:
        // 1. Use a single existing PDF file directly (if that's all we have)
        // 2. Convert all images to a single PDF (if we have no PDFs)
        // 3. Merge PDFs and image-converted-PDFs together

        if (pdfFiles.length == 1 && imageFiles.isEmpty && isPdfInputFile) {
          // Case 1: Single PDF file only - use it directly
          logger.info('PDF Edit Mode - using single PDF directly');
          filePath = pdfFiles[0].path;
          pageCount = await pdfService.getPdfPageCount(filePath);
        } else {
          // Case 2 & 3: Create or merge PDFs
          logger.info('PDF Edit Mode - creating/merging PDFs');
          List<String> allPdfPaths = [];

          // Add existing PDFs
          if (pdfFiles.isNotEmpty) {
            allPdfPaths.addAll(pdfFiles.map((file) => file.path));
          }

          // Convert images to PDFs if we have any
          if (imageFiles.isNotEmpty) {
            try {
              String imagesPdfPath = await pdfService.createPdfFromImages(
                  imageFiles,
                  '${documentName}_images_${DateTime.now().millisecondsSinceEpoch}');
              allPdfPaths.add(imagesPdfPath);
              tempPaths.add(imagesPdfPath);
            } catch (e) {
              logger.error('Error batch converting images: $e');
              // Fallback: convert images individually
              for (int i = 0; i < imageFiles.length; i++) {
                try {
                  String singleImagePdfPath =
                      await pdfService.createPdfFromImages(
                    [imageFiles[i]],
                    '${documentName}_image${i}_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  allPdfPaths.add(singleImagePdfPath);
                  tempPaths.add(singleImagePdfPath);
                } catch (e) {
                  logger.error('Error converting image ${i}: $e');
                  // Skip problematic image
                }
              }
            }
          }

          // Check if we have any PDFs to work with
          if (allPdfPaths.isEmpty) {
            throw Exception('No valid content to save');
          } else if (allPdfPaths.length == 1) {
            // Only one PDF, use it directly
            filePath = allPdfPaths[0];
          } else {
            // Merge multiple PDFs
            filePath = await pdfService.mergePdfs(allPdfPaths, documentName);
          }

          // Get final page count
          pageCount = await pdfService.getPdfPageCount(filePath);
        }
      } else {
        // Image Edit Mode - Convert all to PDFs and merge if needed
        logger.info('Image Edit Mode - converting to PDF');
        List<String> allPdfPaths = [];

        // Convert images to PDFs
        if (imageFiles.isNotEmpty) {
          try {
            String imagesPdfPath = await pdfService.createPdfFromImages(
                imageFiles,
                '${documentName}_images_${DateTime.now().millisecondsSinceEpoch}');
            allPdfPaths.add(imagesPdfPath);
            tempPaths.add(imagesPdfPath);
          } catch (e) {
            logger.error('Error batch converting images: $e');
            // Fallback: convert images individually
            for (int i = 0; i < imageFiles.length; i++) {
              try {
                String singleImagePdfPath =
                    await pdfService.createPdfFromImages(
                  [imageFiles[i]],
                  '${documentName}_image${i}_${DateTime.now().millisecondsSinceEpoch}',
                );
                allPdfPaths.add(singleImagePdfPath);
                tempPaths.add(singleImagePdfPath);
              } catch (e) {
                logger.error('Error converting image ${i}: $e');
                // Skip problematic image
              }
            }
          }
        }

        // Add existing PDFs if any
        if (pdfFiles.isNotEmpty) {
          allPdfPaths.addAll(pdfFiles.map((file) => file.path));
        }

        // Finalize the PDF path
        if (allPdfPaths.isEmpty) {
          throw Exception('No valid content to save');
        } else if (allPdfPaths.length == 1) {
          filePath = allPdfPaths[0];
        } else {
          filePath = await pdfService.mergePdfs(allPdfPaths, documentName);
        }

        pageCount = await pdfService.getPdfPageCount(filePath);
      }

      // Step 3: Apply password protection if needed
      if (isPasswordProtectionEnabled) {
        // For single PDF that's an input, make a copy before applying password
        if (isPdfInputFile && pdfFiles.length == 1 && imageFiles.isEmpty) {
          final tempDir = await getTemporaryDirectory();
          final tempPath =
              '${tempDir.path}/temp_password_${DateTime.now().millisecondsSinceEpoch}.pdf';
          await File(filePath).copy(tempPath);
          filePath = tempPath;
          tempPaths.add(tempPath);
        }

        // Apply password
        filePath =
            await pdfService.protectPdf(filePath, passwordController.text);
      }

      // Step 4: Generate thumbnail
      try {
        thumbnailFile = await imageService.createThumbnail(File(filePath),
            size: AppConstants.thumbnailSize);
      } catch (e) {
        logger.error('Error creating thumbnail: $e');
        // Create fallback thumbnail
        thumbnailFile = await _createSimpleThumbnail(documentName);
      }

      // Step 5: Save document to repository
      List<String> pagesPaths = [];

      // First path is always the PDF
      pagesPaths.add(filePath);

      // For newly created documents, store the original image paths
      // This allows future editing as either images or PDF
      if (!isEditingExistingDocument && imageFiles.isNotEmpty) {
        // Add all original image paths
        for (File imageFile in imageFiles) {
          pagesPaths.add(imageFile.path);
        }

        logger.info(
            'Saving document with ${pagesPaths.length} paths: PDF + ${pagesPaths.length - 1} original images');
      } else if (isEditingExistingDocument) {
        // For existing documents, preserve the original image paths if available
        if (document!.pagesPaths.length > 1) {
          // Check if the original image paths still exist
          List<String> validOriginalPaths = [];

          for (int i = 1; i < document!.pagesPaths.length; i++) {
            String originalPath = document!.pagesPaths[i];
            if (await File(originalPath).exists()) {
              validOriginalPaths.add(originalPath);
            }
          }

          // Only include valid image paths
          if (validOriginalPaths.isNotEmpty) {
            pagesPaths.addAll(validOriginalPaths);
            logger.info(
                'Preserving ${validOriginalPaths.length} original image paths');
          }
        }
      }

      if (isEditingExistingDocument) {
        final updatedDocument = document!.copyWith(
          name: documentName,
          pdfPath: filePath,
          pagesPaths: pagesPaths, // Now storing PDF + original images
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
          modifiedAt: DateTime.now(),
          isPasswordProtected: isPasswordProtectionEnabled,
          password:
              isPasswordProtectionEnabled ? passwordController.text : null,
        );

        await ref
            .read(documentsProvider.notifier)
            .updateDocument(updatedDocument);
        AppDialogs.showSnackBar(
          context,
          message: 'document_updated_success'.tr(),
          type: SnackBarType.success,
        );
      } else {
        final newDocument = Document(
          name: documentName,
          pdfPath: filePath,
          pagesPaths: pagesPaths, // Now storing PDF + original images
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
          isPasswordProtected: isPasswordProtectionEnabled,
          password:
              isPasswordProtectionEnabled ? passwordController.text : null,
        );

        await ref.read(documentsProvider.notifier).addDocument(newDocument);
        AppDialogs.showSnackBar(
          context,
          message: 'document_saved_success'.tr(namedArgs: {
            'protected':
                isPasswordProtectionEnabled ? ' with password protection' : ''
          }),
          type: SnackBarType.success,
        );
        ref.read(scanProvider.notifier).clearPages();
      }

      // Clean up temporary files
      for (String tempPath in tempPaths) {
        if (tempPath != filePath) {
          // Don't delete the final PDF
          try {
            final tempFile = File(tempPath);
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (e) {
            // Ignore cleanup errors
            logger.warning('Warning: Could not clean up temp file: $tempPath');
          }
        }
      }

      context.go(AppRoutes.home);
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'error_saving_document'.tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
      logger.error('Error saving document: $e');
    } finally {
      isProcessing = false;
      _notifyStateChanged();
    }
  }

  // Create a simple fallback thumbnail when all else fails
  Future<File> _createSimpleThumbnail(String documentName) async {
    try {
      // Create a simple colored rectangle with text
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = 300.0; // Standard thumbnail size

      // Fill background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size, size),
        Paint()..color = Colors.blueGrey.shade100,
      );

      // Draw PDF icon (as text emoji)
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: '📄',
          style: GoogleFonts.notoSerif(fontSize: size * 0.4),
        ),
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset((size - iconPainter.width) / 2, size * 0.25),
      );

      // Draw document name
      final TextPainter namePainter = TextPainter(
        text: TextSpan(
          text: documentName.length > 15
              ? '${documentName.substring(0, 15)}...'
              : documentName,
          style: GoogleFonts.notoSerif(
            fontSize: size * 0.08,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
      namePainter.layout(maxWidth: size - 30);
      namePainter.paint(
        canvas,
        Offset((size - namePainter.width) / 2, size * 0.7),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate fallback thumbnail');
      }

      // Save to file
      final outputPath = await FileUtils.getUniqueFilePath(
        documentName:
            'thumbnail_fallback_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'png',
        inTempDirectory: false,
      );

      final file = File(outputPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      // If all else fails, create a 1x1 pixel image as an absolute last resort
      final outputPath = await FileUtils.getUniqueFilePath(
        documentName:
            'thumbnail_empty_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'png',
        inTempDirectory: false,
      );

      final List<int> pixels = [0, 0, 0, 255]; // Simple black pixel
      final File file = File(outputPath);
      await file.writeAsBytes(Uint8List.fromList(pixels));

      return file;
    }
  }
}
