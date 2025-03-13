import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/ui/common/document_actions.dart';
import 'package:easy_scan/ui/common/folder_actions.dart';
import 'package:easy_scan/ui/common/folder_creator.dart';
import 'package:easy_scan/ui/common/folder_selection.dart';
import 'package:easy_scan/ui/common/folders_grid.dart';
import 'package:easy_scan/ui/common/import_options.dart';
import 'package:easy_scan/utils/constants.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../config/routes.dart';
import '../../../models/folder.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/folder_provider.dart';
import '../../../providers/scan_provider.dart';
import '../../../services/image_service.dart';
import '../../../services/pdf_import_service.dart';
import '../../../services/pdf_service.dart';
import '../../../utils/date_utils.dart';
import '../../common/app_bar.dart';
import '../../common/dialogs.dart';
import '../../widget/folder_card.dart';
import '../../widget/password_bottom_sheet.dart';
import 'widget/all_documents.dart';
import 'widget/empty_state.dart';
import 'widget/folders_section.dart';
import 'widget/quick_actions.dart';
import 'widget/recent_documents.dart';
import 'widget/search_results.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController controller = TextEditingController();
  String? _imagePath;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  final PdfService _pdfService = PdfService();
  bool _scanSuccessful = false;
  String? _pdfPath;
  File? _thumbnailImage;

  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    final recentDocuments = ref.watch(recentDocumentsProvider);
    final allDocuments = ref.watch(documentsProvider);
    final rootFolders = ref.watch(rootFoldersProvider);
    final List<Document> filteredDocuments = _searchQuery.isEmpty
        ? []
        : ref.read(documentsProvider.notifier).searchDocuments(_searchQuery);

    return Scaffold(
      appBar: CustomAppBar(
        title: _searchQuery.isEmpty
            ? const Text('CamScanner App')
            : TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Simply set an empty search query to activate search mode
                // without immediately clearing it
                setState(() {
                  _searchQuery = ' '; // Trigger search mode with a space
                  _searchController.text = ' '; // Set controller text to match
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppRoutes.navigateToSettings(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_searchQuery.isNotEmpty)
            _buildSearchResults(filteredDocuments)
          else
            RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
                ref.invalidate(documentsProvider);
                ref.invalidate(foldersProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  QuickActions(
                    onScan: () => AppRoutes.navigateToCamera(context),
                    onImport: () {
                      ImportOptions.showImportOptions(
                        context,
                        onImportFromGallery: _pickImageForScan,
                        onImportPdf: _importPdfFromLocal,
                        onImportFromCloud: _importPdfFromICloud,
                      );
                    },
                    onFolders: () => _showFolderSelectionDialog(rootFolders),
                    onFavorites: _showFavorites,
                  ),
                  const SizedBox(height: 24),
                  if (recentDocuments.isNotEmpty)
                    RecentDocuments(
                      documents: recentDocuments,
                      onDocumentTap: (doc) =>
                          AppRoutes.navigateToView(context, doc),
                      onMorePressed: (Document document) {
                        DocumentActions.showDocumentOptions(
                            context, document, ref);
                      },
                    ),
                  if (rootFolders.isNotEmpty)
                    FoldersSection(
                      folders: rootFolders,
                      onFolderTap: (folder) =>
                          AppRoutes.navigateToFolder(context, folder),
                      onMorePressed: (Folder folder) {
                        FolderActions.showFolderOptions(context, folder, ref);
                      },
                      onCreateFolder: _createNewFolder,
                      onSeeAll: () => FoldersGrid.showAllFolders(
                        context,
                        ref.read(rootFoldersProvider),
                        ref,
                        title: 'My Folders',
                        onFolderTap: (folder) {
                          AppRoutes.navigateToFolder(context, folder);
                        },
                        onFolderOptions: (folder) {
                          FolderActions.showFolderOptions(context, folder, ref);
                        },
                        onCreateNewFolder: _createNewFolder,
                      ), // Added See All callback
                    ),
                  if (allDocuments.isNotEmpty)
                    AllDocuments(
                      documents: allDocuments,
                      onDocumentTap: (doc) =>
                          AppRoutes.navigateToView(context, doc),
                      onMorePressed: (Document document) {
                        DocumentActions.showDocumentOptions(
                            context, document, ref);
                      },
                    ),
                  if (recentDocuments.isEmpty &&
                      rootFolders.isEmpty &&
                      allDocuments.isEmpty)
                    EmptyState(
                        onScan: () => AppRoutes.navigateToCamera(context)),
                ],
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRoutes.navigateToCamera(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
    );
  }

  void _createNewFolder() async {
    final folder = await FolderCreator.showCreateFolderBottomSheet(
      context,
      ref,
      title: 'Create Subfolder',
    );

    if (folder != null) {
      // Use the created folder
      print('Created folder: ${folder.name}');
    }
  }

  void _showFolderSelectionDialog(List<Folder> folders) async {
    final selectedFolder = await FolderSelector.showFolderSelectionDialog(
      context,
      folders,
      ref,
      onCreateFolder: _createNewFolder,
      onFolderOptions: (folder) {
        FolderActions.showFolderOptions(context, folder, ref);
      },
    );

    if (selectedFolder != null) {
      AppRoutes.navigateToFolder(context, selectedFolder);
    }
  }

  // Search results builder
  Widget _buildSearchResults(List<Document> documents) {
    if (documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No documents found',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return ListTile(
          leading: document.thumbnailPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(document.thumbnailPath!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.picture_as_pdf),
          title: Text(
            document.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateTimeUtils.getFriendlyDate(document.modifiedAt),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () =>
                DocumentActions.showDocumentOptions(context, document, ref),
          ),
          onTap: () => AppRoutes.navigateToView(context, document),
        );
      },
    );
  }

  Future<void> _importPdfFromLocal() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pdfImportService = PdfImportService();
      final document = await pdfImportService.importPdfFromLocal();

      if (document != null) {
        // Add the document to storage
        await ref.read(documentsProvider.notifier).addDocument(document);

        // Show success message
        // ignore: use_build_context_synchronously
        AppDialogs.showSnackBar(
          context,
          message: 'PDF imported successfully',
        );
      }
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error importing PDF: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Import PDF from iCloud (iOS only)
  Future<void> _importPdfFromICloud() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pdfImportService = PdfImportService();
      final document = await pdfImportService.importPdfFromICloud();

      if (document != null) {
        // Add the document to storage
        await ref.read(documentsProvider.notifier).addDocument(document);

        // Show success message
        // ignore: use_build_context_synchronously
        AppDialogs.showSnackBar(
          context,
          message: 'PDF imported from iCloud successfully',
        );
      }
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error importing PDF from iCloud: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Pick image from gallery for scanning
  Future<void> _pickImageForScan() async {
    final imageService = ImageService();
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        // Process images
        final scanState = ref.read(scanProvider);
        ref.read(scanProvider.notifier).setScanning(true);

        for (var image in images) {
          final File imageFile = File(image.path);

          ref.read(scanProvider.notifier).addPage(imageFile);
        }

        ref.read(scanProvider.notifier).setScanning(false);

        // Navigate to edit screen
        if (ref.read(scanProvider).scannedPages.isNotEmpty) {
          // ignore: use_build_context_synchronously
          AppRoutes.navigateToEdit(context);
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

  void _showFavorites() {
    final favorites = ref.read(favoriteDocumentsProvider);

    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No favorite documents yet'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final document = favorites[index];
                  return ListTile(
                    leading: document.thumbnailPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(document.thumbnailPath!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    title: Text(document.name),
                    subtitle: Text(
                      DateTimeUtils.getFriendlyDate(document.modifiedAt),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      onPressed: () {
                        Navigator.pop(context);

                        // Remove from favorites
                        final updatedDoc = Document(
                          id: document.id,
                          name: document.name,
                          pdfPath: document.pdfPath,
                          pagesPaths: document.pagesPaths,
                          pageCount: document.pageCount,
                          thumbnailPath: document.thumbnailPath,
                          createdAt: document.createdAt,
                          modifiedAt: document.modifiedAt,
                          tags: document.tags,
                          folderId: document.folderId,
                          isFavorite: false,
                          isPasswordProtected: document.isPasswordProtected,
                          password: document.password,
                        );

                        ref
                            .read(documentsProvider.notifier)
                            .updateDocument(updatedDoc);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      AppRoutes.navigateToView(context, document);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
