import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/services/share_service.dart';
import 'package:easy_scan/ui/common/document_actions.dart';
import 'package:easy_scan/ui/common/folder_actions.dart';
import 'package:easy_scan/ui/common/folder_creator.dart';
import 'package:easy_scan/ui/common/folder_selection.dart';
import 'package:easy_scan/ui/common/folders_grid.dart';
import 'package:easy_scan/ui/common/import_options.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/routes.dart';
import '../../../models/folder.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/folder_provider.dart';
import '../../../providers/scan_provider.dart';
import '../../../services/pdf_import_service.dart';
import '../../../utils/date_utils.dart';
import '../../common/app_bar.dart';
import '../../common/dialogs.dart';
import 'component/all_documents.dart';
import 'component/empty_state.dart';
import 'component/folders_section.dart';
import 'component/quick_actions.dart';
import 'component/recent_documents.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController controller = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  final ShareService _shareService = ShareService();
  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
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
            ? Text('CamScanner App', style: GoogleFonts.notoSerif())
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
          IconButton(
            icon: const Icon(Icons.connected_tv_rounded),
            onPressed: () {
              AppRoutes.navigateToConversion(context);
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
                          context,
                          document,
                          ref,
                          onDelete: (p0) {
                            showDeleteConfirmation(context, p0, ref);
                          },
                          onMoveToFolder: (p0) {
                            showMoveToFolderDialog(context, p0, ref);
                          },
                          onRename: (p0) {
                            showRenameDocumentDialog(context, p0, ref);
                          },
                          onShare: (p0) {
                            _shareDocument(context, p0, ref);
                          },
                        );
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
                          context,
                          document,
                          ref,
                          onDelete: (p0) {
                            showDeleteConfirmation(context, p0, ref);
                          },
                          onMoveToFolder: (p0) {
                            showMoveToFolderDialog(context, p0, ref);
                          },
                          onRename: (p0) {
                            showRenameDocumentDialog(context, p0, ref);
                          },
                          onShare: (p0) {
                            _shareDocument(context, p0, ref);
                          },
                        );
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

  Future<void> _shareDocument(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _shareService.sharePdf(
        document.pdfPath,
        subject: document.name,
      );
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error sharing document: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> showRenameDocumentDialog(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: document.name);

    final String? newName = await showCupertinoDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => CupertinoAlertDialog(
                title: const Text('Rename Document'),
                content: CupertinoTextField(
                  controller: controller,
                  autofocus: true,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: const Text('Rename'),
                  ),
                ],
              ),
            ));

    controller.dispose();

    if (newName != null && newName.isNotEmpty) {
      final updatedDoc = document.copyWith(
        name: newName,
        modifiedAt: DateTime.now(),
      );

      ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Show success message
      if (context.mounted) {
        AppDialogs.showSnackBar(context,
            type: SnackBarType.success,
            message: 'Document renamed successfully');
      }
    }
  }

  Future<void> showMoveToFolderDialog(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    // Get all folders
    final allFolders = ref.read(foldersProvider);

    // Show folder selection dialog
    final selectedFolder = await FolderSelector.showFolderSelectionDialog(
      context,
      allFolders,
      ref,
      onCreateFolder: () async {
        // Create a new folder directly as a destination
        await FolderCreator.showCreateFolderBottomSheet(
          context,
          ref,
          title: 'Create Destination Folder',
        );
      },
    );

    // If user selected a folder, move the document
    if (selectedFolder != null && context.mounted) {
      // Update document with new folder ID
      final updatedDoc = document.copyWith(
        folderId: selectedFolder.id,
        modifiedAt: DateTime.now(),
      );

      // Save the updated document
      await ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Show success message
      if (context.mounted) {
        AppDialogs.showSnackBar(context,
            type: SnackBarType.success,
            message: 'Moved to ${selectedFolder.name}');
      }
    }
  }

  Future<void> showDeleteConfirmation(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    final bool confirm = await showCupertinoDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setState) => CupertinoAlertDialog(
                    title: const Text('Delete Document'),
                    content: Text(
                        'Are you sure you want to delete "${document.name}"? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(documentsProvider.notifier)
                              .deleteDocument(document.id);
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  )),
        ) ??
        false;

    if (confirm && context.mounted) {
      await ref.read(documentsProvider.notifier).deleteDocument(document.id);

      // Show success message
      if (context.mounted) {
        AppDialogs.showSnackBar(context,
            type: SnackBarType.success,
            message: 'Document deleted successfully');
      }
    }
  }

  void _createNewFolder() async {
    final folder = await FolderCreator.showCreateFolderBottomSheet(
      context,
      ref,
      title: 'Create Folder',
    );

    if (folder != null) {
      AppDialogs.showSnackBar(context,
          type: SnackBarType.success,
          message: 'Created folder ${folder.name} successfully');
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
      return Center(
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
              style: GoogleFonts.notoSerif(fontSize: 16.sp),
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
                    width: 30.w,
                    height: 30.h,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.picture_as_pdf),
          title: Text(
            document.name,
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateTimeUtils.getFriendlyDate(document.modifiedAt),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => DocumentActions.showDocumentOptions(
              context,
              document,
              ref,
              onDelete: (p0) {
                showDeleteConfirmation(context, p0, ref);
              },
              onMoveToFolder: (p0) {
                showMoveToFolderDialog(context, p0, ref);
              },
              onRename: (p0) {
                showRenameDocumentDialog(context, p0, ref);
              },
              onShare: (p0) {
                _shareDocument(context, p0, ref);
              },
            ),
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
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        // Process images
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
      AppDialogs.showSnackBar(
        context,
        message: 'No favorite documents yet',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar for better UX
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 30.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with count
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Favorites',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${favorites.length}',
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Document list
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final document = favorites[index];
                  return Card(
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        AppRoutes.navigateToView(context, document);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Document thumbnail
                            document.thumbnailPath != null
                                ? Hero(
                                    tag: 'document_${document.id}',
                                    child: Container(
                                      width: 60,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(
                                              File(document.thumbnailPath!)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),

                            const SizedBox(width: 16),

                            // Document info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.name,
                                    style: GoogleFonts.notoSerif(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateTimeUtils.getFriendlyDate(
                                            document.modifiedAt),
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 10.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${document.pageCount} pages',
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 10.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            IconButton(
                              icon: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
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
                                  isPasswordProtected:
                                      document.isPasswordProtected,
                                  password: document.password,
                                );

                                ref
                                    .read(documentsProvider.notifier)
                                    .updateDocument(updatedDoc);

                                // Show feedback
                                AppDialogs.showSnackBar(
                                  context,
                                  message:
                                      '${document.name} removed from favorites',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
