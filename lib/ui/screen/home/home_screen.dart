import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/scan_service.dart';
import 'package:scanpro/services/share_service.dart';
import 'package:scanpro/ui/common/component/scan_initial_view.dart';
import 'package:scanpro/ui/common/document_actions.dart';
import 'package:scanpro/ui/screen/folder/components/folder_actions.dart';
import 'package:scanpro/ui/screen/barcode/widget/recent_barcodes.dart';
import 'package:scanpro/ui/screen/compression/components/compression_tools.dart';
import 'package:scanpro/ui/screen/folder/components/folder_creator.dart';
import 'package:scanpro/ui/common/folder_selection.dart';
import 'package:scanpro/ui/common/folders_grid.dart';
import 'package:scanpro/ui/common/pdf_merger.dart';
import 'package:scanpro/ui/screen/compression/components/compression_bottomsheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/routes.dart';
import '../../../models/folder.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/folder_provider.dart';
import '../../../utils/date_utils.dart';
import '../../common/app_bar.dart';
import '../../common/dialogs.dart';
import '../barcode/widget/barcode_scan_options_view.dart';
import 'component/all_documents.dart';
import 'component/empty_state.dart';
import '../folder/components/folders_section.dart';
import 'component/quick_actions.dart';
import 'component/recent_documents.dart';
import 'package:path/path.dart' as path;

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
  final ShareService _shareService = ShareService();
  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  void navigateByDocumentType(BuildContext context, Document document) {
    // Get file extension
    final String extension =
        path.extension(document.pdfPath).toLowerCase().replaceAll('.', '');

    // List of editable extensions
    final List<String> editableExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

    // Navigate to Edit or View based on extension
    if (editableExtensions.contains(extension)) {
      AppRoutes.navigateToEdit(context, document: document);
    } else {
      AppRoutes.navigateToView(context, document);
    }
  }

  void _handleScanAction() {
    final scanService = ref.read(scanServiceProvider);
    showModalBottomSheet(
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
            onScanPressed: () {
              scanService.scanDocuments(
                context: context,
                ref: ref,
                setLoading: (isLoading) =>
                    setState(() => _isLoading = isLoading),
                onSuccess: () {
                  AppRoutes.navigateToEdit(context);
                },
              );
            },
            onImportPressed: () {
              scanService.pickImages(
                context: context,
                ref: ref,
                setLoading: (isLoading) =>
                    setState(() => _isLoading = isLoading),
                onSuccess: () {
                  AppRoutes.navigateToEdit(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void showCompressionOptions(
      BuildContext context, Document document, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CompressionBottomSheet(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentDocuments = ref.watch(recentDocumentsProvider);
    final allDocuments = ref.watch(documentsProvider);
    final rootFolders = ref.watch(rootFoldersProvider);
    final List<Document> filteredDocuments = _searchQuery.isEmpty
        ? []
        : ref.read(documentsProvider.notifier).searchDocuments(_searchQuery);
    final scanService = ref.read(scanServiceProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: _searchQuery.isEmpty
            ? AutoSizeText('ScanPro',
                style: GoogleFonts.lilitaOne(fontSize: 25.sp))
            : CupertinoSearchTextField(
                style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                controller: _searchController,
                placeholder: 'Search all documents...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
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
                setState(() {
                  _searchQuery = ''; // Set empty to activate search field
                  _searchController.text = ''; // Clear text
                  Future.delayed(Duration.zero, () {
                    FocusScope.of(context).unfocus();
                    _searchController.clear();
                    setState(() {
                      _searchQuery = ' '; // Space to trigger search mode
                      _searchController.text = '';
                    });
                  });
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
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
                    onScan: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: BarcodeScanOptionsView(
                              onScanPressed: () {
                                Navigator.pop(context);
                                AppRoutes.navigateToBarcodeScan(context);
                              },
                              onGeneratePressed: () {
                                Navigator.pop(context);
                                AppRoutes.navigateToBarcodeGenerator(context);
                              },
                              onHistoryPressed: () {
                                Navigator.pop(context);
                                AppRoutes.navigateToBarcodeHistory(context);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    onFolders: () {
                      _showFolderSelectionDialog(rootFolders);
                    },
                    onOcr: _handleOcrAction,
                    onUnlock: _handleUnlockAction,
                    onMerge: () => PdfMerger.showMergeOptions(context, ref),
                    onCompress: () {
                      PdfCompressionUtils.showCompressionOptions(context, ref);
                    },
                    onFavorite: _showFavorites,
                    onMoreTools: () {},
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
                          onEdit: (p0) {
                            navigateByDocumentType(context, p0);
                          },
                        );
                      },
                    ),
                  const RecentBarcodesWidget(),
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
                          AppRoutes.navigateToFolders(context);
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
                      onViewAllPressed: () {
                        AppRoutes.navigateToAllDoc(context);
                      },
                    ),
                  if (recentDocuments.isEmpty &&
                      rootFolders.isEmpty &&
                      allDocuments.isEmpty)
                    EmptyState(onScan: _handleScanAction),
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
    );
  }

  void _handleOcrAction() {
    // Implementation for OCR action
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutoSizeText(
              'ocr.extract_text'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AutoSizeText(
              'ocr.select_document'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOcrOption(
                  context,
                  Icons.document_scanner_outlined,
                  'ocr.scan_document'.tr(),
                  () {
                    Navigator.pop(context);
                    _handleScanAction();
                  },
                ),
                _buildOcrOption(
                  context,
                  Icons.photo_library_outlined,
                  'ocr.gallery_image'.tr(),
                  () {
                    Navigator.pop(context);
                    final scanService = ref.read(scanServiceProvider);
                    scanService.pickImages(
                      context: context,
                      ref: ref,
                      setLoading: (isLoading) =>
                          setState(() => _isLoading = isLoading),
                      onSuccess: () {
                        AppRoutes.navigateToEdit(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleUnlockAction() {
    final documents = ref.read(documentsProvider);
    final lockedDocuments =
        documents.where((doc) => doc.isPasswordProtected).toList();

    if (lockedDocuments.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'pdf.no_locked_documents'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutoSizeText(
              'pdf.password_protected_documents'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            AutoSizeText(
              'pdf.select_document_to_open'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lockedDocuments.length,
                itemBuilder: (context, index) {
                  final document = lockedDocuments[index];
                  return _buildLockedDocumentItem(context, document);
                },
              ),
            ),
            const SizedBox(height: 16),
            SafeArea(
              top: false,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const AutoSizeText('common.cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedDocumentItem(BuildContext context, Document document) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: document.thumbnailPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(document.thumbnailPath!),
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        title: AutoSizeText(
          document.name,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: AutoSizeText(
          DateTimeUtils.getFriendlyDate(document.modifiedAt),
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.lock, color: Colors.blue),
        onTap: () {
          Navigator.pop(context);
          AppRoutes.navigateToView(context, document);
        },
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
                title: AutoSizeText('document.rename_document'.tr()),
                content: CupertinoTextField(
                  controller: controller,
                  autofocus: true,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AutoSizeText('common.cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: AutoSizeText('common.rename'.tr()),
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
            message: 'document.document_renamed'.tr());
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
          title: 'folder.create_destination_folder'.tr(),
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
            message: 'moved_to_folder'
                .tr(namedArgs: {'folderName': ' ${selectedFolder.name}'}));
      }
    }
  }

  Future<void> showDeleteConfirmation(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    final bool confirm = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('document.delete_document'.tr()),
            content: Text('document.delete_confirm_message'
                .tr(namedArgs: {'name': document.name})),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: Text('common.cancel'.tr()),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: Text('common.delete'.tr()),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && context.mounted) {
      await ref.read(documentsProvider.notifier).deleteDocument(document.id);

      // Show success message
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message: 'document.document_deleted'.tr(),
        );
      }
    }
  }

  void _createNewFolder() async {
    final folder = await FolderCreator.showCreateFolderBottomSheet(
      context,
      ref,
      title: 'create_folder'.tr(),
    );

    if (folder != null) {
      AppDialogs.showSnackBar(context,
          type: SnackBarType.success,
          message: 'created_folder_success'
              .tr(namedArgs: {'folderName': '${folder.name}'}));
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
      AppRoutes.navigateToFolders(context);
    }
  }

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
            AutoSizeText(
              'no_documents_yet'.tr(),
              style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700, fontSize: 16.sp),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: Container(
              width: 60,
              height: 60,
              child: document.thumbnailPath != null &&
                      File(document.thumbnailPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(document.thumbnailPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
            ),
            title: AutoSizeText(
              document.name,
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  DateTimeUtils.getFriendlyDate(document.modifiedAt),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    AutoSizeText(
                      'pages_count'
                          .tr(namedArgs: {'count': '${document.pageCount}'}),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (document.isFavorite) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      )
                    ],
                    if (document.isPasswordProtected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.blue,
                      )
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                DocumentActions.showDocumentOptions(
                  context,
                  document,
                  ref,
                  onDelete: (doc) => showDeleteConfirmation(context, doc, ref),
                  onMoveToFolder: (doc) =>
                      showMoveToFolderDialog(context, doc, ref),
                  onRename: (doc) =>
                      showRenameDocumentDialog(context, doc, ref),
                  onShare: (doc) => _shareDocument(context, doc, ref),
                  onEdit: (doc) => navigateByDocumentType(context, doc),
                );
              },
            ),
            onTap: () => AppRoutes.navigateToView(context, document),
          ),
        );
      },
    );
  }

  void _showFavorites() {
    final favorites = ref.read(favoriteDocumentsProvider);

    if (favorites.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'no_favorite_documents_yet'.tr(),
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
                      AutoSizeText(
                        'favorites'.tr(),
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
                    child: AutoSizeText(
                      '${favorites.length}',
                      style: GoogleFonts.slabo27px(
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
                                  AutoSizeText(
                                    document.name,
                                    style: GoogleFonts.slabo27px(
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
                                      AutoSizeText(
                                        DateTimeUtils.getFriendlyDate(
                                            document.modifiedAt),
                                        style: GoogleFonts.slabo27px(
                                          fontWeight: FontWeight.w700,
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
                                      AutoSizeText(
                                        'pages_count'.tr(namedArgs: {
                                          'count': ' ${document.pageCount}'
                                        }),
                                        style: GoogleFonts.slabo27px(
                                          fontWeight: FontWeight.w700,
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
                                  message: 'removed_from_favorites'.tr(
                                      namedArgs: {
                                        'documentName': document.name
                                      }),
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
                    child: const AutoSizeText('common.close'),
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
