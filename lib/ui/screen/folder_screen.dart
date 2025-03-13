import 'package:easy_scan/ui/common/add_options.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/common/document_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/models/folder.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/providers/folder_provider.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import '../../utils/constants.dart';
import '../widget/document_card.dart';
import '../widget/folder_card.dart';

class FolderScreen extends ConsumerWidget {
  final Folder folder;
  const FolderScreen({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subfolders = ref.watch(subFoldersProvider(folder.id));
    final documents = ref.watch(documentsInFolderProvider(folder.id));

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFolderOptions(context, ref, folder),
          ),
        ],
      ),
      body: _buildContent(context, ref, subfolders, documents),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddOptions.showAddOptions(
          context,
          ref,
          title: 'Add to This Folder',
          onCreateSubfolder: () => _showCreateFolderDialog(context, ref),
          onScanDocument: () => AppRoutes.navigateToCamera(context),
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
  ) {
    if (subfolders.isEmpty && documents.isEmpty) {
      return _buildEmptyView(context, ref);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Subfolders section
        if (subfolders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Folders',
                style: TextStyle(
                  fontSize: 18,
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
          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 18,
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
                onMorePressed: () =>
                    DocumentActions.showDocumentOptions(context, document, ref),
              );
            },
          ),
        ],
      ],
    );
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
          const Text(
            'This folder is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add documents or create subfolders',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => AddOptions.showAddOptions(
              context,
              ref,
              title: 'Add to This Folder',
              onCreateSubfolder: () => _showCreateFolderDialog(context, ref),
              onScanDocument: () => AppRoutes.navigateToCamera(context),
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                      return CheckboxListTile(
                        title: Text(document.name),
                        subtitle: Text(
                          'Modified: ${document.modifiedAt.toString().substring(0, 10)}',
                        ),
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
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
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
        folderId: folder.id, // Move to current folder
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Subfolder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Folder Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Color:'),
                const SizedBox(height: 8),
                Wrap(
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
                ),
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
                            parentId: folder.id,
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
              height: 4,
              width: 40,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
              width: 40,
              height: 40,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
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

                ref.read(foldersProvider.notifier).updateFolder(updatedFolder);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showChangeFolderColorDialog(
      BuildContext context, WidgetRef ref, Folder folder) {
    int selectedColor = folder.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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

    showDialog(
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
              if (folder.id == this.folder.id) {
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
