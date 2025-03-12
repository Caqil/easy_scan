import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/routes.dart';
import '../../models/folder.dart';
import '../../providers/document_provider.dart';
import '../../providers/folder_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/image_service.dart';
import '../../services/pdf_import_service.dart';
import '../../utils/date_utils.dart';
import '../common/app_bar.dart';
import '../common/dialogs.dart';
import '../widget/document_card.dart';
import '../widget/folder_card.dart';

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

    // Filtered documents based on search
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
                setState(() {
                  _searchQuery = ' '; // Trigger search mode
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchController.text = '';
                  setState(() {
                    _searchQuery = '';
                  });
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
          // Main content
          _searchQuery.isNotEmpty
              ? _buildSearchResults(filteredDocuments)
              : _buildHomeContent(recentDocuments, rootFolders, allDocuments),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppRoutes.navigateToCamera(context);
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
    );
  }

  Widget _buildHomeContent(List<Document> recentDocuments,
      List<Folder> rootFolders, List<Document> allDocuments) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(documentsProvider);
        ref.invalidate(foldersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.camera_alt,
                        label: 'Scan',
                        onTap: () {
                          AppRoutes.navigateToCamera(context);
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.image,
                        label: 'Import',
                        onTap: () {
                          _showImportOptions();
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.folder_open,
                        label: 'Folders',
                        onTap: () => _showFolderSelectionDialog(rootFolders),
                      ),
                      _buildQuickAction(
                        icon: Icons.star,
                        label: 'Favorites',
                        onTap: () {
                          _showFavorites();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (recentDocuments.isNotEmpty) ...[
            const Text(
              'Recent Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentDocuments.length,
                itemBuilder: (context, index) {
                  final document = recentDocuments[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 140,
                      child: DocumentCard(
                        document: document,
                        onTap: () {
                          AppRoutes.navigateToView(context, document);
                        },
                        onMorePressed: () {
                          _showDocumentOptions(document);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (rootFolders.isNotEmpty) ...[
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
                  onPressed: _showCreateFolderDialog, // This should now work
                  child: const Text('Create New'),
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
              itemCount: rootFolders.length,
              itemBuilder: (context, index) {
                final folder = rootFolders[index];
                return FolderCard(
                  folder: folder,
                  documentCount:
                      ref.read(documentsInFolderProvider(folder.id)).length,
                  onTap: () => AppRoutes.navigateToFolder(context, folder),
                  onMorePressed: () => _showFolderOptions(folder),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // All Documents
          if (allDocuments.isNotEmpty) ...[
            const Text(
              'All Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allDocuments.length,
              itemBuilder: (context, index) {
                final document = allDocuments[index];
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
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showDocumentOptions(document);
                    },
                  ),
                  onTap: () {
                    AppRoutes.navigateToView(context, document);
                  },
                );
              },
            ),
          ],

          // Empty state
          if (recentDocuments.isEmpty &&
              rootFolders.isEmpty &&
              allDocuments.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  void _showFolderSelectionDialog(List<Folder> folders) {
    if (folders.isEmpty) {
      _showCreateFolderDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Folder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(folder.color),
                  radius: 16,
                ),
                title: Text(folder.name),
                onTap: () {
                  Navigator.pop(context);
                  _showFolderOptions(folder);
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Folder'),
            onTap: () {
              Navigator.pop(context);
              _showCreateFolderDialog();
            },
          ),
        ],
      ),
    );
  }

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
          title: Text(document.name),
          subtitle: Text(
            DateTimeUtils.getFriendlyDate(document.modifiedAt),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showDocumentOptions(document);
            },
          ),
          onTap: () {
            AppRoutes.navigateToView(context, document);
          },
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'No documents yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan or import your first document',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              AppRoutes.navigateToCamera(context);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final TextEditingController controller = TextEditingController();
    int selectedColor = AppConstants.folderColors[0];
    bool isLoading = false; // Track loading state

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Create New Folder'),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
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
            actions: isLoading
                ? [] // Hide buttons during loading
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            await ref.read(foldersProvider.notifier).addFolder(
                                  Folder(
                                    name: controller.text.trim(),
                                    color: selectedColor,
                                  ),
                                );
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            if (mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error creating folder: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
          );
        },
      ),
    ).then((_) {
      controller.dispose();
    });
  }

  void _showDocumentOptions(Document document) {
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
              _showRenameDocumentDialog(document);
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

              // Toggle favorite status
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
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Move to Folder'),
            onTap: () {
              Navigator.pop(context);
              _showMoveToFolderDialog(document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Share document
              // TODO: Implement share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(
              document.isPasswordProtected ? 'Change Password' : 'Add Password',
            ),
            onTap: () {
              Navigator.pop(context);
              _showPasswordDialog(document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(document);
            },
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(Folder folder) {
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
              _showRenameFolderDialog(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Change Color'),
            onTap: () {
              Navigator.pop(context);
              _showChangeFolderColorDialog(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteFolderConfirmation(folder);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDocumentDialog(Document document) {
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

  void _showRenameFolderDialog(Folder folder) {
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

  void _showChangeFolderColorDialog(Folder folder) {
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

  void _showMoveToFolderDialog(Document document) {
    final folders = ref.read(foldersProvider);
    String? selectedFolderId = document.folderId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Move to Folder'),
            content: SizedBox(
              width: double.maxFinite,
              child: folders.isEmpty
                  ? const Center(
                      child:
                          Text('No folders available. Create a folder first.'),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        RadioListTile<String?>(
                          title: const Text('None (Root)'),
                          value: null,
                          groupValue: selectedFolderId,
                          onChanged: (value) {
                            setState(() {
                              selectedFolderId = value;
                            });
                          },
                        ),
                        ...folders.map((folder) {
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
                        }).toList(),
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

  void _showPasswordDialog(Document document) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          document.isPasswordProtected ? 'Change Password' : 'Add Password',
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (document.isPasswordProtected)
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
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
                    isFavorite: document.isFavorite,
                    isPasswordProtected: true,
                    password: controller.text.trim(),
                  );

                  // TODO: In a real app, we would use the PdfService to add password protection to the PDF
                  ref
                      .read(documentsProvider.notifier)
                      .updateDocument(updatedDoc);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showDeleteConfirmation(Document document) {
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
              // TODO: In a real app, we would also delete the PDF file and associated image files
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

  void _showDeleteFolderConfirmation(Folder folder) {
    final documents = ref.read(documentsInFolderProvider(folder.id));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: documents.isNotEmpty
            ? Text(
                'This folder contains ${documents.length} documents. Deleting the folder will move all documents to root. Continue?')
            : Text('Are you sure you want to delete "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // If folder has documents, move them to root
              if (documents.isNotEmpty) {
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
                    folderId: null, // Move to root
                    isFavorite: document.isFavorite,
                    isPasswordProtected: document.isPasswordProtected,
                    password: document.password,
                  );

                  ref
                      .read(documentsProvider.notifier)
                      .updateDocument(updatedDoc);
                }
              }

              // Delete the folder
              ref.read(foldersProvider.notifier).deleteFolder(folder.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text(
                'Import Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.photo),
                  title: const Text('Import from Gallery'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageForScan();
                  },
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.doc),
                  title: const Text('Import PDF'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    _importPdfFromLocal();
                  },
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.cloud_download),
                  title: const Text('Import from iCloud'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    _importPdfFromICloud();
                  },
                ),
              ],
            ),
            SizedBox(
              height: 50,
            )
          ],
        ),
      ),
    );
  }

  /// Import PDF from device storage
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
          final File processedFile = await imageService.enhanceImage(
            imageFile,
            scanState.settings.colorMode,
            quality: scanState.settings.quality,
          );
          ref.read(scanProvider.notifier).addPage(processedFile);
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
