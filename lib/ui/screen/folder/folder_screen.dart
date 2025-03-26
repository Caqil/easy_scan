import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/models/folder.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/providers/folder_provider.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/common/document_actions.dart';
import 'package:scanpro/ui/screen/folder/components/folder_actions.dart';
import 'package:scanpro/ui/screen/folder/components/folder_creator.dart';
import 'package:scanpro/ui/common/folder_selection.dart';
import 'package:scanpro/ui/screen/folder/components/enhanced_breadcrumbs.dart';
import 'package:scanpro/utils/date_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;

class FolderScreen extends ConsumerStatefulWidget {
  final Folder? folder;

  const FolderScreen({super.key, this.folder});

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentParentId;
  List<String> _breadcrumbs = ["Root"];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();

    // Initialize with provided folder or start at root
    if (widget.folder != null) {
      _currentParentId = widget.folder!.id;
      _breadcrumbs = ["Root", widget.folder!.name];
    } else {
      _currentParentId = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      _currentParentId = folder.id;
      _breadcrumbs.add(folder.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allFolders = ref.watch(foldersProvider);
    final folders = allFolders
        .where((folder) => folder.parentId == _currentParentId)
        .toList();

    // Get documents in the current folder
    final documents = ref.watch(documentsInFolderProvider(_currentParentId));

    // Filter folders based on search query if not empty
    final filteredFolders = _searchQuery.isEmpty
        ? folders
        : allFolders
            .where((folder) =>
                folder.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Filter documents based on search query if not empty
    final filteredDocuments = _searchQuery.isEmpty
        ? documents
        : ref
            .read(documentsProvider.notifier)
            .searchDocuments(_searchQuery)
            .where((doc) => doc.folderId == _currentParentId)
            .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: _searchQuery.isEmpty
            ? AutoSizeText(
                'folder_screen.title'.tr(),
                style: GoogleFonts.lilitaOne(fontSize: 25.adaptiveSp),
              )
            : CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'folder_screen.search_placeholder'.tr(),
                style: GoogleFonts.slabo27px(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
        actions: [
          IconButton(
            icon: Icon(_searchQuery.isEmpty ? Icons.search : Icons.clear),
            onPressed: () {
              setState(() {
                if (_searchQuery.isEmpty) {
                  _searchQuery = ' '; // Activate search mode
                } else {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.create_new_folder),
            onPressed: () {
              _createNewFolder(context);
            },
          ),
          IconButton(
            icon: Icon(!_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced breadcrumbs (only shown when not searching)
          if (_searchQuery.isEmpty)
            EnhancedBreadcrumbs(
              breadcrumbs: _breadcrumbs,
              currentParentId: _currentParentId,
              onBreadcrumbTap: _onBreadcrumbTap,
              onNavigateUp: _navigateUp,
            ),

          // Folder and document list/grid
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(filteredFolders, filteredDocuments)
                : !_isGridView
                    ? _buildGridView(folders, documents)
                    : _buildListView(folders, documents),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Folder> folders, List<Document> documents) {
    if (folders.isEmpty && documents.isEmpty) {
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
              'folder_screen.no_results_found'.tr(),
              style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700, fontSize: 16.adaptiveSp),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Display folders if any
        if (folders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AutoSizeText(
              'folder_screen.folders_section'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...folders.map((folder) => _buildFolderListItem(folder)),
          const Divider(height: 24),
        ],

        // Display documents if any
        if (documents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AutoSizeText(
              'folder_screen.documents_section'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...documents.map((document) => _buildDocumentListItem(document)),
        ],
      ],
    );
  }

  Widget _buildGridView(List<Folder> folders, List<Document> documents) {
    if (folders.isEmpty && documents.isEmpty) {
      return _buildEmptyView();
    }

    return CustomScrollView(
      slivers: [
        // Folders section
        if (folders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: AutoSizeText(
                'folder_screen.folders_section'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.adaptiveSp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final folder = folders[index];
                  return _buildFolderGridItem(folder);
                },
                childCount: folders.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(height: 24.h),
          ),
        ],

        // Documents section
        if (documents.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              child: AutoSizeText(
                'folder_screen.documents_section'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.adaptiveSp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final document = documents[index];
                  return _buildDocumentGridItem(document);
                },
                childCount: documents.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListView(List<Folder> folders, List<Document> documents) {
    if (folders.isEmpty && documents.isEmpty) {
      return _buildEmptyView();
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Folders section
        if (folders.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
            child: AutoSizeText(
              'folder_screen.folders_section'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...folders.map((folder) => _buildFolderListItem(folder)),
          Divider(height: 24.h),
        ],

        // Documents section
        if (documents.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
            child: AutoSizeText(
              'folder_screen.documents_section'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...documents.map((document) => _buildDocumentListItem(document)),
        ],
      ],
    );
  }

  Widget _buildFolderGridItem(Folder folder) {
    final documentsCount =
        ref.read(documentsInFolderProvider(folder.id)).length;
    final subFolders = ref.read(subFoldersProvider(folder.id));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(folder.color).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToFolder(folder),
        onLongPress: () =>
            FolderActions.showFolderOptions(context, folder, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(folder.color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  folder.iconName != null
                      ? IconData(
                          int.parse('0x${folder.iconName}'),
                          fontFamily: 'MaterialIcons',
                        )
                      : Icons.folder,
                  color: Color(folder.color),
                  size: 30,
                ),
              ),
              const SizedBox(height: 5),
              AutoSizeText(
                folder.name,
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.adaptiveSp,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AutoSizeText(
                '${'folder_screen.documents_count'.tr(namedArgs: {
                      'count': documentsCount.toString()
                    })} | ${'folder_screen.subfolders_count'.tr(namedArgs: {
                      'count': subFolders.length.toString()
                    })}',
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700,
                  fontSize: 10.adaptiveSp,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderListItem(Folder folder) {
    final documentsCount =
        ref.read(documentsInFolderProvider(folder.id)).length;
    final subFolders = ref.read(subFoldersProvider(folder.id));
    final hasSubFolders = subFolders.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToFolder(folder),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(folder.color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  folder.iconName != null
                      ? IconData(
                          int.parse('0x${folder.iconName}'),
                          fontFamily: 'MaterialIcons',
                        )
                      : Icons.folder,
                  color: Color(folder.color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      folder.name,
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.adaptiveSp,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        AutoSizeText(
                          'folder_screen.documents_count'.tr(
                              namedArgs: {'count': documentsCount.toString()}),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.folder,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        AutoSizeText(
                          'folder_screen.subfolders_count'.tr(namedArgs: {
                            'count': subFolders.length.toString()
                          }),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      FolderActions.showRenameFolderDialog(
                          context, folder, ref);
                      break;
                    case 'color':
                      FolderActions.showChangeFolderColorDialog(
                          context, folder, ref);
                      break;
                    case 'delete':
                      FolderActions.showDeleteFolderConfirmation(
                          context, folder, ref);
                      break;
                    case 'addDocs':
                      FolderActions.addDocumentsToFolder(context, folder, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('folder_screen.menu_options.rename'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'color',
                    child: Row(
                      children: [
                        Icon(Icons.palette),
                        SizedBox(width: 8),
                        Text('folder_screen.menu_options.change_color'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'folder_screen.menu_options.delete'.tr(),
                          style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'addDocs',
                    child: Row(
                      children: [
                        Icon(Icons.add_to_photos),
                        SizedBox(width: 8),
                        Text('folder_screen.menu_options.add_documents'.tr()),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasSubFolders)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentGridItem(Document document) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => AppRoutes.navigateToView(context, document),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail or placeholder
                  if (document.thumbnailPath != null &&
                      File(document.thumbnailPath!).existsSync())
                    Hero(
                      tag: 'document_${document.id}',
                      child: Image.file(
                        File(document.thumbnailPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.picture_as_pdf,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),

                  // Favorite icon
                  if (document.isFavorite)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),

                  // Password indicator
                  if (document.isPasswordProtected)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Document info
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    document.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AutoSizeText(
                    DateTimeUtils.getFriendlyDate(document.modifiedAt),
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      fontSize: 10.adaptiveSp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentListItem(Document document) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AppRoutes.navigateToView(context, document),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Document thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: document.thumbnailPath != null &&
                        File(document.thumbnailPath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'document_${document.id}',
                          child: Image.file(
                            File(document.thumbnailPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
              ),

              const SizedBox(width: 16),

              // Document details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      document.name,
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        AutoSizeText(
                          DateTimeUtils.getFriendlyDate(document.modifiedAt),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        AutoSizeText(
                          'folder_screen.pages_count'.tr(namedArgs: {
                            'count': document.pageCount.toString()
                          }),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (document.isFavorite) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          )
                        ],
                        if (document.isPasswordProtected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.lock,
                            size: 12,
                            color: Colors.blue,
                          )
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  DocumentActions.showDocumentOptions(
                    context,
                    document,
                    ref,
                    onDelete: (p0) {
                      _showDeleteDocumentConfirmation(context, p0);
                    },
                    onMoveToFolder: (p0) {
                      _showMoveToFolderDialog(context, p0, ref);
                    },
                    onRename: (p0) {
                      _showRenameDocumentDialog(context, p0);
                    },
                    onEdit: (p0) {
                      navigateByDocumentType(context, p0);
                    },
                    onShare: (p0) async {
                      await DocumentActions.shareDocument(
                          context, ref, document);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void navigateByDocumentType(BuildContext context, Document document) {
    // Get file extension
    final String extension =
        path.extension(document.pdfPath).toLowerCase().replaceAll('.', '');

    // List of editable extensions
    final List<String> editableExtensions = ['pdf'];

    // Navigate to Edit or View based on extension
    if (editableExtensions.contains(extension)) {
      AppRoutes.navigateToEdit(context, document: document);
    } else {
      AppRoutes.navigateToView(context, document);
    }
  }
  void _showDeleteDocumentConfirmation(
      BuildContext context, Document document) {
    AppDialogs.showConfirmDialog(
      context,
      title: 'folder_screen.dialogs.delete_document_title'.tr(),
      message: 'folder_screen.dialogs.delete_document_message'
          .tr(namedArgs: {'name': document.name}),
      confirmText: 'folder_screen.dialogs.delete_button'.tr(),
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed) {
        ref.read(documentsProvider.notifier).deleteDocument(document.id);

        // Show success message
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message:
              'folder_screen.dialogs.success_messages.document_deleted'.tr(),
        );
      }
    });
  }

  Future<void> _showMoveToFolderDialog(
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
            message: 'folder_screen.dialogs.success_messages.moved_to_folder'
                .tr(namedArgs: {'folderName': selectedFolder.name}));
      }
    }
  }

  void _showRenameDocumentDialog(BuildContext context, Document document) {
    final TextEditingController controller =
        TextEditingController(text: document.name);

    showCupertinoDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: Text('folder_screen.dialogs.rename_document_title'.tr()),
          content: CupertinoTextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('folder_screen.dialogs.cancel_button'.tr()),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: Text('folder_screen.dialogs.rename_button'.tr()),
            ),
          ],
        ),
      ),
    ).then((newName) {
      if (newName != null && newName.isNotEmpty) {
        final updatedDoc = document.copyWith(
          name: newName,
          modifiedAt: DateTime.now(),
        );

        ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

        // Show success message
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message:
              'folder_screen.dialogs.success_messages.document_renamed'.tr(),
        );
      }

      controller.dispose();
    });
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            _currentParentId == null
                ? 'folder_screen.no_folders_yet'.tr()
                : 'folder_screen.folder_empty'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'folder_screen.create_folder_prompt'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              fontSize: 14.adaptiveSp,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _createNewFolder(context),
            icon: const Icon(Icons.create_new_folder),
            label: AutoSizeText('folder_screen.create_folder_button'.tr()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateUp() {
    if (_currentParentId == null) return;

    final allFolders = ref.read(foldersProvider);
    final currentFolder = allFolders.firstWhere(
      (f) => f.id == _currentParentId,
      orElse: () => Folder(name: "Unknown"),
    );

    setState(() {
      _currentParentId = currentFolder.parentId;
      _breadcrumbs.removeLast();
    });
  }

  void _onBreadcrumbTap(int index) {
    if (index == _breadcrumbs.length - 1) {
      return; // Don't process if tapping current folder
    }

    if (index == 0) {
      // Root tap
      setState(() {
        _currentParentId = null;
        _breadcrumbs = ["Root"];
      });
    } else {
      // Navigate to specific folder in breadcrumb path
      String? targetId;
      String? parentId;

      final allFolders = ref.read(foldersProvider);
      for (int j = 1; j <= index; j++) {
        final folders =
            allFolders.where((f) => f.parentId == parentId).toList();

        if (folders.isEmpty) break;

        final targetFolder = folders.firstWhere(
          (f) => f.name == _breadcrumbs[j],
          orElse: () => Folder(name: "Unknown"),
        );

        if (targetFolder.name == "Unknown") break;

        parentId = targetFolder.id;
        targetId = targetFolder.id;
      }

      if (targetId != null) {
        setState(() {
          _currentParentId = targetId;
          _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
        });
      }
    }
  }

  void _createNewFolder(BuildContext context) async {
    final folder = await FolderCreator.showCreateFolderBottomSheet(
      context,
      ref,
      title:
          _currentParentId == null ? 'Create Root Folder' : 'Create Subfolder',
      parentId: _currentParentId,
    );

    if (folder != null && mounted) {
      AppDialogs.showSnackBar(
        context,
        type: SnackBarType.success,
        message: 'Created folder ${folder.name} successfully',
      );
    }
  }
}
