import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/models/folder.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/providers/folder_provider.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/common/folder_actions.dart';
import 'package:easy_scan/ui/common/folder_creator.dart';
import 'package:easy_scan/ui/screen/folder/components/enhanced_breadcrumbs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FolderScreen extends ConsumerStatefulWidget {
  const FolderScreen({super.key});

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
    _currentParentId = null;
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

    // Filter folders based on search query if not empty
    final filteredFolders = _searchQuery.isEmpty
        ? folders
        : allFolders
            .where((folder) =>
                folder.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: _searchQuery.isEmpty
            ? const Text('Folder Browser')
            : CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search folders',
                style: const TextStyle(color: Colors.black),
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
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
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

          // Folder list/grid
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(filteredFolders)
                : _isGridView
                    ? _buildGridView(folders)
                    : _buildListView(folders),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewFolder(context),
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  Widget _buildSearchResults(List<Folder> folders) {
    if (folders.isEmpty) {
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
              'No folders found',
              style: GoogleFonts.notoSerif(fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final documentsCount =
            ref.read(documentsInFolderProvider(folder.id)).length;
        final subFolders = ref.read(subFoldersProvider(folder.id));

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
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
            title: Text(
              folder.name,
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${documentsCount} documents | ${subFolders.length} subfolders',
              style: GoogleFonts.notoSerif(fontSize: 12.sp),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => AppRoutes.navigateToFolder(context, folder),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () =>
                      FolderActions.showFolderOptions(context, folder, ref),
                ),
              ],
            ),
            onTap: () => _navigateToFolder(folder),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Folder> folders) {
    if (folders.isEmpty) {
      return _buildEmptyView();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
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
                  Text(
                    folder.name,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$documentsCount docs | ${subFolders.length} folders',
                    style: GoogleFonts.notoSerif(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Folder> folders) {
    if (folders.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
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
                        Text(
                          folder.name,
                          style: GoogleFonts.notoSerif(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            Text(
                              '$documentsCount documents',
                              style: GoogleFonts.notoSerif(
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
                            Text(
                              '${subFolders.length} subfolders',
                              style: GoogleFonts.notoSerif(
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
                        case 'open':
                          AppRoutes.navigateToFolder(context, folder);
                          break;
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
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open),
                            SizedBox(width: 8),
                            Text('Open Folder'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'color',
                        child: Row(
                          children: [
                            Icon(Icons.palette),
                            SizedBox(width: 8),
                            Text('Change Color'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
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
      },
    );
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
          Text(
            _currentParentId == null
                ? 'No folders yet'
                : 'This folder is empty',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new folder to get started',
            style: GoogleFonts.notoSerif(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _createNewFolder(context),
            icon: const Icon(Icons.create_new_folder),
            label: const Text('Create Folder'),
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
    if (index == _breadcrumbs.length - 1)
      return; // Don't process if tapping current folder

    if (index == 0) {
      // Root tap
      setState(() {
        _currentParentId = null;
        _breadcrumbs = ["Root"];
      });
    } else {
      // Navigate to specific folder in breadcrumb path
      String? targetId;
      String? parentId = null;

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
