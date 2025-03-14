import 'package:easy_scan/services/share_service.dart';
import 'package:easy_scan/ui/common/add_options.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/common/document_actions.dart';
import 'package:easy_scan/ui/common/folder_creator.dart';
import 'package:easy_scan/ui/common/folder_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/models/folder.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/providers/folder_provider.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/constants.dart';
import '../widget/document_card.dart';
import '../widget/folder_card.dart';

class FolderScreen extends ConsumerStatefulWidget {
  final Folder folder;
  const FolderScreen({super.key, required this.folder});

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> {
  bool _isLoading = false;
  final ShareService _shareService = ShareService();
  @override
  Widget build(BuildContext context) {
    final subfolders = ref.watch(subFoldersProvider(widget.folder.id));
    final documents = ref.watch(documentsInFolderProvider(widget.folder.id));
    final allFolders = ref.watch(foldersProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFolderOptions(context, ref, widget.folder),
          ),
        ],
      ),
      body: _buildContent(
        context,
        ref,
        subfolders,
        documents,
        widget.folder,
        allFolders,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddOptions.showAddOptions(
          context,
          ref,
          title: 'Add to This Folder',
          onCreateSubfolder: () => _showCreateFolderDialog(context, ref),
          onScanDocument: () => AppRoutes.navigateToEdit(context),
          onImportDocuments: () => _showImportDocumentsDialog(context, ref),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Folder> subfolders,
    List<Document> documents,
    Folder currentFolder, // Add current folder as a parameter
    List<Folder> allFolders, // Add all folders for breadcrumb path
  ) {
    if (subfolders.isEmpty && documents.isEmpty) {
      return _buildEmptyView(context, ref);
    }

    // Build the breadcrumb path
    final List<String> breadcrumbs =
        _buildBreadcrumbPath(currentFolder, allFolders);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Breadcrumb navigation
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  breadcrumbs.join(' > '),
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort, size: 20),
                onPressed: () {},
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.grey),

        // Subfolders section
        if (subfolders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Folders',
                style: GoogleFonts.notoSerif(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showCreateFolderDialog(context, ref),
                child: const Text('New Folder'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: subfolders.length,
            itemBuilder: (context, index) {
              final subfolder = subfolders[index];
              return FolderCard(
                folder: subfolder,
                documentCount:
                    ref.read(documentsInFolderProvider(subfolder.id)).length,
                onTap: () {
                  AppRoutes.navigateToFolder(context, subfolder);
                },
                onMorePressed: () =>
                    _showFolderOptions(context, ref, subfolder),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Documents section
        if (documents.isNotEmpty) ...[
          Text(
            'Documents',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return DocumentCard(
                document: document,
                onTap: () {
                  AppRoutes.navigateToView(context, document);
                },
                onMorePressed: () => DocumentActions.showDocumentOptions(
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
                  onShare: (p0) => _shareDocument(context, p0, ref),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  List<String> _buildBreadcrumbPath(
      Folder currentFolder, List<Folder> allFolders) {
    final List<String> path = [];
    String? currentId = currentFolder.id;

    while (currentId != null) {
      final folder = allFolders.firstWhere(
        (f) => f.id == currentId,
      );
      path.insert(0, folder.name);
      currentId = folder.parentId;
    }

    // Add "Root" as the starting point
    path.insert(0, 'Root');
    return path;
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

  Widget _buildEmptyView(BuildContext context, WidgetRef ref) {
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
          Text(
            'This folder is empty',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add documents or create subfolders',
            style: GoogleFonts.notoSerif(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => AddOptions.showAddOptions(
              context,
              ref,
              title: 'Add to This Folder',
              onCreateSubfolder: () => _showCreateFolderDialog(context, ref),
              onScanDocument: () => AppRoutes.navigateToEdit(context),
              onImportDocuments: () => _showImportDocumentsDialog(context, ref),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Content'),
          ),
        ],
      ),
    );
  }

  void _showImportDocumentsDialog(BuildContext context, WidgetRef ref) {
    final allDocuments = ref.watch(documentsProvider);
    // Filter to only show documents in root (folderId = null) and not in current folder
    final rootDocuments =
        allDocuments.where((doc) => doc.folderId == null).toList();
    final Set<String> selectedDocumentIds = {};

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Import Documents from Root'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: rootDocuments.isEmpty
                ? const Center(
                    child: Text('No documents available in root folder'),
                  )
                : ListView.builder(
                    itemCount: rootDocuments.length,
                    itemBuilder: (context, index) {
                      final document = rootDocuments[index];
                      final isSelected =
                          selectedDocumentIds.contains(document.id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedDocumentIds.remove(document.id);
                            } else {
                              selectedDocumentIds.add(document.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              CupertinoCheckbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedDocumentIds.add(document.id);
                                    } else {
                                      selectedDocumentIds.remove(document.id);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(document.name),
                                    Text(
                                      'Modified: ${document.modifiedAt.toString().substring(0, 10)}',
                                      style: GoogleFonts.notoSerif(
                                        color: CupertinoColors.secondaryLabel,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoButton(
              onPressed: selectedDocumentIds.isEmpty
                  ? null
                  : () {
                      _importSelectedDocuments(ref, selectedDocumentIds);
                      Navigator.pop(context);
                      AppDialogs.showSnackBar(
                        context,
                        message: 'Documents imported successfully',
                      );
                    },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _importSelectedDocuments(WidgetRef ref, Set<String> documentIds) {
    final allDocuments = ref.read(documentsProvider);

    for (var docId in documentIds) {
      final document = allDocuments.firstWhere((doc) => doc.id == docId);
      final updatedDoc = Document(
        id: document.id,
        name: document.name,
        pdfPath: document.pdfPath,
        pagesPaths: document.pagesPaths,
        pageCount: document.pageCount,
        thumbnailPath: document.thumbnailPath,
        createdAt: document.createdAt,
        modifiedAt: DateTime.now(),
        tags: document.tags,
        folderId: widget.folder.id, // Move to current folder
        isFavorite: document.isFavorite,
        isPasswordProtected: document.isPasswordProtected,
        password: document.password,
      );

      ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
    }
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    int selectedColor = AppConstants.folderColors[0];

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Create Subfolder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: controller,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Select Color:'),
                const SizedBox(height: 8),
                Material(
                    color: Colors.transparent,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.folderColors.map((color) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(color),
                            child: selectedColor == color
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(foldersProvider.notifier).addFolder(
                          Folder(
                            name: controller.text.trim(),
                            color: selectedColor,
                            parentId: widget.folder.id,
                          ),
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    ).then((_) => controller.dispose());
  }

  void _showFolderOptions(BuildContext context, WidgetRef ref, Folder folder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 2.h,
              width: 30.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Folder info header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // Folder icon
                  Container(
                    width: 48,
                    height: 48,
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

                  // Folder name
                  Expanded(
                    child: Text(
                      folder.name,
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Rename option
            _buildFolderOptionTile(
              context,
              icon: Icons.edit_outlined,
              title: 'Rename Folder',
              description: 'Change folder name',
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(context, ref, folder);
              },
            ),

            // Change color option
            _buildFolderOptionTile(
              context,
              icon: Icons.palette_outlined,
              title: 'Change Color',
              description: 'Customize folder appearance',
              onTap: () {
                Navigator.pop(context);
                _showChangeFolderColorDialog(context, ref, folder);
              },
            ),

            // Move folder option (only for non-root folders)
            if (folder.parentId != null)
              _buildFolderOptionTile(
                context,
                icon: Icons.drive_file_move_outlined,
                title: 'Move Folder',
                description: 'Change folder location',
                onTap: () {
                  Navigator.pop(context);
                  // Implementation for moving folder
                },
              ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Delete option
            _buildFolderOptionTile(
              context,
              icon: Icons.delete_outlined,
              iconColor: Colors.red,
              title: 'Delete Folder',
              description: 'Remove folder and move contents',
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteFolderConfirmation(context, ref, folder);
              },
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderOptionTile(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String title,
    required String description,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.notoSerif(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(
      BuildContext context, WidgetRef ref, Folder folder) {
    final TextEditingController controller =
        TextEditingController(text: folder.name);

    showCupertinoDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => CupertinoAlertDialog(
                title: const Text('Rename Folder'),
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
                        final updatedFolder = Folder(
                          id: folder.id,
                          name: controller.text.trim(),
                          parentId: folder.parentId,
                          color: folder.color,
                          iconName: folder.iconName,
                          createdAt: folder.createdAt,
                        );

                        ref
                            .read(foldersProvider.notifier)
                            .updateFolder(updatedFolder);
                        setState(() {});
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Rename'),
                  ),
                ],
              ),
            )).then((_) => controller.dispose());
  }

  void _showChangeFolderColorDialog(
      BuildContext context, WidgetRef ref, Folder folder) {
    int selectedColor = folder.color;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Change Folder Color'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.folderColors.map((color) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(color),
                    child: selectedColor == color
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final updatedFolder = Folder(
                    id: folder.id,
                    name: folder.name,
                    parentId: folder.parentId,
                    color: selectedColor,
                    iconName: folder.iconName,
                    createdAt: folder.createdAt,
                  );

                  ref
                      .read(foldersProvider.notifier)
                      .updateFolder(updatedFolder);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteFolderConfirmation(
      BuildContext context, WidgetRef ref, Folder folder) {
    final documents = ref.read(documentsInFolderProvider(folder.id));
    final subfolders = ref.read(subFoldersProvider(folder.id));

    showCupertinoDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: documents.isNotEmpty || subfolders.isNotEmpty
            ? Text(
                'This folder contains ${documents.length} documents and ${subfolders.length} subfolders. '
                'All contents will be moved to the parent folder. Continue?',
              )
            : Text('Are you sure you want to delete "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Move documents to parent folder
              for (var document in documents) {
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
                  folderId: folder.parentId, // Move to parent folder
                  isFavorite: document.isFavorite,
                  isPasswordProtected: document.isPasswordProtected,
                  password: document.password,
                );

                ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
              }

              // Move subfolders to parent folder
              for (var subfolder in subfolders) {
                final updatedFolder = Folder(
                  id: subfolder.id,
                  name: subfolder.name,
                  parentId: folder.parentId, // Move to parent folder
                  color: subfolder.color,
                  iconName: subfolder.iconName,
                  createdAt: subfolder.createdAt,
                );

                ref.read(foldersProvider.notifier).updateFolder(updatedFolder);
              }

              // Delete the folder
              ref.read(foldersProvider.notifier).deleteFolder(folder.id);
              Navigator.pop(context);

              // If this is the folder we're viewing, go back
              if (folder.id == widget.folder.id) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
