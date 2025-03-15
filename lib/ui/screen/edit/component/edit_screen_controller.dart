import 'dart:io';
import 'dart:typed_data';
import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/providers/scan_provider.dart';
import 'package:easy_scan/services/image_service.dart';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/services/scan_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/camera/component/scan_initial_view.dart';
import 'package:easy_scan/utils/constants.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
      _loadExistingDocument();
    } else {
      documentNameController = TextEditingController(
          text: 'Scan ${DateTime.now().toString().substring(0, 10)}');
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfEmpty());
    }
  }

  void dispose() {
    documentNameController.dispose();
    passwordController.dispose();
    pageController.dispose();
  }

  void toggleViewMode() {
    isEditView = !isEditView;
    _notifyStateChanged();
  }

  Future<void> _loadExistingDocument() async {
    isProcessing = true;
    _notifyStateChanged();
    try {
      final doc = document!;
      pages = [];

      if (doc.pagesPaths.isEmpty) {
        throw Exception('Document has no pages defined');
      }

      for (String path in doc.pagesPaths) {
        final file = File(path);
        if (await file.exists()) {
          pages.add(file);
        } else {
          print('Warning: Page file does not exist at path: $path');

          // If the primary document path exists and it's a PDF, we can still work with it
          if (doc.pdfPath.isNotEmpty && await File(doc.pdfPath).exists()) {
            pages.add(File(doc.pdfPath));
            // Break after adding the PDF once - no need to add it multiple times
            break;
          }
        }
      }

      if (pages.isEmpty && doc.pdfPath.isNotEmpty) {
        // Try the main PDF path if individual page paths are missing
        final pdfFile = File(doc.pdfPath);
        if (await pdfFile.exists()) {
          pages.add(pdfFile);
        } else {
          throw Exception('Primary PDF file not found at ${doc.pdfPath}');
        }
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
      int pageCount = pages.length;
      String fileExtension;

      final File thumbnailFile = await imageService.createThumbnail(
        pages[0],
        size: AppConstants.thumbnailSize,
      );

      fileExtension =
          path.extension(pages[0].path).toLowerCase().replaceAll('.', '');

      filePath = await pdfService.createPdfFromImages(pages, documentName);
      pageCount = await pdfService.getPdfPageCount(filePath);
      fileExtension = 'pdf';

      if (isPasswordProtectionEnabled && fileExtension == 'pdf') {
        filePath =
            await pdfService.protectPdf(filePath, passwordController.text);
      }

      if (isEditingExistingDocument) {
        final updatedDocument = document!.copyWith(
          name: documentName,
          pdfPath: filePath,
          pagesPaths: pages.map((file) => file.path).toList(),
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
          message: 'Document updated successfully',
          type: SnackBarType.success,
        );
      } else {
        final newDocument = Document(
          name: documentName,
          pdfPath: filePath,
          pagesPaths: pages.map((file) => file.path).toList(),
          pageCount: pageCount,
          thumbnailPath: thumbnailFile.path,
          isPasswordProtected: isPasswordProtectionEnabled,
          password:
              isPasswordProtectionEnabled ? passwordController.text : null,
        );

        await ref.read(documentsProvider.notifier).addDocument(newDocument);
        AppDialogs.showSnackBar(
          context,
          message:
              'Document saved successfully as ${fileExtension.toUpperCase()}${isPasswordProtectionEnabled ? ' with password protection' : ''}',
          type: SnackBarType.success,
        );
        ref.read(scanProvider.notifier).clearPages();
      }

      AppRoutes.navigateToHome(context);
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Error saving document: $e',
        type: SnackBarType.error,
      );
      debugPrint('Error saving document: $e');
    } finally {
      isProcessing = false;
      _notifyStateChanged();
    }
  }

  bool _isTextFile(String extension) =>
      ['txt', 'html', 'md', 'rtf'].contains(extension);

  bool _isImageFile(String extension) =>
      ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension);

  Future<String> _copyFile(
      File sourceFile, String documentName, String extension) async {
    final String targetPath = await FileUtils.getUniqueFilePath(
      documentName: documentName,
      extension: extension,
    );
    final File newFile = await sourceFile.copy(targetPath);
    return newFile.path;
  }

  Future<String> _processSingleImage(
      File imageFile, String documentName, String extension) async {
    final String targetPath = await FileUtils.getUniqueFilePath(
      documentName: documentName,
      extension: extension,
    );
    try {
      final File newFile = await imageFile.copy(targetPath);
      return newFile.path;
    } catch (e) {
      final bytes = await imageFile.readAsBytes();
      final File newFile = File(targetPath);
      await newFile.writeAsBytes(bytes);
      return newFile.path;
    }
  }
}
