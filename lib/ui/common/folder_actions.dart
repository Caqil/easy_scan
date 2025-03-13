// Add this file to your project as lib/ui/common/folder_actions.dart

import 'package:easy_scan/providers/document_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/folder.dart';
import '../../providers/folder_provider.dart';
import '../../utils/constants.dart';

/// A globally accessible class to handle folder-related actions
class FolderActions {
  /// Show folder options bottom sheet
  static Future<void> showFolderOptions(
    BuildContext context,
    Folder folder,
    WidgetRef ref, {
    Function(Folder)? onRename,
    Function(Folder)? onChangeColor,
    Function(Folder)? onDelete,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderOptionsSheet(
        folder: folder,
        ref: ref,
        onRename: onRename,
        onChangeColor: onChangeColor,
        onDelete: onDelete,
      ),
    );
  }

  /// Show rename folder dialog
  static Future<void> showRenameFolderDialog(
    BuildContext context,
    Folder folder,
    WidgetRef ref,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: folder.name);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName != null && newName.isNotEmpty) {
      final updatedFolder = Folder(
        id: folder.id,
        name: newName,
        parentId: folder.parentId,
        color: folder.color,
        iconName: folder.iconName,
        createdAt: folder.createdAt,
      );

      ref.read(foldersProvider.notifier).updateFolder(updatedFolder);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder renamed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Show change folder color dialog
  static Future<void> showChangeFolderColorDialog(
    BuildContext context,
    Folder folder,
    WidgetRef ref,
  ) async {
    int selectedColor = folder.color;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Folder Color'),
            content: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AppConstants.folderColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor == color
                              ? Color(color).withOpacity(0.6)
                              : Colors.transparent,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final updatedFolder = Folder(
        id: folder.id,
        name: folder.name,
        parentId: folder.parentId,
        color: selectedColor,
        iconName: folder.iconName,
        createdAt: folder.createdAt,
      );

      ref.read(foldersProvider.notifier).updateFolder(updatedFolder);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder color updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Show delete folder confirmation dialog
  static Future<void> showDeleteFolderConfirmation(
    BuildContext context,
    Folder folder,
    WidgetRef ref, {
    bool popNavigatorOnSuccess = false,
  }) async {
    final documentsInFolder = ref.read(documentsInFolderProvider(folder.id));
    final subfolders = ref.read(subFoldersProvider(folder.id));

    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Folder'),
            content: documentsInFolder.isNotEmpty || subfolders.isNotEmpty
                ? Text(
                    'This folder contains ${documentsInFolder.length} documents and ${subfolders.length} subfolders. '
                    'All contents will be moved to the parent folder. Continue?')
                : Text('Are you sure you want to delete "${folder.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // Move documents to parent folder
      if (documentsInFolder.isNotEmpty) {
        for (var document in documentsInFolder) {
          final updatedDoc = document.copyWith(folderId: folder.parentId);
          ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
        }
      }

      // Move subfolders to parent folder
      if (subfolders.isNotEmpty) {
        for (var subfolder in subfolders) {
          final updatedFolder = Folder(
            id: subfolder.id,
            name: subfolder.name,
            parentId: folder.parentId,
            color: subfolder.color,
            iconName: subfolder.iconName,
            createdAt: subfolder.createdAt,
          );
          ref.read(foldersProvider.notifier).updateFolder(updatedFolder);
        }
      }

      // Delete the folder
      await ref.read(foldersProvider.notifier).deleteFolder(folder.id);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Optionally pop navigator if viewing the deleted folder
        if (popNavigatorOnSuccess) {
          Navigator.pop(context);
        }
      }
    }
  }
}

/// Internal widget for folder options sheet
class _FolderOptionsSheet extends StatelessWidget {
  final Folder folder;
  final WidgetRef ref;
  final Function(Folder)? onRename;
  final Function(Folder)? onChangeColor;
  final Function(Folder)? onDelete;

  const _FolderOptionsSheet({
    required this.folder,
    required this.ref,
    this.onRename,
    this.onChangeColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

          // Options list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Rename Folder',
                  description: 'Change folder name',
                  onTap: () {
                    Navigator.pop(context);
                    if (onRename != null) {
                      onRename!(folder);
                    } else {
                      FolderActions.showRenameFolderDialog(
                          context, folder, ref);
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Change Color',
                  description: 'Customize folder appearance',
                  onTap: () {
                    Navigator.pop(context);
                    if (onChangeColor != null) {
                      onChangeColor!(folder);
                    } else {
                      FolderActions.showChangeFolderColorDialog(
                          context, folder, ref);
                    }
                  },
                ),
                if (folder.parentId != null)
                  _buildOptionTile(
                    context,
                    icon: Icons.drive_file_move_outlined,
                    title: 'Move Folder',
                    description: 'Change folder location',
                    onTap: () {
                      Navigator.pop(context);
                      // Implement move folder functionality
                    },
                  ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildOptionTile(
                  context,
                  icon: Icons.delete_outlined,
                  iconColor: Colors.red,
                  title: 'Delete Folder',
                  description: 'Remove folder and move contents',
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) {
                      onDelete!(folder);
                    } else {
                      FolderActions.showDeleteFolderConfirmation(
                        context,
                        folder,
                        ref,
                        popNavigatorOnSuccess: true,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
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
}
