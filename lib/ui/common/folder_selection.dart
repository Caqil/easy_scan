import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/folder.dart';
import '../../providers/folder_provider.dart';

class FolderSelector {
  /// Show a modern folder selection bottom sheet with subfolder support
  static Future<Folder?> showFolderSelectionDialog(
    BuildContext context,
    List<Folder> allFolders,
    WidgetRef ref, {
    String? currentFolderId,
    required Function() onCreateFolder,
    Function(Folder)? onFolderOptions,
  }) async {
    if (allFolders.isEmpty) {
      onCreateFolder();
      return null;
    }

    return showModalBottomSheet<Folder?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderSelectionSheet(
        allFolders: allFolders,
        ref: ref,
        currentFolderId: currentFolderId,
        onCreateFolder: onCreateFolder,
        onFolderOptions: onFolderOptions,
      ),
    );
  }
}

class _FolderSelectionSheet extends ConsumerStatefulWidget {
  final List<Folder> allFolders;
  final String? currentFolderId;
  final Function() onCreateFolder;
  final Function(Folder)? onFolderOptions;
  final WidgetRef ref;

  const _FolderSelectionSheet({
    required this.allFolders,
    required this.ref,
    this.currentFolderId,
    required this.onCreateFolder,
    this.onFolderOptions,
  });

  @override
  ConsumerState<_FolderSelectionSheet> createState() =>
      _FolderSelectionSheetState();
}

class _FolderSelectionSheetState extends ConsumerState<_FolderSelectionSheet> {
  String? _currentParentId;
  List<String> _breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _currentParentId = null;
    _breadcrumbs = ["Root"];

    // If we have a current folder, build the breadcrumb path
    if (widget.currentFolderId != null) {
      _buildBreadcrumbPath(widget.currentFolderId);
    }
  }

  // Build the breadcrumb path from the current folder up to the root
  void _buildBreadcrumbPath(String? folderId) {
    if (folderId == null) return;

    final List<String> path = [];
    String? currentId = folderId;

    while (currentId != null) {
      final folder = widget.allFolders.firstWhere(
        (f) => f.id == currentId,
        orElse: () => Folder(name: "Unknown"),
      );

      path.insert(0, folder.name);
      currentId = folder.parentId;
    }

    if (path.isNotEmpty) {
      setState(() {
        _breadcrumbs = ["Root", ...path];
        _currentParentId = folderId;
      });
    }
  }

  // Navigate to a subfolder
  void _navigateToFolder(Folder folder) {
    setState(() {
      _currentParentId = folder.id;
      _breadcrumbs.add(folder.name);
    });
  }

  // Navigate up one level
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

  @override
  Widget build(BuildContext context) {
    // Get folders for current level from the provided allFolders list
    final folders = widget.allFolders
        .where((folder) => folder.parentId == _currentParentId)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        'folder_selector.select_folder'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AutoSizeText(
                        'folder_selector.choose_destination'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
// Replace the existing SingleChildScrollView with this:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .start, // Changed from default center alignment
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Add a back button when not at root
                  if (_currentParentId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: _navigateUp,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ..._buildBreadcrumbs(),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Folder list
          Flexible(
            child: folders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      return _buildFolderTile(context, folder);
                    },
                  ),
          ),

          const Divider(height: 1),

          // Create new folder option
          InkWell(
            onTap: () {
              Navigator.pop(context);
              widget.onCreateFolder();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.create_new_folder_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AutoSizeText(
                      'folder_selector.create_new_folder'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  const Icon(Icons.add, size: 20),
                ],
              ),
            ),
          ),

          if (_currentParentId != null)
            InkWell(
              onTap: () {
                final currentFolder = widget.allFolders.firstWhere(
                  (f) => f.id == _currentParentId,
                  orElse: () => Folder(name: "Unknown"),
                );
                Navigator.pop(context, currentFolder);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: AutoSizeText(
                  'folder_selector.select_current_folder'.tr(
                    namedArgs: {'name': _breadcrumbs.last},
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbs() {
    List<Widget> items = [];

    for (int i = 0; i < _breadcrumbs.length; i++) {
      final isLast = i == _breadcrumbs.length - 1;
      final isFirst = i == 0;

      items.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLast
                ? null
                : () {
                    if (i == 0) {
                      setState(() {
                        _currentParentId = null;
                        _breadcrumbs = ["Root"];
                      });
                    } else {
                      String? targetId;
                      String? parentId = null;

                      for (int j = 1; j <= i; j++) {
                        final folders = widget.allFolders
                            .where((f) => f.parentId == parentId)
                            .toList();
                        final targetFolder = folders.firstWhere(
                          (f) => f.name == _breadcrumbs[j],
                          orElse: () => Folder(name: "Unknown"),
                        );
                        parentId = targetFolder.id;
                        targetId = targetFolder.id;
                      }

                      if (targetId != null) {
                        setState(() {
                          _currentParentId = targetId;
                          _breadcrumbs = _breadcrumbs.sublist(0, i + 1);
                        });
                      }
                    }
                  },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLast
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLast
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFirst)
                    Icon(
                      Icons.home,
                      size: 16,
                      color: isLast
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade600,
                    ),
                  if (isFirst) const SizedBox(width: 4),
                  AutoSizeText(
                    _breadcrumbs[i],
                    style: GoogleFonts.slabo27px(
                      color: isLast
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade800,
                      fontWeight: isLast ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (!isLast) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ),
        );
      }
    }

    return items;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            AutoSizeText(
              'folder_selector.no_subfolders_found'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            AutoSizeText(
              'folder_selector.create_subfolder_here'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTile(BuildContext context, Folder folder) {
    final subfolders =
        widget.allFolders.where((f) => f.parentId == folder.id).toList();
    final hasSubfolders = subfolders.isNotEmpty;

    return InkWell(
      onTap: () {
        if (hasSubfolders) {
          _navigateToFolder(folder);
        } else {
          Navigator.pop(context, folder);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (hasSubfolders)
                    AutoSizeText(
                      'folder_selector.subfolder_count'.tr(
                        namedArgs: {'count': subfolders.length.toString()},
                      ),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (hasSubfolders)
              const Icon(Icons.chevron_right, color: Colors.grey),
            if (widget.onFolderOptions != null)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  widget.onFolderOptions!(folder);
                },
              ),
          ],
        ),
      ),
    );
  }
}
