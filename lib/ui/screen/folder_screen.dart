
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
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFolderOptions(context, ref, folder),
          ),
        ],
      ),
      body: _buildContent(context, ref, subfolders, documents),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
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
                    _showDocumentOptions(context, ref, document),
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
            onPressed: () => _showAddOptions(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Content'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('Create Subfolder'),
            onTap: () {
              Navigator.pop(context);
              _showCreateFolderDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Scan Document'),
            onTap: () {
              Navigator.pop(context);
              AppRoutes.navigateToCamera(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import Documents'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_copy),
            title: const Text('Move Documents Here'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameFolderDialog(context, ref, folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Change Color'),
            onTap: () {
              Navigator.pop(context);
              _showChangeFolderColorDialog(context, ref, folder);
            },
          ),
          if (folder.parentId != null)
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move Folder'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteFolderConfirmation(context, ref, folder);
            },
          ),
        ],
      ),
    );
  }

  void _showDocumentOptions(
      BuildContext context, WidgetRef ref, Document document) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.remove_red_eye),
            title: const Text('View'),
            onTap: () {
              Navigator.pop(context);
              AppRoutes.navigateToView(context, document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDocumentDialog(context, ref, document);
            },
          ),
          ListTile(
            leading: Icon(
              document.isFavorite ? Icons.star : Icons.star_border,
            ),
            title: Text(
              document.isFavorite
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleFavorite(ref, document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Move to Another Folder'),
            onTap: () {
              Navigator.pop(context);
              _showMoveDocumentDialog(context, ref, document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDocumentConfirmation(context, ref, document);
            },
          ),
        ],
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

  void _showRenameDocumentDialog(
      BuildContext context, WidgetRef ref, Document document) {
    final TextEditingController controller =
        TextEditingController(text: document.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document Name',
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
                final updatedDoc = Document(
                  id: document.id,
                  name: controller.text.trim(),
                  pdfPath: document.pdfPath,
                  pagesPaths: document.pagesPaths,
                  pageCount: document.pageCount,
                  thumbnailPath: document.thumbnailPath,
                  createdAt: document.createdAt,
                  modifiedAt: DateTime.now(),
                  tags: document.tags,
                  folderId: document.folderId,
                  isFavorite: document.isFavorite,
                  isPasswordProtected: document.isPasswordProtected,
                  password: document.password,
                );

                ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _toggleFavorite(WidgetRef ref, Document document) {
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
      folderId: document.folderId,
      isFavorite: !document.isFavorite,
      isPasswordProtected: document.isPasswordProtected,
      password: document.password,
    );

    ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
  }

  void _showMoveDocumentDialog(
      BuildContext context, WidgetRef ref, Document document) {
    final folders = ref.read(foldersProvider);
    String? selectedFolderId = document.folderId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Move Document'),
            content: SizedBox(
              width: double.maxFinite,
              child: folders.isEmpty
                  ? const Center(
                      child: Text('No folders available.'),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        RadioListTile<String?>(
                          title: const Text('Root (No Folder)'),
                          value: null,
                          groupValue: selectedFolderId,
                          onChanged: (value) {
                            setState(() {
                              selectedFolderId = value;
                            });
                          },
                        ),
                        ...folders
                            .where((f) => f.id != folder.id)
                            .map((folder) {
                          return RadioListTile<String?>(
                            title: Text(folder.name),
                            value: folder.id,
                            groupValue: selectedFolderId,
                            onChanged: (value) {
                              setState(() {
                                selectedFolderId = value;
                              });
                            },
                          );
                        }),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
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
                    folderId: selectedFolderId,
                    isFavorite: document.isFavorite,
                    isPasswordProtected: document.isPasswordProtected,
                    password: document.password,
                  );

                  ref
                      .read(documentsProvider.notifier)
                      .updateDocument(updatedDoc);
                  Navigator.pop(context);
                },
                child: const Text('Move'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDocumentConfirmation(
      BuildContext context, WidgetRef ref, Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(documentsProvider.notifier).deleteDocument(document.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
