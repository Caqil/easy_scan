import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/folder.dart';

class FolderSelector {
  /// Show a modern folder selection bottom sheet
  static Future<Folder?> showFolderSelectionDialog(
    BuildContext context,
    List<Folder> folders,
    WidgetRef ref, {
    required Function() onCreateFolder,
    Function(Folder)? onFolderOptions,
  }) async {
    if (folders.isEmpty) {
      onCreateFolder();
      return null;
    }

    return showModalBottomSheet<Folder?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderSelectionSheet(
        folders: folders,
        onCreateFolder: onCreateFolder,
        onFolderOptions: onFolderOptions,
      ),
    );
  }
}

class _FolderSelectionSheet extends StatelessWidget {
  final List<Folder> folders;
  final Function() onCreateFolder;
  final Function(Folder)? onFolderOptions;

  const _FolderSelectionSheet({
    required this.folders,
    required this.onCreateFolder,
    this.onFolderOptions,
  });

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Folder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose a destination folder',
                        style: TextStyle(
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

          const Divider(height: 1),

          // Folder list
          Flexible(
            child: ListView.builder(
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
              onCreateFolder();
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
                  const Expanded(
                    child: Text(
                      'Create New Folder',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.add, size: 20),
                ],
              ),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildFolderTile(BuildContext context, Folder folder) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, folder);
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
              child: Text(
                folder.name,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            if (onFolderOptions != null)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  onFolderOptions!(folder);
                },
              ),
          ],
        ),
      ),
    );
  }
}
